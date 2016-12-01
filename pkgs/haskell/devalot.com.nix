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
  version = "0.3.0.0";

  src = fetchgit {
    url    = "pmade.com:git/devalot/site.git";
    rev    = "";
    sha256 = "";
  };

  buildInputs = with pkgs; [
    sassc # For processing Sass.
  ];
  
  postInstall = ''
    export LANG=en_US.UTF-8
    $out/bin/devalot-frontend rebuild
    mv www $out/www
  '';
}
