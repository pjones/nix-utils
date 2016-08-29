let pkgs   = import <nixpkgs> {};
in (pkgs.callPackage ../../lib/ruby { }) {

  ##############################################################################
  name  = "cltc-claims";
  ruby  = pkgs.ruby_2_3;
  mysql = pkgs.mysql;

  ##############################################################################
  # Load some additional Nix helper files:
  extras = [ "mysql" ];

  ##############################################################################
  # Extra packages.
  buildInputs = with pkgs; [ ];
}
