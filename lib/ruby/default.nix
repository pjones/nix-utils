{ stdenv, pkgs, ... }:

with stdenv.lib;

{ ruby         ? pkgs.ruby_2_2
, mysql        ? pkgs.mysql
, v8           ? pkgs.v8_3_16_14
, buildInputs  ? []
, shellHook    ? ""
, bundleConfig ? ""
, extras       ? [ ]
, ...
}@args:

let helpers = map (extra: pkgs.callPackage "${./.}/${extra}.nix" { }) extras;
in stdenv.mkDerivation (args // {
  name = "some-ruby-app";
  version = "0.0";
  src = ./.;

  buildInputs = with pkgs; [
    ruby
    bundler
    git
    zlib
    openssl
  ] ++ buildInputs ++ (concatMap (h: h.buildInputs or []) helpers);

  shellHook = ''
    RUBY=${ruby}/bin/ruby
    RBV=`$RUBY -e "puts RUBY_VERSION.split('.')[0..1].join('.')"`

    export BUNDLE=$HOME/.gem/ruby/$RBV.0/bin/bundle
    export PATH=`dirname $BUNDLE`:$PATH

    if [ ! -x $BUNDLE ]; then
      ${ruby}/bin/gem install --user-install bundler
    fi

    # Bundler has a long standing bug of fucking up the generation of its config file.
    rm -rf .bundle/config
    ( echo "--"
      echo "BUNDLE_PATH: vendor/bundle"
      echo "BUNDLE_DISABLE_SHARED_GEMS: '1'"
      echo ${bundleConfig}                  
      ${concatMapStrings (h: concatStrings ["echo " (h.bundleConfig or "") "\n"]) helpers}
    ) > .bundle/config

    # Need correct LD_FLAGS for building some C extensions (mysql).
    export LD_FLAGS="-L${pkgs.openssl}/lib"

    # Now that we have all that, let's install some gems.
    $BUNDLE install --path vendor/bundle

    ${shellHook}
    ${concatMapStrings (h: h.shellHook or "") helpers}
  '';
})
