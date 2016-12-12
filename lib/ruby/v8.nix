{ stdenv
, pkgs
, v8package ? pkgs.v8_3_16_14
, ...
}:

with stdenv.lib; {

  ##############################################################################
  # Extra packages:
  buildInputs = with pkgs; [
    v8package
  ];

  ##############################################################################
  # Extra calls to Bundler:
  bundleConfig = concatStringsSep " " [
    "BUNDLE_BUILD__LIBV8:"
    "--with-system-v8"
  ];
}
