{ pkgs, ... }:

let myHaskellBuilder = pkgs.callPackage ../../lib/haskell/builder.nix { };
    callHaskellPackage = (path: with pkgs; callPackage path { inherit myHaskellBuilder; });
in
{
  clockdown =  callHaskellPackage ./clockdown.nix;
  devalot-www = callHaskellPackage ./devalot.com.nix;
  edify =  callHaskellPackage ./edify.nix;
  xmonadrc =  callHaskellPackage ./xmonadrc.nix;
}
