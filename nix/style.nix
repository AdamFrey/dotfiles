{ config, pkgs, lib, ... }:
{
    stylix = {
        base16Scheme = "${pkgs.base16-schemes}/share/themes/selenized-light.yaml";
        image = config.lib.stylix.pixel "base0A";
        polarity = "light";
        enable = true;
    };

    specialisation.night.configuration = {
      stylix = {
        base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/selenized-dark.yaml";
        polarity = lib.mkForce "dark";
      };
    };
}
