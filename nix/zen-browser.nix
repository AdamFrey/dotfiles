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
      };
    };

    # Policies for browser configuration
    policies = {
      # Disable automatic updates (managed by Nix)
      DisableAppUpdate = true;

      # Privacy settings
      DisableTelemetry = true;
      DisablePocket = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };

      # Bookmarks (can be managed declaratively)
      ManagedBookmarks = [
        {
          toplevel_name = "Managed Bookmarks";
        }
        {
          name = "NixOS";
          children = [
            { name = "NixOS Manual"; url = "https://nixos.org/manual/nixos/stable/"; }
            { name = "Nixpkgs"; url = "https://search.nixos.org/packages"; }
            { name = "Home Manager"; url = "https://nix-community.github.io/home-manager/"; }
          ];
        }
      ];
    };

    # Native messaging hosts (if needed for extensions)
    nativeMessagingHosts = with pkgs; [
      # firefoxpwa  # Progressive Web Apps
      # tridactyl-native  # For Tridactyl vim extension
    ];
  };
}
