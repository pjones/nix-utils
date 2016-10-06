let
  pkgs   = import <nixpkgs> {};
  stdenv = pkgs.stdenv;
  hsenv  = pkgs.haskell.packages.lts-5_15;
in stdenv.mkDerivation rec {
  name = "purescript-env";
  version = "0.0";
  src = ./.;

  buildInputs = with pkgs; [
    hsenv.purescript nodejs
  ];

  shellHook = ''
    if [ ! -d node_modules/pulp ]; then
      npm install pulp
    fi

    export PATH=node_modules/.bin:$PATH
  '';
}
