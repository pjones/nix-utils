let
  pkgs    = import <nixpkgs> {};
  stdenv  = pkgs.stdenv;
  haskell = pkgs.haskell.packages.ghc784.ghcWithPackages (x: with x; [
              cabal-install
              hlint
              base
            ]);
in rec {
  cltc-dodo = stdenv.mkDerivation rec {
    name = "cltc-dodo";
    version = "0.0";
    src = ./.;

    buildInputs = with pkgs; [
      haskell zlib
    ];

    shellHook = with pkgs; ''
      # Needed for template Haskell:
      LD_LIBRARY_PATH=${zlib}/lib
    '';
  };
}
