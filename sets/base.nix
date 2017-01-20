{ pkgs, ... }:

{
  # Packages needed on any system, including servers, workstations,
  # laptops, VMs, etc.
  packages = with pkgs; [
    # Emacs, my best friend.  But it's better without GTK. (The Emacs
    # daemon works better without GTK, that is.)
    (emacs.override {withX = true; withGTK2 = false; withGTK3 = false;})
    gnutls # Needed by various Emacs packages.

    # I still have a lot of scripts that require Ruby.
    ruby_2_2

    tmux duplicity gnupg inotifyTools libxml2 libxslt
    rsync unison zip unzip tree bc pwgen

  ];
}
