{ config, lib, pkgs, ... }:

with lib;

let cfg = config.websites.devalot;
    localPkgs = import ../../lib/unstable.nix;
    backend = "${localPkgs.devalot-www}/bin/devalot-backend";
    workingDir = "/var/lib/devalot";

in
{
  ###### Interface
  options = {
    websites.devalot = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the devalot.com website.";
      };

      port = mkOption {
        type = types.int;
        default = 8000;
        description = "Port number for the Devalot backend server.";
      };

      user = mkOption {
        type = types.str;
        default = "nobody";
        description = "Devalot backend server user.";
      };

      group = mkOption {
        type = types.str;
        default = "nogroup";
        description = "Devalot backend server group.";
      };
    };
  };

  ###### Implementation
  config = mkIf cfg.enable {

    # Firewall Settings:
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    # Extra packages needed:
    environment.systemPackages = [
      localPkgs.devalot-www
    ];

    # Apache Virtual Host Configuration:
    services.httpd.virtualHosts = [{
      hostName = "devalot.com";
      serverAliases = [ "www.devalot.com" ];

      adminAddr = "domains@pmade.com";
      documentRoot = "${workingDir}/www";
      logFormat = "combined";

      #enableSSL = true;

      # Ancillary files.
      servedDirs = [
        {dir = "${workingDir}/files"; urlPath = "/files";}
      ];

      extraConfig = ''
        # Turn off directory indexes for /files:
        <Directory "${workingDir}/files">
          Options -Indexes
        </Directory>

        RewriteEngine On
        # RewriteLog "/var/log/apache2/rewrite.log"
        # RewriteLogLevel 3

        # Force all traffic to www.
        RewriteCond %{HTTP_HOST} !^www\.devalot\.com$ [NC]
        RewriteRule ^(.*)$ http://www.devalot.com$1 [R=301,L,QSA]

        # Rewrite old tags URLs to new topics URLs.
        # Step 1.  Lowercase, run rules again.
        RewriteMap lc int:tolower
        RewriteCond %{REQUEST_URI} ^/tags/.+$
        RewriteRule ^/tags/(.*[A-Z].*)$ /tags/''${lc:$1} [N]

        # Step 2.  Replace a single underscores.
        RewriteCond %{REQUEST_URI} ^/tags/(.+)
        RewriteRule (.*)_(.*) $1-$2 [N]

        # Step 3.  Redirect the user to /topics via a 301.
        RewriteRule ^/tags/?$ /topics/index.html [R=301,L]
        RewriteRule ^/tags/(.+)$ /topics/$1.html [R=301,L]

        # Article directories should go to the archive index.
        RewriteRule ^/articles/(\d+)/?$     /articles/archive/$1.html
        RewriteRule ^/articles/(\d+)/\d+/?$ /articles/archive/$1.html

        # /feedback is now at /contact.html
        RewriteRule ^/feedback/?$ /contact.html [R=301,L]

        # If the request doesn't have ".html" and adding that extension
        # results in a valid file, tack it on automatically.
        RewriteCond %{THE_REQUEST} ^(GET|HEAD)
        RewriteCond %{DOCUMENT_ROOT}%{REQUEST_URI}.html -f
        RewriteRule ^(.+)$ $1.html [L,PT]

        # Set up the proxy to the backend JSON server.
        ProxyRequests Off
        ProxyVia Off
        ProxyPass /json/ http://127.0.0.1:${toString cfg.port}/json/
      '';
    }];

    # Start the site backend server:
    systemd.services.devalot-backend = {
      description = "Devalot.com Backend Server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.service" ];

      serviceConfig = {
        WorkingDirectory = "-${workingDir}";
        ExecStart = "${backend} -b 127.0.0.1 -p ${toString cfg.port} -e production -q";
        Restart = "always";
        KillMode = "process";
        Type = "simple";

        PermissionsStartOnly = true;
        User = cfg.user;
        Group = cfg.group;
      };

      preStart = ''
        ${pkgs.coreutils}/bin/mkdir -p ${workingDir}/log
        ${pkgs.coreutils}/bin/chown -R ${cfg.user}:${cfg.group} ${workingDir}

        ${pkgs.coreutils}/bin/mkdir -p ${workingDir}/files
        ${pkgs.coreutils}/bin/chown -R wwwrun:wwwrun ${workingDir}/files

        # Bootstrap the document root:
        if [ ! -d ${workingDir}/www ]; then
          ${pkgs.coreutils}/bin/cp -r ${localPkgs.devalot-www}/www ${workingDir}/www
          ${pkgs.coreutils}/bin/chown -R wwwrun:wwwrun ${workingDir}/www
        fi
      '';
    };
  };
}
