{ lib
, stdenv
, fetchurl
, makeWrapper
, jdk21_headless
}:

let
  pname = "noumenon";
  version = "0.5.5";

  noum-bin = fetchurl {
    url = "https://github.com/leifericf/noumenon/releases/download/v${version}/noum-linux-x86_64";
    hash = "sha256-j667A8ifH/mXMojqz6Hzv5INeE5caWJlbX5g6Uwkutc=";
  };

  jar = fetchurl {
    url = "https://github.com/leifericf/noumenon/releases/download/v${version}/noumenon-${version}.jar";
    hash = "sha256-hqs4nqkNEG6uAu+T8oSGlnFmo25SfrvHOUR5L3kLK+M=";
  };

  jre = jdk21_headless;

in stdenv.mkDerivation {
  inherit pname version;

  dontUnpack = true;
  dontStrip = true;
  dontPatchELF = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib $out/share/noumenon

    # Install the native CLI launcher (statically linked Babashka/GraalVM binary)
    install -Dm755 ${noum-bin} $out/lib/noum

    # Install the JVM backend uber-jar
    cp ${jar} $out/share/noumenon/noumenon.jar

    # Wrapper script that pre-seeds ~/.noumenon/ with Nix-managed JRE and JAR
    # so the launcher never downloads anything at runtime.
    cat > $out/bin/noum <<'WRAPPER'
    #!/usr/bin/env bash
    set -euo pipefail

    NOUM_DIR="$HOME/.noumenon"
    JRE_DIR="$NOUM_DIR/jre"
    LIB_DIR="$NOUM_DIR/lib"
    JAR_PATH="$LIB_DIR/noumenon.jar"

    mkdir -p "$NOUM_DIR" "$LIB_DIR"

    # Symlink Nix-managed JRE if not already present or pointing elsewhere
    if [ ! -e "$JRE_DIR" ] || [ "$(readlink -f "$JRE_DIR")" != "@jre@" ]; then
      rm -rf "$JRE_DIR"
      ln -sfn "@jre@" "$JRE_DIR"
    fi

    # Symlink Nix-managed JAR if not already present or pointing elsewhere
    if [ ! -e "$JAR_PATH" ] || [ "$(readlink -f "$JAR_PATH")" != "@jar@" ]; then
      rm -f "$JAR_PATH"
      ln -sfn "@jar@" "$JAR_PATH"
    fi

    exec "@noum@" "$@"
    WRAPPER

    substituteInPlace $out/bin/noum \
      --replace-warn "@jre@" "${jre}" \
      --replace-warn "@jar@" "$out/share/noumenon/noumenon.jar" \
      --replace-warn "@noum@" "$out/lib/noum"
    chmod +x $out/bin/noum

    # Direct server wrapper bypassing the launcher entirely
    makeWrapper ${jre}/bin/java $out/bin/noumenon-server \
      --add-flags "-jar $out/share/noumenon/noumenon.jar"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Knowledge graph platform that compiles Git repos into a queryable database for AI agents";
    homepage = "https://github.com/leifericf/noumenon";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "noum";
  };
}
