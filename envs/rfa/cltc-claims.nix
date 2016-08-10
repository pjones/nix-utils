let
  pkgs   = import <nixpkgs> {};
  stdenv = pkgs.stdenv;
  mysql  = pkgs.mysql55;
in rec {
  cltc-claims = stdenv.mkDerivation rec {
    name = "cltc-claims";
    version = "0.0";
    src = ./.;

    buildInputs = with pkgs; [
      ruby_2_2
      bundler
      git
      zlib
      openssl

      # See above `let' for MySQL version and vendor.
      mysql
    ];

    shellHook = ''
      RBV=`ruby -e "puts RUBY_VERSION.split('.')[0..1].join('.')"`
      export BUNDLE=$HOME/.gem/ruby/$RBV.0/bin/bundle
      export PATH=`dirname $BUNDLE`:$PATH

      if [ ! -x $BUNDLE ]; then
        gem install --user-install bundler
      fi

      if [ ! -r .bundle/config ]; then
        # Watch out, the .bundle/config file might have spurious
        # quotes in it due to a bug.  Right now you have to clean that
        # up by hand.
        $BUNDLE config --local build.mysql2  \
          --with-zlib=${pkgs.zlib}          \
          --with-mysql-include=${mysql}/include/mysql \
          --with-mysql-lib=${mysql}/lib > /dev/null
      fi

      # Need correct LD_FLAGS for building some C extensions (mysql).
      export LD_FLAGS="-L${pkgs.openssl}/lib"

      # Now that we have all that, let's install some gems.
      $BUNDLE install --path vendor/bundle
    '';
  };
}
