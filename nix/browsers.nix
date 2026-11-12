# Browser toggle configuration
# When disabled, removes Chrome and Zen browsers
# Only eww (Emacs Web Wowser) will remain available
# Browser data in ~/.config and ~/.cache is preserved when disabled

{ config, pkgs, lib, inputs, ... }:

with lib;

let
  cfg = config.services.browsersEnabled;
  blocking = import ./browser-blocking.nix;
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

    # Chrome/Chromium policies
    programs.chromium = mkIf cfg {
      enable = true;

      # uBlock Origin Lite.
      extensions = [ "ddkjiahejlhfcafbddmgiahcphecmpfh" ];

      extraOpts = {
        URLBlocklist = blocking.chromeUrlBlocklist;
        MetricsReportingEnabled = false;

        # web-pause, loaded unpacked from the polyrepo's dist/ directory.
        # The manifest key fixes this ID.
        "3rdparty".extensions.ndeglbjlglechmbeiffambpoocdbgfpo = blocking.webPause;
      };
    };

    # Zen's enterprise policies.
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
