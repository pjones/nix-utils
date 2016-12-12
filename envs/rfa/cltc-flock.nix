let pkgs = import <nixpkgs> {};
in (pkgs.callPackage ../../lib/ruby { }) {

  ##############################################################################
  name  = "cltc-flock";
  ruby  = pkgs.ruby_2_2;
  mysql = pkgs.mysql;

  ##############################################################################
  # Load some additional Nix helper files:
  extras = [ "mysql" "nokogiri" "v8" ];

  ##############################################################################
  buildInputs = with pkgs; [
    inetutils # for hostname(1)
  ];
}
