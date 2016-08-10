let
  pkgs   = import <nixpkgs> {};
  stdenv = pkgs.stdenv;
  ruby   = pkgs.ruby_2_1;
  mysql  = pkgs.mysql55;
in rec {
  cltc-phoenix = stdenv.mkDerivation rec {
    name = "cltc-phoenix";
    version = "0.0";
    src = ./.;

    buildInputs = with pkgs; [
      # See above for ruby version.
      ruby
      bundler

      # See above for MySQL version and vendor.
      mysql

      git
      libxml2
      libxslt
      libffi
      pkgconfig
      openssl

      # For hostname(1)
      inetutils
    ];

    shellHook = ''
      # After a Nix garbage collection you might need to run:
      # rm -rf .bundle vendor/bundle

      RBV=`ruby -e "puts RUBY_VERSION.split('.')[0..1].join('.')"`
      export BUNDLE=$HOME/.gem/ruby/$RBV.0/bin/bundle
      export PATH=`dirname $BUNDLE`:$PATH

      if [ ! -x $BUNDLE ]; then
        gem install --user-install bundler
      fi

      if [ ! -r .bundle/config ]; then
        $BUNDLE config --local build.nokogiri                  \
          --use-system-libraries                              \
          --with-xml2-lib=${pkgs.libxml2}/lib                 \
          --with-xml2-include=${pkgs.libxml2}/include/libxml2 \
          --with-xslt-lib=${pkgs.libxslt}/lib                 \
          --with-xslt-include=${pkgs.libxslt}/include > /dev/null

        $BUNDLE config --local build.mysql     \
          --with-opt-dir=${mysql} \
          --with-mysql-include=${mysql}/include/mysql \
          --with-mysql-lib=${mysql}/lib \
          --with-mysqlclientlib=${mysql} \
          --with-mysql-dir=${mysql} > /dev/null
      fi

      $BUNDLE install --path vendor/bundle

      if [ ! -r config/database.yml ]; then
        grep -v password config/database.yml.sample > config/database.yml

        mysqladmin -u root -f drop cltc_phoenix_development
        mysqladmin -u root create  cltc_phoenix_development
        mysqladmin -u root -f drop cltc_phoenix_test
        mysqladmin -u root create  cltc_phoenix_test

        $BUNDLE exec rake db:schema:load
        $BUNDLE exec rake db:test:clone
        env RAILS_ENV=test $BUNDLE exec rake db:fixtures:load
      fi
    '';
  };
}
