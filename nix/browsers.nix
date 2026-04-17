# Browser toggle configuration
# When disabled, removes Chrome and Zen browsers
# Only eww (Emacs Web Wowser) will remain available
# Browser data in ~/.config and ~/.cache is preserved when disabled

{ config, pkgs, lib, inputs, ... }:

with lib;

let
  cfg = config.services.browsersEnabled;
in
{
  options.services.browsersEnabled = mkOption {
    type = types.bool;
    default = true;
    description = ''
      Enable web browsers (Chrome, Zen).
      When disabled, only eww (Emacs Web Wowser) will be available.
      Browser data and configuration files are preserved.
    '';
  };

  config = {
    # Conditionally set BROWSER environment variable
    environment.sessionVariables = mkIf cfg {
      BROWSER = "zen-beta";
    };

    # Chrome/Chromium policies (applies to Google Chrome too)
    programs.chromium = mkIf cfg {
      enable = true;
      extraOpts = {
        URLBlocklist = [
          "images.google.com"
          "google.com/search*tbm=isch*"
          "google.com/search*udm=2*"
          "google.com/imghp*"
          "lens.google.com"
          "google.com/search*udm=39*"
          "www.tiktok.com"
          "tiktok.com"
          "x.com"
          "twitter.com"
          "reddit.com"
          "youtube.com"
        ];
      };
    };

    # Conditionally include browser packages
    # Zen browser is installed via home-manager module in zen-browser.nix
    environment.systemPackages = with pkgs;
      lib.optionals cfg [
        google-chrome
      ];
  };
}
