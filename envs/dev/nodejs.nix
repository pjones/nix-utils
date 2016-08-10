let
  pkgs   = import <nixpkgs> {};
  stdenv = pkgs.stdenv;
in rec {
  nodejsenv = stdenv.mkDerivation rec {
    name = "nodejsenv";
    version = "0.0";
    src = ./.;

    buildInputs = with pkgs; [
      nodejs
    ];

    shellHook = "";
  };
}
