{ lib
, stdenv
, fetchurl
, autoPatchelfHook
}:

let
  pname = "pants";
  version = "0.12.5";

  src = fetchurl {
    url = "https://github.com/pantsbuild/scie-pants/releases/download/v${version}/scie-pants-linux-x86_64";
    hash = "sha256-XJ0mwsbndaKp3cwWgLOEmx4Jq0ryS1WwYruIWNETi8U=";
  };

in stdenv.mkDerivation {
  inherit pname version;

  dontUnpack = true;

  nativeBuildInputs = [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${src} $out/bin/pants
    runHook postInstall
  '';

  meta = with lib; {
    description = "The Pants build system launcher (scie-pants)";
    homepage = "https://www.pantsbuild.org";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "pants";
  };
}
