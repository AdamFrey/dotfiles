{ lib
, fetchurl
, buildFHSEnv
, stdenv
}:

let
  pname = "pants";
  version = "0.12.5";

  src = fetchurl {
    url = "https://github.com/pantsbuild/scie-pants/releases/download/v${version}/scie-pants-linux-x86_64";
    hash = "sha256-XJ0mwsbndaKp3cwWgLOEmx4Jq0ryS1WwYruIWNETi8U=";
  };

  pants-unwrapped = stdenv.mkDerivation {
    pname = "${pname}-unwrapped";
    inherit version;

    dontUnpack = true;
    dontPatchELF = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 ${src} $out/bin/pants
      runHook postInstall
    '';
  };

in buildFHSEnv {
  name = "pants";
  targetPkgs = pkgs: with pkgs; [
    # Core requirements for the Python that scie-pants downloads
    stdenv.cc.cc.lib
    zlib
    # SSL/TLS certificates
    cacert
    # Common build dependencies
    gcc
    glibc
    bash
    coreutils
  ];
  extraBwrapArgs = [
    "--setenv" "SSL_CERT_FILE" "/etc/ssl/certs/ca-bundle.crt"
  ];
  runScript = "${pants-unwrapped}/bin/pants";

  meta = with lib; {
    description = "The Pants build system launcher (scie-pants)";
    homepage = "https://www.pantsbuild.org";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "pants";
  };
}
