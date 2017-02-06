# Build the Haskell package that is in the current directory.
{ nixpkgs ? import <nixpkgs> {}
}:

let
  pkgs = nixpkgs.pkgs;

  # My super awesome Haskell builder:
  myHaskellBuilder = with pkgs; callPackage ./builder.nix {
    forceLocal = true;
  };

  # We'll let stack deal with the packages:
  haskpkgs = p: [ ];

in myHaskellBuilder haskpkgs {
  name    = "generic-stack-package";
  version = "0.0.0.0";

  buildInputs = with pkgs; [
    zlib  # Very common Haskell dependency.
  ];

  shellHook = ''
    # Make stack happy:
    export GPG_TTY=`tty`
  '';
}
