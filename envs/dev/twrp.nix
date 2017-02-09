# This derivation is based on the following guides (and help from #twrp):
#
#   http://wiki.lineageos.org/oneplus3_build.html
#   https://forum.xda-developers.com/showthread.php?t=1943625
#
# More information:
#
#   https://github.com/omnirom/android_bootable_recovery
#
# To do:
#
#   * Add roomserviceLines to .repo/local_manifests/roomservice.xml
#   * Continue fixing wacky shit.
#   * https://gerrit.omnirom.org/#/c/21661/

let
  pkgs       = import <nixpkgs> {};
  stdenv     = pkgs.stdenv;
  fetchgit   = pkgs.fetchgit;

  repo       = "git://github.com/omnirom/android.git";
  branch     = "android-7.1";

  # NOTE: Change this to match your Device Code:
  deviceCode = "oneplus3";

  # NOTE: These are extra `repo' source that you need that contain
  # binary blobs for your device.  You'll need to track down which
  # repositories you actually need.
  #
  # https://github.com/TheMuppets
  roomserviceLines = ''
    <project name="TheMuppets/proprietary_vendor_oneplus" path="vendor/oneplus"/>
    <project name="TheMuppets/proprietary_vendor_qcom_binaries" path="vendor/qcom/binaries"/>
  '';

in stdenv.mkDerivation {
  name    = "twrp";
  version = "3.0.4";

  src = fetchgit {
    url    = repo;
    rev    = "2d2281b4ebc3c3a8718d8d233a14d39ce5a3f815";
    sha256 = "1q7vimjf7dwkwbzd3n8r6wlh6f14g6srh5z24yg1ywpn1mlgrpdp";
  };

  buildInputs = with pkgs; [
    gitRepo # the repo tool
    gnupg   # wanted by the repo tool
    python  # need for building
  ];

  postUnpack = ''
    [ -n "$out" -a -d "$out" ] && cd "$out"
    repo init -u ${repo} -b ${branch}
    repo sync

    # Fix stupid absolute paths all over the place:
    for f in `find . -type f -name '*.sh' -o -name Makefile -o -name '*.mk'`; do
      sed -i.orig -e 's|/bin/bash|${pkgs.bash}/bin/bash|g' \
                  -e 's|/bin/||g' \
                   "$f"
    done

    source build/envsetup.sh
    breakfast ${deviceCode}
  '';

  shellHook = ''
    if [ -r default.xml ]; then
      eval "$postUnpack"
    fi
  '';
}
