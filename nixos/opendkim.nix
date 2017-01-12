################################################################################
# My own custom module for OpenDKIM.
{ config, lib, pkgs, ...}:

with lib;

let
  cfg = config.services.pmade-opendkim;
  defaultUser = "opendkim";
  homeDir = "/run/opendkim";
  pidFile = "${homeDir}/opendkim.pid";

  # The name of the TXT resource record type.
  mkResourceName = host: "${host.selector}._domainkey.${host.signingDomain}";

  # Entries in the SigningTable.
  mkSigningTable = hosts:
    concatMapStrings (h: concatMapStrings (a: "${a} ${mkResourceName h}\n") h.addressWildcards) hosts;

  signingTableFile = pkgs.writeTextFile {
    name = "sigtable";
    text = mkSigningTable (attrValues cfg.hosts);
  };

  # Make a file in the nix store to hold a private key for a host.
  # FIXME: Make this a private file as soon as nix supports that.
  openHostPrivateKey = host: pkgs.writeTextFile {
    name = "${host.name}-dkim-key";
    text = host.privateKey;
  };

  # Temp function to hold secure version of the host key.
  hostPrivateKey = host: homeDir + "/" + baseNameOf "${openHostPrivateKey host}";

  # Entries in the KeyTable.
  mkKeyTable = hosts:
    concatMapStrings (h: "${mkResourceName h} ${h.signingDomain}:${h.selector}:${hostPrivateKey h}\n") hosts;

  keyTableFile = pkgs.writeTextFile {
    name = "keytable";
    text = mkKeyTable (attrValues cfg.hosts);
  };

  # Entries in the TrustedHosts file.
  mkTrustedHosts = confOpts:
    concatStringsSep "\n" confOpts.extraTrustedHosts +
    "\n" + concatMapStrings (h: "${h.signingDomain}\n") (attrValues confOpts.hosts);

  trustedHostsFile = pkgs.writeTextFile {
    name = "trustedhosts";
    text = mkTrustedHosts cfg;
  };

  # The configuration file.
  mkOpenDKIMConf = confOpts: ''
    AutoRestart             No
    Syslog                  Yes
    SyslogSuccess           Yes
    LogWhy                  Yes
    LogResults              Yes

    UMask                   002
    UserID                  ${confOpts.user}:${confOpts.user}
    Socket                  inet:${toString confOpts.port}@${confOpts.interface}

    Canonicalization        relaxed/simple
    Mode                    sv

    OversignHeaders         From
    AlwaysAddARHeader       Yes

    SignatureAlgorithm      rsa-sha256
    ExternalIgnoreList      refile:${trustedHostsFile}
    InternalHosts           refile:${trustedHostsFile}
    KeyTable                refile:${keyTableFile}
    SigningTable            refile:${signingTableFile}

    ${confOpts.extraConf}
  '';

  openDKIMConfFile = pkgs.writeTextFile {
    name = "opendkim.conf";
    text = mkOpenDKIMConf cfg;
  };

  # Host configuration.
  hostOpts = { name, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        example = "example.com";
        description = "Name of the host.";
      };

      addressWildcards = mkOption {
        type = types.listOf types.str;
        example = [ "*@example.com" ];
        description = ''
          Wildcard patterns that are matched against the address found
          in the `From:' header field.
        '';
      };

      signingDomain = mkOption {
        type = types.str;
        example = "example.com";
        description = ''
          The name of the domain to use in the signature's `d=' value.

          A signature verifying server would use this value along with
          the `selector' value to figure out which DNS record to
          fetch.

          For example: selector._domainkey.signingDomain
        '';
      };

      selector = mkOption {
        type = types.str;
        example = "20150303";
        description = ''
          The name of the selector to use in the signature's `s=' value.

          A signature verifying server would use this value along with
          the `signingDomain' value to figure out which DNS record to
          fetch.

          For example: selector._domainkey.signingDomain
        '';
      };

      privateKey = mkOption {
        type = types.str;
        description = ''
          The text of the RSA private key used for signing.
        '';
      };
    };

    config = {
      name = mkDefault name;
    };
  };

in

{
  ###### Interface

  options = {

    services.pmade-opendkim = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to run the OpenDKIM server.
        '';
      };

      user = mkOption {
        default = defaultUser;
        example = "john";
        type = types.str;
        description = ''
          The name of an existing user account to use to own the
          OpenDKIM server process.  If not specified, a default user
          will be created to own the process.
        '';
      };

      interface = mkOption {
        default = "127.0.0.1";
        example = "127.0.0.1";
        type = types.str;
        description = ''
          The interface the OpenDKIM deamon will be listening to.  If
          `127.0.0.1', only clients on the local host can connect to
          it; if `0.0.0.0', clients can access it from any network
          interface.
        '';
      };

      port = mkOption {
        default = 12301;
        example = 12301;
        type = types.int;
        description = ''
          Specifies the port on which to listen.
        '';
      };

      extraTrustedHosts = mkOption {
        type = types.listOf types.str;
        default = [ "127.0.0.1" "localhost" "::1" ];
        example = [ "127.0.0.1" "localhost" "::1" ];
        description = ''
          Identifies an extra set internal hosts whose mail should be signed
          rather than verified.
        '';
      };

      extraConf = mkOption {
        default = "";
        type = types.lines;
        description = ''
          Extra config to add to the bottom of the `opendkim.conf' file.
        '';
      };

      hosts = mkOption {
        default = {};
        example =
          { "example.com" = {
              addressWildcard = "*@example.com";
              signingDomain = "example.com";
              selector = "20150303";
              privateKey = "...";
            };
          };
        description = ''
          The configuration for each host to sign mail for.
        '';
        type = types.loaOf types.optionSet;
        options = [ hostOpts ];
      };
    };
  };

  ###### Implementation

  config = mkIf cfg.enable {

    systemd.services.opendkim = {
      description = "OpenDKIM Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.service" ];

      serviceConfig = {
        Restart   = "on-failure";
        ExecStart = "${pkgs.opendkim}/bin/opendkim -P ${pidFile} -x ${openDKIMConfFile}";
        KillMode  = "process";
        Type      = "forking";
        PIDFile   = pidFile;
      };

      preStart = ''
        ${pkgs.coreutils}/bin/mkdir -p                      ${homeDir}
        ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.user} ${homeDir}
        ${pkgs.coreutils}/bin/chmod 0770                    ${homeDir}

        # HACK: Copy key files into a place where they can be secured
        # since /nix/store is always readable.  This just gets around
        # OpenDKIM refusing to use the keys, it doesn't prevent
        # someone from seeing the keys in /nix/store.
        ${concatMapStrings (host: ''
          ${pkgs.coreutils}/bin/cp ${openHostPrivateKey host} ${hostPrivateKey host}
          ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.user} ${hostPrivateKey host}
          ${pkgs.coreutils}/bin/chmod 0640                    ${hostPrivateKey host}
        '') (attrValues cfg.hosts)}
      '';
    };

    users.extraUsers = optional (cfg.user == defaultUser)
      { name = defaultUser;
        description = "OpenDKIM server daemon owner";
        group = defaultUser;
        # uid = config.ids.uids.opendkim;
        uid = 208;
        createHome = true;
        home = homeDir;
      };

    users.extraGroups = optional (cfg.user == defaultUser)
      { name = defaultUser;
        # gid = config.ids.gids.opendkim;
        gid = 208;
        members = [ defaultUser ];
      };
  };
}
