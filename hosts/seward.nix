# Packages to install for my laptop Seward.
(import ../lib {}).boot ({ pkgs, ... }: {
  # Other files to include:
  imports = [
    ../sets/desktop.nix
  ];

  # Host specific packages:
  packages = with pkgs; [
  ];
})
