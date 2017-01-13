################################################################################
# My own custom module for running pflogsumm once a day.
{ config, lib, pkgs, ...}:

with lib;

let cfg = config.services.pmade.pflogsumm;

    journalctl = "${pkgs.systemd}/bin/journalctl";
    sendmail   = "${pkgs.postfix}/bin/sendmail";
    pflogsumm  = "${pkgs.pflogsumm}/bin/pflogsumm";

    script = pkgs.writeScript "pflogsumm-script" ''
      #!/bin/sh -eu

      body=`${journalctl} -u postfix | ${pflogsumm} -d yesterday`

      cat <<EOT | ${sendmail} "${cfg.to}"
      From: ${cfg.to}
      To: ${cfg.to}
      Subject: Nightly Postfix Statistics

      $body
      EOT
    '';
in
{
  ###### Interface
  options = {

    services.pmade.pflogsumm = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable nightly pflogsumm.";
      };

      to = mkOption {
        type = types.str;
        example = "foo@example.com";
        description = "Who to email the report to.";
      };

      user = mkOption {
        type = types.str;
        default = "postfix";
        description = "User to run pflogsumm as.";
      };

      group = mkOption {
        type = types.str;
        default = "systemd-journal";
        description = "Group to run pflogsumm as.";
      };
    };
  };

  ###### Implementation
  config = mkIf cfg.enable {
    # Packages
    environment.systemPackages = [ pkgs.pflogsumm ];

    systemd.timers.pflogsumm = {
      description = "Postfix Nightly Statistics";
      wantedBy    = [ "timers.target" ];

      timerConfig = {
        OnCalendar = "01:05";
        Unit = "pflogsumm.service";
      };
    };

    systemd.services.pflogsumm = {
      description = "Postfix Statistics via pflogsumm";

      serviceConfig = {
        ExecStart = "${script}";
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
      };
    };
  };
}
