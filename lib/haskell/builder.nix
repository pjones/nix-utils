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
    cabal new-build
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
