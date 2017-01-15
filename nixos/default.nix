{ ... }:

{
  imports = [
    # Override existing NixOS modules:
    ./override/opendkim.nix
    ./override/rmilter.nix
    ./override/pflogsumm.nix
    ./override/vsftpd.nix
    ./override/dovecot.nix

    # Custom NixOS modules:
    ./services/mail/server/default.nix

    # Websites:
    ./websites/devalot.com.nix
  ];
}
