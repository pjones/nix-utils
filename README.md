# My Nix Packages and Utilities

This repository is a collection personal packages and utilities that I
use to manage my user environment in [NixOS][].  It also includes a
list of packages that should be installed for each machine that I
manage.  The packages are then installed in an atomic manner.

## Utilities

  * `nix-repo`: A utility to manage my fork of `nixpkgs` so that I can
    maintain a known stable package repository and cherry pick
    upstream changes as I wish.  This utility is just a simple wrapper
    around git and some system tools.

## Environments

This repository also contains specific Nix environments.  That is, Nix
files that create a temporary shell environment with certain tools
installed and the shell configured properly.  These environment files
are meant to be used with `nix-shell`.

[nixos]: http://nixos.org/
