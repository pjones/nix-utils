{ stdenv, pkgs, ... }:

with stdenv.lib; {

  ##############################################################################
  # Extra packages:
  buildInputs = with pkgs; [
    libxml2
    libxslt
    libffi
    pkgconfig
  ];

  ##############################################################################
  # Extra calls to Bundler:
  bundleConfig = concatStringsSep " " [
    "BUNDLE_BUILD__NOKOGIRI:"
    "--use-system-libraries"
    "--with-xml2-lib=${pkgs.libxml2}/lib"
    "--with-xml2-include=${pkgs.libxml2}/include/libxml2"
    "--with-xslt-lib=${pkgs.libxslt}/lib"
    "--with-xslt-include=${pkgs.libxslt}/include"
  ];
}
