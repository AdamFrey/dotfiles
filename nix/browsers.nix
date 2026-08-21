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

    # Zen's enterprise policies. This is the copy that actually takes effect.
    #
    # Gecko checks SysConfD ("/etc/" + MOZ_APP_NAME, and Zen's MOZ_APP_NAME is
    # "zen") before the app directory. The home-manager module writes the same
    # set into the wrapper package's distribution/ dir, but Gecko resolves
    # XREAppDist through the wrapper's symlinks to the unwrapped package, whose
    # distribution/policies.json is an empty {"policies":{}} -- which is why
    # about:policies reported the service inactive until this file existed.
    #
    environment.etc."zen/policies/policies.json" = mkIf cfg {
      text = builtins.toJSON { policies = import ./zen-policies.nix; };
    };

    # Conditionally include browser packages
    # Zen browser is installed via home-manager module in zen-browser.nix
    environment.systemPackages = with pkgs;
      lib.optionals cfg [
        google-chrome
      ];
  };
}
