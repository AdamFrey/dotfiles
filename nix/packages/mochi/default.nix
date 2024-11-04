{ lib, appimageTools, fetchurl, asar }: let
  pname = "mochi";
  version = "1.17.15";

  src = fetchurl {
    url = "https://mochi.cards/releases/Mochi-${version}.AppImage";
    hash = "sha256-ZuoeeQ7SusRhr5BXBYEWCZ9pjdcWClKoR0mnom1XkPg=";
  };

  appimageContents = (appimageTools.extract { inherit pname version src; }).overrideAttrs (oA: {
    buildCommand = ''
      ${oA.buildCommand}

      # Get rid of the autoupdater
      ${asar}/bin/asar extract $out/resources/app.asar app
      sed -i 's/async isUpdateAvailable.*/async isUpdateAvailable(updateInfo) { return false;/g' app/node_modules/electron-updater/out/AppUpdater.js
      ${asar}/bin/asar pack app $out/resources/app.asar
    '';
  });

in appimageTools.wrapAppImage {
  inherit pname version;
  src = appimageContents;

  extraPkgs = pkgs: [ pkgs.hidapi ];

  extraInstallCommands = ''
    # Add desktop convencience stuff
    install -Dm444 ${appimageContents}/mochi.desktop -t $out/share/applications
    install -Dm444 ${appimageContents}/mochi.png -t $out/share/pixmaps
    substituteInPlace $out/share/applications/mochi.desktop \
      --replace 'Exec=AppRun' "Exec=$out/bin/${pname} --"
  '';

  meta = with lib; {
    homepage = "https://mochi.cards";
    description = "Official Mochi electron app";
    platforms = [ "x86_64-linux" ];
    license = licenses.unfree;
    mainProgram = "mochi";
  };
}
