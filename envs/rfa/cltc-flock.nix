let
  pkgs   = import <nixpkgs> {};
  stdenv = pkgs.stdenv;
  ruby   = pkgs.ruby_2_2;
  mysql  = pkgs.mysql55;
  v8     = pkgs.v8_3_16_14;
in rec {
  cltc-flock = stdenv.mkDerivation rec {
    name = "cltc-flock";
    version = "0.0";
    src = ./.;

    buildInputs = with pkgs; [
      ruby
      bundler
      git
      libxml2
      libxslt
      libffi
      pkgconfig
      openssl
      mysql
      inetutils /* for hostname(1) */
      v8 # Needed by therubyracer gem.
    ];

    shellHook = ''
      RBV=`ruby -e "puts RUBY_VERSION.split('.')[0..1].join('.')"`
      export BUNDLE=$HOME/.gem/ruby/$RBV.0/bin/bundle
      export PATH=`dirname $BUNDLE`:$PATH

      if [ ! -x $BUNDLE ]; then
        gem install --user-install bundler
      fi

      if [ ! -r .bundle/config ]; then
        # This is causing Bundler to generate a `.bundle/config` file
        # with too many quotes.  https://github.com/bundler/bundler/issues/3053
        # That's even with the newest version too. :(
        $BUNDLE config --local build.nokogiri \
          --use-system-libraries \
          --with-xml2-lib=${pkgs.libxml2}/lib \
          --with-xml2-include=${pkgs.libxml2}/include/libxml2 \
          --with-xslt-lib=${pkgs.libxslt}/lib \
          --with-xslt-include=${pkgs.libxslt}/include > /dev/null

        $BUNDLE config --local build.mysql2  \
          --with-zlib=${pkgs.zlib}          \
          --with-mysql-include=${mysql}/include/mysql \
          --with-mysql-lib=${mysql}/lib > /dev/null

        $BUNDLE config --local build.libv8 \
          --with-system-v8
      fi

      # Need correct paths for building some C extensions (mysql).
      export LD_FLAGS="-L${pkgs.openssl}/lib"

      # Now that we have all that, let's install some gems.
      $BUNDLE install --path vendor/bundle
    '';
  };
}
