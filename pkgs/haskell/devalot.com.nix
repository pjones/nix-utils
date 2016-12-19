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
    url    = "ssh://dracula.pmade.com/git/devalot/site.git";
    rev    = "92863903350bbac2909b23aebd938673c34200d5";
    sha256 = "0bwa2q8pm4383z83ap1ld3aw56qp8mppxf58nlclf095c4f6iyjg";
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
