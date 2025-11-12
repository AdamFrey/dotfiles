{ config, pkgs, lib, ... }:
{
    stylix = {
        base16Scheme = "${pkgs.base16-schemes}/share/themes/selenized-light.yaml";
        image = config.lib.stylix.pixel "base0A";
        polarity = "light";

        # image = "~/Downloads/aerial-forest-wallpaper.jpg";
        # image = pkgs.fetchurl {
        #   url = "https://images.unsplash.com/photo-1542919242-b32f2a7bce8d?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb";
        #   sha256 = "foobar";
        # };
        enable = true;
    };

    specialisation.day.configuration = {
      stylix = {
        polarity = lib.mkForce "light";
      };
    };
}
