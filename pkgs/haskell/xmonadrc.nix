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
    url    = "git://git.devalot.com/xmonadrc.git";
    rev    = "584bbdfacf6d30fbee7d38dfd30c1de8f28382d0";
    sha256 = "1wvn93ghgskf8snjdry42imb2fiwfp1gvgv30rnn5rqlg980msi5";
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
