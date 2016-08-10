let
  pkgs   = import <nixpkgs> {};
  stdenv = pkgs.stdenv;
  hsenv  = pkgs.haskellngPackages.ghcWithPackages (p: with p; [ purescript ]);
in rec {
  myenv = stdenv.mkDerivation rec {
    name = "purescript-dev";
    version = "0.0";
    src = ./.;

    buildInputs = with pkgs; [
      hsenv nodejs
    ];

    shellHook = ''
      if [ ! -d node_modules/pulp ]; then
        npm install pulp
      fi

      export PATH=node_modules/.bin:$PATH
    '';
  };
}
