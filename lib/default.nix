{ pkgs ? import <nixpkgs> {}
}:

with import <nixpkgs/lib/lists.nix>; rec {
  # Bootstrap this library.
  boot = hostConfig: process (hostConfig {pkgs = allPkgs;});

  # Process a set containing imports and packages.
  process = { imports ? [], packages ? [] }:
    let others = fold (a: b: load a // b) {} imports; in
    others // pkgSet packages;

  # Turn a list of packages into a set.
  pkgSet = packages:
    fold (a: b: {"${a.name}" = a;} // b) {} packages;

  # Packages in the ../pkgs directory.
  localPkgs = import ../pkgs/default.nix {inherit pkgs;};

  # Local packages and those from nixpkgs.
  allPkgs = localPkgs // pkgs;

  # Load the given file, passing in pkgs.
  load = file: process (import file {pkgs = allPkgs;});
}
