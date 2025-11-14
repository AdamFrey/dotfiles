{ lib
, stdenv
, fetchurl
, appimageTools
, makeWrapper
, electron
, xorg
, mesa
}:

let
  pname = "fastmail";
  version = "1.0.4";

  src = fetchurl {
    url = "https://dl.fastmailcdn.com/desktop/production/linux/x64/Fastmail-${version}.AppImage";
    hash = "sha512-lavGgtrIRiYL4NQEecpppvcTLZCgp54sTDFyVgySzBZmB6bcwCk9Kpjgepjma6iCUtUQYkN5ydtEYLZqTcSw4Q==";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };

in stdenv.mkDerivation {
  inherit pname version;

  src = appimageContents;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [
    xorg.libX11
    xorg.libXtst
    mesa
  ];

  installPhase = ''
    runHook preInstall

    # Create directory structure
    mkdir -p $out/bin
    mkdir -p $out/share/applications
    mkdir -p $out/share/icons/hicolor/{16x16,24x24,32x32,48x48,64x64,128x128,256x256,512x512}/apps
    mkdir -p $out/opt/fastmail

    # Copy AppImage contents
    cp -r $src/* $out/opt/fastmail/

    # Install icons
    for size in 16 24 32 48 64 128 256 512; do
      if [ -f "$src/usr/share/icons/hicolor/''${size}x''${size}/apps/fastmail.png" ]; then
        cp "$src/usr/share/icons/hicolor/''${size}x''${size}/apps/fastmail.png" \
           "$out/share/icons/hicolor/''${size}x''${size}/apps/com.fastmail.Fastmail.png"
      fi
    done

    # Create desktop file
    cat > $out/share/applications/com.fastmail.Fastmail.desktop <<EOF
[Desktop Entry]
Name=Fastmail
Exec=$out/bin/fastmail %U
Terminal=false
Type=Application
Icon=com.fastmail.Fastmail
StartupWMClass=Fastmail
Comment=Fastmail Desktop Client
MimeType=x-scheme-handler/fastmail;
Categories=Network;Email;
EOF

    # Install wrapper script
    substitute ${./fastmail-wrapper.sh} $out/bin/fastmail \
      --subst-var-by electron ${electron} \
      --subst-var-by out $out
    chmod +x $out/bin/fastmail

    runHook postInstall
  '';

  meta = with lib; {
    description = "Fastmail Desktop Client";
    homepage = "https://www.fastmail.com";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
    mainProgram = "fastmail";
  };
}
