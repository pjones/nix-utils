{ pkgs, ... }:

{
  # List of other files to include:
  imports = [
    ./base.nix
    ./development.nix
  ];

  # Packages for a full user experience on a laptop or workstation.
  packages = with pkgs; [
    # Security:
    pass

    # Terminals and core software:
    termite wmctrl

    # Internet Utilities:
    asynk
    chromium
    curl
    firefox
    skype
    tigervnc
    wget

    # Media Players/Viewers:
    beets
    feh
    ffmpeg
    moc
    mpc_cli
    mpd
    mpg123
    ncmpcpp
    vlc
    volumeicon
    zathura

    # Media Ripping, Burning, Scanning, Encoding, etc.:
    makemkv
    brotherDSSeries # My scanner driver
    cdrkit          # cdrecord, mkisofs, etc.
    grip
    handbrake
    lame
    youtube-dl

    # Media Editors:
    anki
    audacity
    gimp
    inkscape
    darktable
    imagemagick
    blender

    # Writing and Designing:
    aspell
    aspellDicts.en
    curaLulzbot
    dict
    edify
    gcolor2
    ghostscript
    graphviz
    gromit-mpx
    haskellPackages.pandoc-citeproc
    haskellPackages.pandoc-crossref
    impressive
    libreoffice
    mscgen
    pandoc
    pdftk
    slic3r
    texlive.combined.scheme-full
    xournal

    # Games:
    mednafen

    # System utilities
    gparted
    parted
    x11vnc
    ssvnc

    # Misc.
    clockdown
    dunst
    libnotify
    libossp_uuid
    tty-clock
    xorg.xmessage
  ];
}
