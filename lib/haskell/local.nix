# Build the Haskell package that is in the current directory.
{ nixpkgs ? import <nixpkgs> {}
}:

let
  pkgs = nixpkgs.pkgs;

  # My super awesome Haskell builder:
  myHaskellBuilder = with pkgs; callPackage ./builder.nix { };

  # The path to the package.nix file:
  filepath = builtins.getEnv "HASKELL_NIX_FILE";

  # Load the file given to us in NIX_PATH:
  local = pkgs.callPackage filepath {
    myHaskellBuilder = myHaskellBuilder.override {
      forceLocal = true;
    };
  };

in local
