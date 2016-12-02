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
  version = "0.2.0.0";

  src = fetchgit {
    url    = "git://pmade.com/clockdown";
    rev    = "18a51dfcba695df3ed0ac5661c1c57d759ed15d6";
    sha256 = "1fyjdihqj52d548abmm5k46kijxxsv8g8gv9l8nckzmn0drb8yq3";
  };
}
