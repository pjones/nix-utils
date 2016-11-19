{ fetchgit, myHaskellBuilder }:

let haskpkgs = p: with p; [
      async
      base
      byline
      colour
      containers
      mtl
      tasty
      tasty-hunit
      text
      time
      transformers
      vty
    ];
in myHaskellBuilder haskpkgs {
  name    = "clockdown";
  version = "0.1.0.0";

  src = fetchgit {
    url    = "git://pmade.com/clockdown";
    rev    = "9f7e77a9923d35ab0d751db912711c53405cd4d9";
    sha256 = "0vniv04v34xn49bbrp4c2xfwmhbsj25w3iywxf56i1jks6y2k93n";
  };
}
