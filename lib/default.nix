{}:

let pkgs = import <nixpkgs> {};
in

with import <nixpkgs/lib/lists.nix>; rec {
  boot = hostConfig: process (hostConfig {pkgs = allPkgs;});

  # Process a set containing imports and packages.
  process = { imports ? [], packages ? [] }:
    let others = fold (a: b: load a // b) {} imports; in
    others // pkgSet packages;

  # Turn a list of packages into a set.
  pkgSet = packages:
    fold (a: b: {"${a.name}" = a;} // b) {} packages;

  allPkgs =
    (import ../pkgs/default.nix {inherit pkgs;}) //
      pkgs;

  load = file:
    process (import file {pkgs = allPkgs;});
}
