{ config, pkgs, lib, ... }:
{
    stylix = {
        base16Scheme = "${pkgs.base16-schemes}/share/themes/selenized-dark.yaml";
        image = config.lib.stylix.pixel "base0A";
        polarity = "dark";
        enable = true;
    };

    specialisation.day.configuration = {
      stylix = {
        base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/selenized-light.yaml";
        polarity = lib.mkForce "light";
      };
    };
}
