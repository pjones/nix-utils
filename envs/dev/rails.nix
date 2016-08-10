let
  pkgs   = import <nixpkgs> {};
  stdenv = pkgs.stdenv;
in rec {
  railsdev = stdenv.mkDerivation rec {
    name = "railsdev";
    version = "0.0";
    src = ./.;

    buildInputs = with pkgs; [
      ruby_2_1 bundler git sqlite zlib
      libxml2 libxslt libffi pkgconfig
    ];

    shellHook = ''
      if [ -d vendor ]; then
        mkdir -p vendor/gemhome
        GEM_HOME=$PWD/vendor/gemhome
      else
        GEM_HOME=$PWD/gems
      fi
    '';

  };
}
