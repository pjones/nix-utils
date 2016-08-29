{ stdenv, pkgs, v8, ... }:

with stdenv.lib; {

  ##############################################################################
  # Extra packages:
  buildInputs = [ v8 ];

  ##############################################################################
  # Extra calls to Bundler:
  bundleConfig = concatStringsSep " " [
    "BUNDLE_BUILD__LIBV8:"
    "--with-system-v8"
  ];
}
