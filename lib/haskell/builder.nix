# Based on: pkgs/development/haskell-modules/generic-stack-builder.nix
{ stdenv, haskell, pkgconfig, glibcLocales, findutils, coreutils
, forceLocalSource ? false # Override for building from PWD.
, extraBuildInputs ? [ ]   # Override for building from PWD with extra tools.
}:

with stdenv.lib;

haskpkgs:
{ name
, version
, ghc              ? haskell.packages.ghc7103
, buildInputs      ? []
, LD_LIBRARY_PATH  ? []
, ...
}@args:

################################################################################
let find  = "${findutils}/bin/find";
    mkdir = "${coreutils}/bin/mkdir";

    # Default Haskell packages that are needed:
    defhaskpkgs = (p: with p; [ Cabal cabal-install hlint ]);
    allhaskpkgs = ghc.ghcWithPackages (p: (defhaskpkgs p) ++ (haskpkgs p));

    # Make cabal-install happy:
    setHome = ''
      if [ ! -w "$HOME" ]; then
        export HOME=$TMPDIR/home
        mkdir -p $HOME
      fi
    '';

################################################################################
in stdenv.mkDerivation (args // {

  ##############################################################################
  name = "${name}-${version}";

  ##############################################################################
  # Don't let the `ghc' argument to this file leak into the derivation:
  ghc = ghc.ghc.name; # (Turn the ghc function into a string.)

  ##############################################################################
  src = if forceLocalSource
        then builtins.getEnv "PWD"
        else args.src;

  ##############################################################################
  # Workaround for https://ghc.haskell.org/trac/ghc/ticket/11042:
  LD_LIBRARY_PATH = makeLibraryPath (LD_LIBRARY_PATH ++ buildInputs);

  ##############################################################################
  buildInputs = buildInputs ++ [ allhaskpkgs pkgconfig ] ++
    optional stdenv.isLinux glibcLocales ++ extraBuildInputs;

  ##############################################################################
  configurePhase = ''
    ${setHome}
    runHook preConfigure

    cabal new-configure     \
      --enable-optimization \
      --enable-executable-stripping

    runHook postConfigure
  '';

  ##############################################################################
  buildPhase = ''
    ${setHome}
    runHook preBuild

    # There's a bug in cabal which is why I am using `--jobs=1' below.
    # https://github.com/haskell/cabal/issues/3460
    # https://github.com/haskell/cabal/pull/3509
    if [ `cabal --version|head -1|cut -d' ' -f3|cut -d. -f1,2` = "1.24" ]; then
      cabal new-build --jobs=1
    else
      cabal new-build
    fi

    runHook postBuild
  '';

  ##############################################################################
  installPhase = ''
    ${setHome}
    runHook preInstall

    ${mkdir} -p $out/bin

    # Copy any executable files:
    ${find} dist-newstyle/build/${name}-${version}/ \
      -type f -executable \
      '(' -not -name '*.so' -and -not -name '*.a' -and -not -name test ')' \
      -exec cp -p '{}' $out/bin/ ';'

    runHook postInstall
  '';
})
