let
  pkgs     = import <nixpkgs> {};
  stdenv   = pkgs.stdenv;
  fetchgit = pkgs.fetchgit;

in stdenv.mkDerivation {
  name    = "twrp";
  version = "3.0.4";
  repo    = "git://github.com/omnirom/android.git";
  branch  = "android-7.1";

  src = fetchgit {
    url    = repo;
    rev    = "2d2281b4ebc3c3a8718d8d233a14d39ce5a3f815";
    sha256 = "1q7vimjf7dwkwbzd3n8r6wlh6f14g6srh5z24yg1ywpn1mlgrpdp";
  };

  buildInputs = with pkgs; [
    gitRepo # the repo tool
    gnupg   # wanted by the repo tool
  ];

  postUnpack = ''
    [ -n "$out" ] && cd "$out"
    repo init -u ${repo} -b ${branch}
    repo sync
  '';

  shellHook = ''
    if [ -r default.xml ]; then
      eval $postUnpack
    fi
  '';
}
