{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  # Tell stylix which zen-browser profile to theme
  stylix.targets.zen-browser.profileNames = [ "Adams Profile" ];

  programs.zen-browser = {
    enable = true;

    # Declare the profile so it appears in profiles.ini / ProfileManager
    profiles."Adams Profile" = {
      id = 0;
      isDefault = true;
      # Path matches the existing profile directory name
      path = "Adams Profile";

      settings = {
        "browser.tabs.warnOnClose" = false;
        "browser.ctrlTab.sortByRecentlyUsed" = true;
        "browser.startup.homepage" = "about:home";
        "browser.toolbars.bookmarks.visibility" = "never";
        "devtools.toolbox.host" = "right";
        "browser.search.openintab" = true;
        "browser.download.useDownloadDir" = true;
        "browser.download.dir" = "/home/adam/inbox";
        "privacy.donottrackheader.enabled" = true;
        "browser.tabs.unloadOnLowMemory" = true;

        # Allow locally built browser extensions to install.
        "xpinstall.signatures.required" = false;
      };
    };

    # Policies for browser configuration.
    # Shared with configuration.nix, which installs the same set at
    # /etc/zen/policies/policies.json -- the only copy Zen actually reads.
    policies = import ./zen-policies.nix;

    # Native messaging hosts (if needed for extensions)
    nativeMessagingHosts = with pkgs; [
      # firefoxpwa  # Progressive Web Apps
      # tridactyl-native  # For Tridactyl vim extension
    ];
  };
}
