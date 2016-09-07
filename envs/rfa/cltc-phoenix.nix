let pkgs = import <nixpkgs> {};
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

      mysqladmin -u root -f drop cltc_phoenix_development || true
      mysqladmin -u root create  cltc_phoenix_development

      mysqladmin -u root -f drop cltc_phoenix_test  || true
      mysqladmin -u root create  cltc_phoenix_test

      $BUNDLE exec rake db:schema:load  && \
        $BUNDLE exec rake db:test:clone && \
        $BUNDLE exec rake feathers:bootstrap
    fi
  '';
}
