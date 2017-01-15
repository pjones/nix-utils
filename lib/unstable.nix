let unstable = "/home/pjones/.nix-defexpr/custom/nixpkgs";
    pkgs     = import unstable {};
in (import ./default.nix { inherit pkgs; }).localPkgs
