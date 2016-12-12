#!/bin/sh -eu

################################################################################
usage () {
  cat <<EOF
Usage: cltc.sh [options] [name]

  -r      Reset everything (binaries, database, etc.)
EOF
}

################################################################################
# Options:
reset=NO

################################################################################
while getopts "r" o; do
  case "${o}" in
    r) reset=YES
       ;;

    h) usage
       exit
       ;;

    *) usage
       exit 1
       ;;
  esac
done

shift $((OPTIND-1))

################################################################################
if [ $# -eq 1 ]; then
  name=$1
else
  dir=`pwd`
  name=`basename $dir`
fi

################################################################################
if [ "$reset" = YES ]; then
  rm -rf ~/.gem vendor/bundle config/database.yml
fi

################################################################################
echo "loading environment for $name..."
exec nix-shell --pure ~/.nixpkgs/envs/rfa/${name}.nix
