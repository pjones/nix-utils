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
  version = "17.2.27.0";

  # 7.10.3 doesn't work thanks to gtk2hs:
  ghc = pkgs.haskell.packages.ghc801;

  src = fetchgit {
    url    = "git://git.devalot.com/xmonadrc.git";
    rev    = "b489c36a733661a3102c73baed81ccd64ff75574";
    sha256 = "1falgzcjcf02x81dna0z957cimky6fijk3ay7zz3gi6vfm2bn9z9";
  };

  buildInputs = (with pkgs; [
    gtk2 autoconf
  ]) ++ (with pkgs.xorg; [
    libX11 libXext libXft libXinerama libXrandr libXrender
  ]);

  preConfigure = ''
    ( test -d vendor/x11 && cd vendor/x11 && autoreconf -f )
  '';

  postInstall = ''
    # Install taffybar configuration:
    mkdir -p $out/share/taffybar
    cp etc/taffybar.gtk $out/share/taffybar/taffybar.rc
  '';
}
