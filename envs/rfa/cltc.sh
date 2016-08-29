#!/bin/sh -eu

dir=`pwd`
name=`basename $dir`
exec nix-shell ~/.nixpkgs/envs/rfa/${name}.nix
