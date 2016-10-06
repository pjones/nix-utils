let
  pkgs   = import <nixpkgs> {};
  stdenv = pkgs.stdenv;

in stdenv.mkDerivation {
  name = "Selenium-Environment";
  version = "0.0";
  src = ./.;

  # FIXME: for this to work you still need to have a symlink for
  # chromium in /bin (/bin/chromium-browser) otherwise chromedriver
  # can't start the browser.  The driver has hard-coded paths to the
  # browser that need to be patched still.
  buildInputs = with pkgs; [
    chromedriver
    chromium
    nodejs
    selenium-server-standalone
  ];

  shellHook = ''
    export PATH=node_modules/.bin:$PATH
  '';
}
