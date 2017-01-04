{ pkgs, fetchgit, myHaskellBuilder }:

let haskpkgs = p: with p; [
      HStringTemplate
      HTTP
      MonadRandom
      QuickCheck
      X11
      X11-xft
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
  version = "0.2.0.0";

  # 7.10.3 doesn't work thanks to gtk2hs:
  ghc = pkgs.haskell.packages.ghc801;

  src = fetchgit {
    url    = "git://pmade.com/xmonadrc.git";
    rev    = "ad45904f4bffef5bbdb602244840937f4893a81f";
    sha256 = "09mg09bh0cb0pzssqyam7rq2f5c0xm7z306vmv17nbryc73qpx6k";
  };

  buildInputs = with pkgs; [
    gtk2 autoconf
  ];

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

  shellHook = ''
    eval $preConfigure
  '';
}
