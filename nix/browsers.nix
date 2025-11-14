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
      BROWSER = "zen";  # or "google-chrome-stable" if you prefer
    };

    # Conditionally include browser packages
    environment.systemPackages = with pkgs;
      lib.optionals cfg [
        google-chrome
        inputs.zen-browser.packages.${pkgs.system}.default
      ];
  };
}