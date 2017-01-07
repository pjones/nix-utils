{ pkgs, ... }:

{
  # Packages for software development.
  packages = with pkgs; [
    # Revision Control Systems:
    gitAndTools.gitFull gitAndTools.gitAnnex darcs mr
    haskellPackages.gitit

    # Build tools:
    gnumake

    # Haskell Development:
    haskellPackages.stack
    haskellPackages.ghc-mod
    haskellPackages.hlint
    haskellPackages.hoogle

    # Hardware Hacking.
    arduino_core avrdude picocom eagle openscad geda ngspice

    # JavaScript Development
    nodejs nodePackages.jshint
  ];
}
