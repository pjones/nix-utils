{
  allowUnfree = true;

  # Where to get binaries from:
  extra-binary-caches = [
    http://hydra.nixos.org
    http://hydra.cryp.to
  ];

  chromium = {
    enablePepperFlash = true;
    enablePepperPDF   = true;
    icedtea           = true;
  };

  firefox = {
    icedtea          = true;
    enableAdobeFlash = true;
  };
}
