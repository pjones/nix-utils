{ fetchgit, myHaskellBuilder }:

let haskpkgs = p: with p; [
      base
      containers
      filepath
      optparse-applicative
      pandoc
      pandoc-types
      parsec
      process
      tasty
      tasty-hunit
      text
      transformers
    ];
in myHaskellBuilder haskpkgs {
  name    = "edify";
  version = "0.2.0.0";

  src = fetchgit {
    url    = "git://pmade.com/edify";
    rev    = "76ef6846b152f113211754b64fa81b8f04ce874b";
    sha256 = "150r4wj28m5s6mmdvqvrxrnamy0qqs9pvwmrc2rcql3yhjqv329h";
  };
}
