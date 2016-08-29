{ stdenv, pkgs, mysql, ... }:

with stdenv.lib; {

  ##############################################################################
  # Extra packages:
  buildInputs = [ mysql ];

  ##############################################################################
  # Extra calls to Bundler:
  bundleConfig = concatStringsSep " " [
    "BUNDLE_BUILD__MYSQL2:"
    "--with-zlib=${pkgs.zlib}"
    "--with-mysql-config=${mysql.lib}/bin/mysql_config"
  ];
}
