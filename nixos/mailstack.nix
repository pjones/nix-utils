# A complete mail stack (Postfix, Dovecot, Spam Filtering, and OpenDKIM).
{ config, lib, pkgs, ...}:

with lib;

let
  cfg = config.services.pmade-mailstack;

  # Helpful Aliases:
  dovecot  = config.services.pmade-dovecot2;
  rmilter  = config.services.pmade-rmilter;
  opendkim = config.services.pmade-opendkim;

  # Virtual Mail Accounts:
  accountOpts = { name, ... }: {
    options = {
      username = mkOption {
        type = types.str;
        example = "jdoe";
        description = "Account username.";
      };

      localPart = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "jdoe";
        description = "Email address local part if different than username.";
      };

      aliases = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "joe@host.com" ];
        description = "Additional addresses this user is allowed to use.";
      };

      password = mkOption {
        type = types.str;
        example = "{SSHA}XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
        description = "Encrypted password for postfix and dovecot.";
      };

      command = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "maildrop -d jdoe";
        description = "Optional mail delivery command.";
      };

      home = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/home/jdoe";
        description = "Home directory.  Defaults to virtual home.";
      };

      uid = mkOption {
        type = types.int;
        default = cfg.virtualUID;
        example = 1000;
        description = "UID for file permissions.  Defaults to virtual UID.";
      };

      gid = mkOption {
        type = types.int;
        default = cfg.virtualGID;
        example = 1000;
        description = "GID for file permissions.  Defaults to virtual GID.";
      };
    };

    config = {
      username = mkDefault name;
    };
  };

  # Virtual Host Configuration:
  hostOpts = { name, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        example = "example.com";
        description = "FQDN of the host.";
      };

      aliases = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          john = "jdoe";
        };
        description = "List of virtual aliases.";
      };

      accounts = mkOption {
        type = types.loaOf types.optionSet;
        options = [ accountOpts ];
        default = { };
        example = {
          jdoe = {
            password = "{SSHA}XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
          };
        };
      };
    };

    config = {
      name = mkDefault name;
    };
  };

  # Calculate an Account's Home Directory:
  homeDir = {host, account}:
    if account.home != null
      then account.home
      else "${cfg.vhostDir}/${host.name}/${account.username}";

  # Other files:
  dovecotAuthSocket = "dovecot-auth";
  dovecotLMTPSocket = "dovecot-lmtp";

  # SSL Certificate Files:
  sslCACertFile     = pkgs.writeText "cacert" cfg.sslCACert;
  sslServerCertFile = pkgs.writeText "cert"   cfg.sslServerCert;
  sslServerKeyFile  = pkgs.writeText "key"    cfg.sslServerKey;

  # Aliases Files:
  aliasList = {aliases, suffix ? ""}:
    concatMapStrings (n: "${n}${suffix}\t${getAttr n aliases}\n") (attrNames aliases);

  # Postfix master.cf:
  masterCf = ''
    # ==========================================================================
    # service type  private unpriv  chroot  wakeup  maxproc command + args
    #               (yes)   (yes)   (yes)   (never) (100)
    # ==========================================================================
    smtp      inet  n       -       n       -       -       smtpd
    465       inet  n       -       n       -       -       smtpd
     -o smtpd_tls_wrappermode=yes
     -o smtpd_sasl_auth_enable=yes
    pickup    fifo  n       -       n       60      1       pickup
    cleanup   unix  n       -       n       -       0       cleanup
    qmgr      fifo  n       -       n       300     1       qmgr
    tlsmgr    unix  -       -       n       1000?   1       tlsmgr
    rewrite   unix  -       -       n       -       -       trivial-rewrite
    bounce    unix  -       -       n       -       0       bounce
    defer     unix  -       -       n       -       0       bounce
    trace     unix  -       -       n       -       0       bounce
    verify    unix  -       -       n       -       1       verify
    flush     unix  n       -       n       1000?   0       flush
    proxymap  unix  -       -       n       -       -       proxymap
    proxywrite unix -       -       n       -       1       proxymap
    smtp      unix  -       -       n       -       -       smtp
    relay     unix  -       -       n       -       -       smtp
      -o smtp_fallback_relay=
    showq     unix  n       -       n       -       -       showq
    error     unix  -       -       n       -       -       error
    retry     unix  -       -       n       -       -       error
    discard   unix  -       -       n       -       -       discard
    local     unix  -       n       n       -       -       local
    virtual   unix  -       n       n       -       -       virtual
    lmtp      unix  -       -       n       -       -       lmtp
    anvil     unix  -       -       n       -       1       anvil
    scache    unix  -       -       n       -       1       scache
    maildrop  unix  -       n       n       -       -       pipe
      flags=DRhu user=${cfg.virtualUser} argv=${pkgs.maildrop}/bin/maildrop -d ''${recipient}
  '';

  # Postfix main.cf:
  mainCf = ''
    # Backwards compatibility for the configuration syntax:
    compatibility_level=3

    # Directories and Users
    queue_directory = ${cfg.postfixBaseDir}/queue
    command_directory = ${pkgs.postfix}/sbin
    daemon_directory = ${pkgs.postfix}/libexec/postfix
    mail_owner = ${cfg.postfixUser}
    default_privs = nobody

    # Identity Settings
    myhostname = ${cfg.externalServerName}
    myorigin = $myhostname
    mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 ${concatStringsSep " " cfg.trustedRelayServers}
    relayhost =
    inet_interfaces = all

    # Local Delivery
    mailbox_transport = lmtp:unix:${cfg.postfixBaseDir}/${dovecotLMTPSocket}
    mailbox_size_limit = 0
    recipient_delimiter = +
    home_mailbox = mail/

    # Restrictions and Spam Blocking
    smtpd_sender_login_maps = hash:${cfg.postfixBaseDir}/etc/sender_login_maps

    smtpd_helo_restrictions =
      permit_sasl_authenticated,
      reject_unknown_helo_hostname,
      permit

    smtpd_client_restrictions =
      permit_sasl_authenticated,
      reject_rbl_client zen.spamhaus.org,
      permit

    smtpd_recipient_restrictions =
      permit_mynetworks,
      permit_sasl_authenticated,
      reject_unknown_sender_domain,
      reject_unknown_recipient_domain,
      reject_unauth_pipelining,
      reject_non_fqdn_recipient,
      reject_unverified_recipient,
      reject_unauth_destination,
      reject_rbl_client zen.spamhaus.org,
      reject_rhsbl_reverse_client dbl.spamhaus.org,
      reject_rhsbl_helo dbl.spamhaus.org,
      reject_rhsbl_sender dbl.spamhaus.org,
      permit

    smtpd_sender_restrictions =
      reject_sender_login_mismatch,
      permit_sasl_authenticated,
      reject_unknown_sender_domain,
      reject_non_fqdn_sender,
      check_sender_access hash:${cfg.postfixBaseDir}/etc/sender_access,
      permit

    smtpd_relay_restrictions =
      permit_sasl_authenticated,
      reject_unauth_destination,
      permit

    # Database and File Mappings
    mydestination = hash:${cfg.postfixBaseDir}/etc/hostnames
    alias_maps = hash:${cfg.postfixBaseDir}/etc/aliases
    alias_database = hash:${cfg.postfixBaseDir}/etc/aliases

    # Virtual Hosting
    virtual_mailbox_base = ${cfg.postfixBaseDir}/vhosts
    virtual_mailbox_domains = hash:${cfg.postfixBaseDir}/etc/virtualhosts
    virtual_mailbox_maps = hash:${cfg.postfixBaseDir}/etc/virtualdirs
    virtual_alias_maps = hash:${cfg.postfixBaseDir}/etc/virtualaliases
    virtual_minimum_uid = 5000
    virtual_uid_maps = static:${toString cfg.virtualUID}
    virtual_gid_maps = static:${toString cfg.virtualGID}
    virtual_transport = lmtp:unix:${cfg.postfixBaseDir}/${dovecotLMTPSocket}

    # TLS parameters
    smtp_tls_session_cache_database = btree:${cfg.postfixBaseDir}/cache/smtp_scache
    smtp_use_tls = yes
    smtpd_tls_auth_only = yes
    smtpd_tls_cert_file = ${sslServerCertFile}
    smtpd_tls_key_file  = ${sslServerKeyFile}
    smtpd_tls_mandatory_ciphers = medium
    smtpd_tls_mandatory_protocols = SSLv3, TLSv1
    smtpd_tls_received_header = yes
    smtpd_tls_session_cache_database = btree:${cfg.postfixBaseDir}/cache/smtpd_scache
    smtpd_use_tls = yes
    tls_random_source = dev:/dev/urandom
    broken_sasl_auth_clients = yes

    # Authentication:
    smtpd_sasl_auth_enable = yes
    smtpd_sasl_authenticated_header = yes
    smtpd_sasl_local_domain = $myhostname
    smtpd_sasl_path = ${cfg.postfixBaseDir}/${dovecotAuthSocket}
    smtpd_sasl_security_options = noanonymous
    smtpd_sasl_type = dovecot

    # Mail Filtering and Signing (DKIM, SPAM, etc.):
    #
    # Below, the `{auth_type}' macro is mandatory for OpenDKIM to work correctly.
    #
    milter_protocol = 6
    milter_default_action = tempfail
    milter_mail_macros = i {mail_addr} {client_addr} {client_name} {auth_authen} {auth_type}
    smtpd_milters = inet:${head rmilter.bindInetSockets} inet:127.0.0.1:${toString opendkim.port}
    non_smtpd_milters = inet:127.0.0.1:${toString opendkim.port}

    # Other Random Settings
    smtpd_banner = $myhostname ESMTP $mail_name
    biff = no
    append_dot_mydomain = no
    readme_directory = no
    message_size_limit = 104857600
  '';

  # Postfix Hostnames File:
  hostnamesCf = ''
    localhost 1
    ${cfg.externalServerName} 1
    ${config.networking.hostName}.${config.networking.domain} 1
  '';

  # Postfix Local Delivery Commands:
  localCommands = concatMapStrings
    (account: "${account.username}\t${account.command}\n")
    (filter (account: account.command != null)
      (concatMap (host: attrValues host.accounts) (attrValues cfg.virtualhosts)));

  # Postfix Sender Access File:
  # FIXME: can we use just hostnames in here?
  senderAccess =
    concatMapStrings (addr: "${addr}\tREJECT\n") cfg.blockedSenders;

  # Postfix virtualhosts:
  virtualHostnames =
    concatMapStrings (host: "${host.name}\t1\n")
        (attrValues cfg.virtualhosts);

  # Postfix virtualdirs:
  # Where to place mail for users without unix accounts.
  virtualDirs = concatMapStrings
    (host: concatMapStrings
      (account: let local = (if account.localPart != null then account.localPart else account.username); in
        "${local}@${host.name}\t${removePrefix cfg.vhostDir (homeDir {inherit host account;})}/mail/\n")
        (attrValues host.accounts)) (attrValues cfg.virtualhosts);

  # Postfix virtualaliases:
  # Aliases for virtualhosts.
  virtualAliases =
    concatMapStrings (host: aliasList {aliases=host.aliases; suffix="@" + host.name;})
      (attrValues cfg.virtualhosts);

  # Postfix and Dovecot Password Entries:
  passwords =
    let common = h: a: ":${a.password}:${toString a.uid}:${toString a.gid}::${homeDir {host=h; account=a;}}::";
        local  = h: a: if a.localPart != null then a.localPart else a.username;
        entry  = h: a: "${a.username}${common h a}\n${local h a}@${h.name}${common h a}\n";
    in # Virtual users:
       (concatMapStrings
         (host: concatMapStrings
                  (account: entry host account)
                  (attrValues host.accounts))
         (attrValues cfg.virtualhosts)) +
       # System users:
       (concatMapStrings
         (user: let h = {name = cfg.externalServerName;};
                in entry h user)
         (attrValues cfg.systemUsers));

  # A lookup table that maps sender email addresses to authenticated
  # user names.  This prevents users from sending email from forged
  # `From:' addresses:
  senderMap =
    let entry = user: hostname: email: "${email}\t${user.username},${local user}@${hostname}\n";
        addr  = user: hostname: "${local user}@${hostname}";
        local = user: if user.localPart != null then user.localPart else user.username;
    in # Loop over all virtual hosts accounts:
       (concatMapStrings
         (host: (concatMapStrings
                  (account: entry account host.name (addr account host.name))
                  (attrValues host.accounts)))
         (attrValues cfg.virtualhosts)) +
       # System users:
       (concatMapStrings
         (user: entry user cfg.externalServerName (addr user cfg.externalServerName) +
                (concatMapStrings
                  (alias: entry user cfg.externalServerName alias)
                  (user.aliases)))
         (attrValues cfg.systemUsers));

  # Put the Files in the Nix Store:
  masterCfFile         = pkgs.writeText "postfix-master.cf" masterCf;
  mainCfFile           = pkgs.writeText "postfix-main.cf" mainCf;
  masterAliasFile      = pkgs.writeText "postfix-aliases" (aliasList {aliases=cfg.aliases; suffix=":";});
  hostnamesCfFile      = pkgs.writeText "postfix-hostnames" hostnamesCf;
  localCommandsFile    = pkgs.writeText "postfix-localdelivery" localCommands;
  senderAccessFile     = pkgs.writeText "postfix-senderaccess" senderAccess;
  virtualHostnamesFile = pkgs.writeText "postfix-virtualhosts" virtualHostnames;
  virtualDirsFile      = pkgs.writeText "postfix-virtualdirs" virtualDirs;
  virtualAliasesFile   = pkgs.writeText "postfix-virtualaliases" virtualAliases;
  passwordsFile        = pkgs.writeText "postfix-passwd" passwords;
  senderMapFile        = pkgs.writeText "postfix-sendermap" senderMap;
in
{
  ###### Interface

  options = {

    services.pmade-mailstack = {

      ##########################################################################
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the full mail stack";
      };

      ##########################################################################
      externalServerName = mkOption {
        type = types.str;
        default = "pmade.com";
        example = "pmade.com";
        description = "Local users must be configured for this domain.";
      };

      ##########################################################################
      postfixBaseDir = mkOption {
        type = types.path;
        default = "/var/lib/postfix";
        example = "/var/lib/postfix";
        description = "Base directory where postfix files are stored.";
      };

      ##########################################################################
      sslCACert = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Contents of the CA certificate";
      };

      ##########################################################################
      sslServerCert = mkOption {
        type = types.str;
        default = "";
        description = "Contents of the server's SSL certificate";
      };

      ##########################################################################
      sslServerKey = mkOption {
        type = types.str;
        default = "";
        description = "Contents of the server's private SSL key";
      };

      ##########################################################################
      aliases = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          root = "jdoe";
          postmaster = "root";
        };
        description = "Entries for the master aliases file.";
      };

      ##########################################################################
      blockedSenders = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "foo@example.com" ];
        description = ''
          List of sender address to immediately reject.
          See http://www.postfix.org/access.5.html
        '';
      };

      ##########################################################################
      trustedRelayServers = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "192.168.1.2" ];
        description = "IP addresses that Postfix should trust as a relay.";
      };

      ##########################################################################
      systemUsers = mkOption {
        type = types.loaOf types.optionSet;
        options = [ accountOpts ];
        default = { };
        example = {
          jdoe = {
            password = "{SSHA}XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
            home = "/home/jdoe";
          };
        };
      };

      ##########################################################################
      virtualhosts = mkOption {
        type = types.loaOf types.optionSet;
        options = [ hostOpts ];
        default = { };
        example = {
          "example.com" = {
            accounts.jdoe.password = "{SSHA}XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
            aliases.john = "jdoe";
          };
        };
      };

      ##########################################################################
      postfixUser = mkOption {
        type = types.str;
        default = "postfix";
        example = "postfix";
        description = "The username used for the Postfix mail server.";
      };

      ##########################################################################
      postfixGroup = mkOption {
        type = types.str;
        default = cfg.postfixUser;
        example = "postfix";
        description = "The group name used for the Postfix mail server.";
      };

      ##########################################################################
      postfixSetgidGroup = mkOption {
        type = types.str;
        default = "postdrop";
        example = "postdrop";
        description = "Name of the setgid Postfix group.";
      };

      ##########################################################################
      vhostDir = mkOption {
        type = types.str;
        default = "/var/lib/virtmail";
        example = "/var/lib/virtmail";
        description = "The directory where virtual mail users live.";
      };

      ##########################################################################
      virtualUser = mkOption {
        type = types.str;
        default = "vmail";
        example = "vmail";
        description = "The username used for the virtualhosts accounts.";
      };

      ##########################################################################
      virtualGroup = mkOption {
        type = types.str;
        default = cfg.virtualUser;
        example = "vmail";
        description = "The group name used for the virtualhosts accounts.";
      };

      ##########################################################################
      virtualUID = mkOption {
        type = types.int;
        default = 5000;
        example = 5000;
        description = "The UID used for virtualhost accounts.";
      };

      ##########################################################################
      virtualGID = mkOption {
        type = types.int;
        default = cfg.virtualUID;
        example = 5000;
        description = "The GID used for virtualhost accounts.";
      };
    };
  };

  ###### Implementation

  config = mkIf cfg.enable {

    ############################################################################
    # Open firewall ports for the services.
    networking.firewall.allowedTCPPorts = [ 25 465 993 ];

    ############################################################################
    # Push postfix tools into the system PATH.
    environment.systemPackages = with pkgs;
      [ postfix
        pdnsd
        dovecot_pigeonhole
      ];

    ############################################################################
    # Force running a DNS caching server.
    networking.nameservers = [ "127.0.0.1" ];
    services.pdnsd.enable = true;

    services.pdnsd.globalConfig = ''
      status_ctl=on;
    '';

    services.pdnsd.serverConfig = ''
      label=google;
      ip=8.8.8.8,8.8.4.4,208.67.222.222,208.67.220.220;
      uptest=ping;
    '';

    ############################################################################
    # Dovecot Configuration:
    services.pmade-dovecot2.enable = true;
    services.pmade-dovecot2.enablePAM = false;
    services.pmade-dovecot2.enableImap = true;
    services.pmade-dovecot2.enablePop3 = false;
    services.pmade-dovecot2.enableLmtp = true;
    services.pmade-dovecot2.mailUser = cfg.virtualUser;
    services.pmade-dovecot2.mailGroup = cfg.virtualGroup;
    services.pmade-dovecot2.mailLocation = "maildir:~/mail:INBOX=~/mail";
    services.pmade-dovecot2.modules = with pkgs; [ dovecot_antispam dovecot_pigeonhole ];
    services.pmade-dovecot2.sslCACert = "${sslCACertFile}";
    services.pmade-dovecot2.sslServerCert = "${sslServerCertFile}";
    services.pmade-dovecot2.sslServerKey = "${sslServerKeyFile}";

    # Extra dovecot2 config:
    services.pmade-dovecot2.extraConfig = ''
      # mail_debug = yes

      service auth {
        unix_listener ${cfg.postfixBaseDir}/${dovecotAuthSocket} {
          mode = 0660
          user = ${cfg.postfixUser}
          group = ${cfg.postfixGroup}
        }
      }

      service lmtp {
        unix_listener ${cfg.postfixBaseDir}/${dovecotLMTPSocket} {
          mode = 0660
          user = ${cfg.postfixUser}
          group = ${cfg.postfixGroup}
        }
      }

      passdb {
        driver = passwd-file
        args = scheme=CRYPT username_format=%u ${passwordsFile}
      }

      userdb {
        driver = passwd-file
        args = username_format=%u ${passwordsFile}
      }

      protocol imap {
        mail_plugins = $mail_plugins antispam
        mail_max_userip_connections = 10
        imap_client_workarounds = delay-newmail
      }

      protocol lmtp {
        postmaster_address = postmaster@pmade.com
        mail_plugins = $mail_plugins quota sieve
      }

      namespace inbox {
        inbox = yes
        separator = /

        mailbox Drafts {
          auto = create
          special_use = \Drafts
        }
        mailbox Junk {
          auto = create
          autoexpunge = 30d
          special_use = \Junk
        }
        mailbox Trash {
          auto = create
          special_use = \Trash
        }
        mailbox Sent {
          auto = subscribe
          special_use = \Sent
        }
        mailbox "Sent Messages" {
          special_use = \Sent
        }
      }

      plugin {
        antispam_backend            = mailtrain
        antispam_spam               = Junk
        antispam_trash              = Trash
        antispam_mail_sendmail      = ${pkgs.rspamd}/bin/rspamc
        antispam_mail_spam          = learn_spam
        antispam_mail_notspam       = learn_ham
      }

      # Sieve configuration for rspamd:
      plugin {
        sieve = file:~/sieve;active=~/.dovecot.sieve
        sieve_plugins = sieve_extprograms
        sieve_global_extensions = +vnd.dovecot.environment
        sieve_extensions = +spamtest +spamtestplus +vnd.dovecot.filter
        sieve_spamtest_status_type   = score
        sieve_spamtest_status_header = X-Spamd-Result: default: [[:alnum:]]+ \[([-.[:digit:]]+)
        sieve_spamtest_max_header    = X-Spamd-Result: default: [[:alnum:]]+ \[[-.[:digit:]]+ / ([-.[:digit:]]+)
      }
    '';

    services.pmade-dovecot2.sieveScripts = {
      # Move spam messages to the Junk folder:
      before = pkgs.writeText "sieve-no-spam" ''
        require "spamtestplus";
        require "fileinto";
        require "relational";
        require "comparator-i;ascii-numeric";
        require "imap4flags";

        if spamtest :value "ge" :comparator "i;ascii-numeric" :percent "50" {
          setflag "\\seen";
          fileinto "Junk";
          stop;
        }
      '';

      # Move messages to folders based on subaddress (+):
      before2 = pkgs.writeText "sieve-subaddress" ''
        require ["variables", "envelope", "fileinto", "subaddress"];

        if envelope :matches :detail "to" "*" {
          set :lower :upperfirst "name" "''${1}";

          if not string :is "''${name}" "" {
           fileinto "''${name}";
          }
        }
      '';

      # Move mailing list messages to their own folder:
      before3 = pkgs.writeText "sieve-mailing-lists" ''
        require ["variables", "fileinto", "mailbox"];

        if header :matches "list-id" "* <*" {
          fileinto :create "mlists/''${1}";
          stop;
        }
      '';
    };

    ############################################################################
    # Spam filter:
    services.rmilter.enable = false; # Must force this off for now.

    services.redis = {
      enable = true;
      bind = "127.0.0.1";
    };

    services.rspamd = {
      enable = true;
      debug = false;
      bindSocket = [
        "/run/rspamd/rspamd.sock mode=0666 owner=rspamd"
        "127.0.0.1:11333"
      ];
    };

    services.pmade-rmilter = {
      enable = true;
      bindInetSockets = [ "127.0.0.1:11990" ];
      socketActivation = false;
      postfix.enable = false; # I'll do this myself.

      rspamd.enable = true;
      rspamd.extraConfig = ''
        # Add all of the X-Spam headers:
        extended_spam_headers = true;
      '';

      extraConfig = ''
        use_redis = true;

        redis {
          servers_grey   = 127.0.0.1:6379;
          servers_white  = 127.0.0.1:6379;
          servers_limits = 127.0.0.1:6379;
          servers_id     = 127.0.0.1:6379;

          # NixOS version of rmilter doesn't understand these:
          # servers_spam   = 127.0.0.1:6379;
          # servers_copy   = 127.0.0.1:6379;
        };
      '';
    };

    ############################################################################
    # User accounts.
    users.extraUsers =
      [ { name = cfg.postfixUser;
          description = "Postfix mail server user";
          uid = config.ids.uids.postfix;
          group = cfg.postfixGroup;
        }
        { name = cfg.virtualUser;
          description = "Virtual Mail User";
          group = cfg.virtualGroup;
          uid = cfg.virtualGID;
          createHome = true;
          home = "${cfg.postfixBaseDir}/vhosts";
        }
      ];

    ############################################################################
    # Groups.
    users.extraGroups =
      [ { name = cfg.postfixGroup;
          gid = config.ids.gids.postfix;
        }
        { name = cfg.postfixSetgidGroup;
          gid = config.ids.gids.postdrop;
        }
        { name = cfg.virtualGroup;
          gid = cfg.virtualGID;
        }
      ];

    ############################################################################
    # System-wide configuration for Maildrop:
    environment.etc."maildroprc".text = ''
      DEFAULT="$HOME/mail"
    '';

    ############################################################################
    # Nightly Statistics:
    services.pmade.pflogsumm.enable = true;
    services.pmade.pflogsumm.to     = "postmaster@${cfg.externalServerName}";

    ############################################################################
    # Run Postfix:
    systemd.services.postfix = {
      description = "Postfix Mail Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.service" ];

      serviceConfig = {
        Restart   = "on-failure";
        ExecStart = "${pkgs.postfix}/bin/postfix -c ${cfg.postfixBaseDir}/etc start";
        ExecStop  = "${pkgs.postfix}/bin/postfix -c ${cfg.postfixBaseDir}/etc stop";
        KillMode  = "process";
        Type      = "forking";
      };

      preStart = ''
        # Create directories and set permissions:
        ${pkgs.coreutils}/bin/rm -rf ${cfg.postfixBaseDir}/etc
        ${pkgs.coreutils}/bin/mkdir -p ${cfg.postfixBaseDir}/{etc,cache,queue}
        ${pkgs.coreutils}/bin/mkdir -p /var/spool/mail
        ${pkgs.coreutils}/bin/chown -R ${cfg.postfixUser}:${cfg.postfixGroup} ${cfg.postfixBaseDir}

        ${pkgs.coreutils}/bin/chown -R ${cfg.postfixUser}:${cfg.postfixGroup} ${cfg.postfixBaseDir}/queue
        ${pkgs.coreutils}/bin/chmod -R ug+rwX ${cfg.postfixBaseDir}/queue

        # Mail spools:
        ${pkgs.coreutils}/bin/chown root:root /var/spool/mail
        ${pkgs.coreutils}/bin/chmod a+rwxt /var/spool/mail
        ${pkgs.coreutils}/bin/ln -snf /var/spool/mail /var/mail
        ${pkgs.coreutils}/bin/mkdir -p ${cfg.vhostDir}

        # Create all of the virtual directories!
        ${concatMapStrings (host: concatMapStrings (account: ''
          ${pkgs.coreutils}/bin/mkdir -p ${homeDir {inherit host account;}}
        '') (attrValues host.accounts)) (attrValues cfg.virtualhosts)}

        ${pkgs.coreutils}/bin/chown -R \
          ${toString cfg.virtualUID}:${toString cfg.virtualGID} ${cfg.vhostDir}

        # Create a bunch of symlinks:
        ${pkgs.coreutils}/bin/ln -nfs ${masterCfFile}         ${cfg.postfixBaseDir}/etc/master.cf
        ${pkgs.coreutils}/bin/ln -nfs ${mainCfFile}           ${cfg.postfixBaseDir}/etc/main.cf
        ${pkgs.coreutils}/bin/ln -nfs ${masterAliasFile}      ${cfg.postfixBaseDir}/etc/aliases
        ${pkgs.coreutils}/bin/ln -nfs ${hostnamesCfFile}      ${cfg.postfixBaseDir}/etc/hostnames
        ${pkgs.coreutils}/bin/ln -nfs ${localCommandsFile}    ${cfg.postfixBaseDir}/etc/localdelivery
        ${pkgs.coreutils}/bin/ln -nfs ${senderAccessFile}     ${cfg.postfixBaseDir}/etc/sender_access
        ${pkgs.coreutils}/bin/ln -nfs ${virtualHostnamesFile} ${cfg.postfixBaseDir}/etc/virtualhosts
        ${pkgs.coreutils}/bin/ln -nfs ${virtualDirsFile}      ${cfg.postfixBaseDir}/etc/virtualdirs
        ${pkgs.coreutils}/bin/ln -nfs ${virtualAliasesFile}   ${cfg.postfixBaseDir}/etc/virtualaliases
        ${pkgs.coreutils}/bin/ln -nfs ${senderMapFile}        ${cfg.postfixBaseDir}/etc/sender_login_maps

        # Hash all the look-up tables:
        ${pkgs.postfix}/bin/postalias -c ${cfg.postfixBaseDir}/etc ${cfg.postfixBaseDir}/etc/aliases
        ${pkgs.postfix}/bin/postmap   -c ${cfg.postfixBaseDir}/etc ${cfg.postfixBaseDir}/etc/hostnames
        ${pkgs.postfix}/bin/postmap   -c ${cfg.postfixBaseDir}/etc ${cfg.postfixBaseDir}/etc/localdelivery
        ${pkgs.postfix}/bin/postmap   -c ${cfg.postfixBaseDir}/etc ${cfg.postfixBaseDir}/etc/sender_access
        ${pkgs.postfix}/bin/postmap   -c ${cfg.postfixBaseDir}/etc ${cfg.postfixBaseDir}/etc/virtualhosts
        ${pkgs.postfix}/bin/postmap   -c ${cfg.postfixBaseDir}/etc ${cfg.postfixBaseDir}/etc/virtualdirs
        ${pkgs.postfix}/bin/postmap   -c ${cfg.postfixBaseDir}/etc ${cfg.postfixBaseDir}/etc/virtualaliases
        ${pkgs.postfix}/bin/postmap   -c ${cfg.postfixBaseDir}/etc ${cfg.postfixBaseDir}/etc/sender_login_maps

        # Expose this whole thing under /etc/postfix:
        ${pkgs.coreutils}/bin/ln -nfs ${cfg.postfixBaseDir}/etc /etc/postfix
      '';
    };
  };
}
