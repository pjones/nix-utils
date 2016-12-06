#!/bin/sh -eu

if [ $# -eq 1 ]; then
  name=$1
else
  dir=`pwd`
  name=`basename $dir`
fi

exec nix-shell --pure ~/.nixpkgs/envs/rfa/${name}.nix
