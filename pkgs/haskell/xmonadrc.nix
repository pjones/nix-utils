{ pkgs, fetchgit, myHaskellBuilder }:

let haskpkgs = p: with p; [
      HStringTemplate
      HTTP
      MonadRandom
      QuickCheck
      attoparsec
      base
      bytestring
      cairo
      containers
      data-default
      dbus
      directory
      doctest
      dyre
      either
      enclosed-exceptions
      exceptions
      extensible-exceptions
      filepath
      gtk
      gtk-traymanager
      hostname
      hspec
      http-client
      libmpd
      mtl
      network
      network-uri
      old-locale
      old-time
      optparse-applicative
      parsec
      process
      random
      safe
      setlocale
      split
      stm
      text
      time
      time-locale-compat
      transformers
      unix
      utf8-string
      word8
      xdg-basedir
    ];
in myHaskellBuilder haskpkgs {
  name    = "xmonadrc";
  version = "0.2.1.0";

  # 7.10.3 doesn't work thanks to gtk2hs:
  ghc = pkgs.haskell.packages.ghc801;

  src = fetchgit {
    url    = "git://git.devalot.com/xmonadrc.git";
    rev    = "db17cfab3baf689db492787d04433069afec1dc0";
    sha256 = "1267lf93k83w33zq837df21qz6g3mbvjrf6ir2a870as4z82xfsh";
  };

  buildInputs = (with pkgs; [
    gtk2 autoconf
  ]) ++ (with pkgs.xorg; [
    libX11 libXext libXft libXinerama libXrandr libXrender
  ]);

  preConfigure = ''
    ( cd vendor/x11 && autoreconf -f )
  '';

  postInstall = ''
    # Install taffybar configuration:
    mkdir -p $out/share/taffybar
    cp etc/taffybar.gtk $out/share/taffybar/taffybar.rc

    # For backwards compatibility:
    cp $out/bin/xmonadrc $out/bin/xmonad
  '';
}
