{ pkgs, ... }:

with pkgs;
{
  brotherDSSeries = callPackage ./drivers/brother-dsseries.nix { };
}
