let pkgs   = import <nixpkgs> {};
in (pkgs.callPackage ../../lib/ruby { }) {

  ##############################################################################
  name  = "cltc-phoenix";
  ruby  = pkgs.ruby_2_1;
  mysql = pkgs.mysql;

  ##############################################################################
  # Load some additional Nix helper files:
  extras = [ "mysql" "nokogiri" ];

  ##############################################################################
  # Extra packages:
  buildInputs = with pkgs; [
    inetutils # For hostname(1)
  ];

  ##############################################################################
  # Extra shell commands to run:
  shellHook = ''
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
}
