{ pkgs, fetchgit, myHaskellBuilder }:

let haskpkgs = p:
    # This hack is because the Heist package is missing a test
    # dependency on pandoc and so the tests fail.
    let goodheist = pkgs.haskell.lib.dontCheck p.heist;
        goodsnap  = p.snap.override { heist = goodheist; };
    in with p; [
      goodsnap # See above.

      aeson
      base
      blaze-builder
      bytestring
      containers
      directory
      errors
      filepath
      hakyll
      hjsmin
      hspec
      lens
      mime-mail
      mtl
      optparse-applicative
      pandoc
      pandoc-types
      parsec
      process
      snap-core
      snap-server
      tasty
      tasty-hunit
      text
      time
      transformers
      yaml
    ];
in myHaskellBuilder haskpkgs {
  name    = "devalot";
  version = "0.4.0.0";

  src = fetchgit {
    url    = "file:///home/pjones/backup/moriarty/git/devalot/site.git";
    rev    = "4e3185a20a8478cc878be362ef997c15b70f75c2";
    sha256 = "1hlbfhil7hlny3a4gvhldrmhj7lf02di6lz3p1cin61ijb22xvlb";
  };

  # Needed to build the site.
  LANG = "en_US.UTF-8";

  # Extra packages.
  buildInputs = with pkgs; [
    sassc  # For processing Sass.
    nodejs # For auto-prefixer (postcss).
  ];

  # Build the site from source after building.
  postInstall = ''
    $out/bin/devalot-frontend rebuild
    mv www $out/www
  '';
}
