#!/bin/sh -eu

dir=`pwd`
name=`basename $dir`
exec nix-shell --pure ~/.nixpkgs/envs/rfa/${name}.nix
