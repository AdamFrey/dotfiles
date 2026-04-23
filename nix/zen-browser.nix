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

      # Block Google Images while allowing regular search
      WebsiteFilter = {
        Block = [
          "*://images.google.com/*"
          "*://www.google.com/search*tbm=isch*"
          "*://www.google.*/search*tbm=isch*"
          "*://www.google.com/search*udm=2*"
          "*://www.google.*/search*udm=2*"
          "*://www.google.com/imghp*"
          "*://www.google.*/imghp*"
          "*://lens.google.com/*"
          "*://www.google.com/search*udm=39*"
          "*://www.google.*/search*udm=39*"
          "*://www.tiktok.com/*"
          "*://tiktok.com/*"
          "*://x.com/*"
          "*://www.x.com/*"
          "*://twitter.com/*"
          "*://www.twitter.com/*"
          "*://www.reddit.com/*"
          "*://reddit.com/*"
          "*://old.reddit.com/*"
          "*://www.youtube.com/*"
          "*://youtube.com/*"
          "*://m.youtube.com/*"
          "*://www.facebook.com/reel/*"
          "*://www.facebook.com/reels/*"
        ];
      };

      # Force-install uBlock Origin (no manual extension install needed)
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          allowed_in_private_browsing = true;
        };
      };

      # Configure uBlock Origin with custom cosmetic filters
      "3rdparty".Extensions."uBlock0@raymondhill.net" = {
        toAdd = {
          userFilters = [
            "! Hide Google Image previews in search results"
            "www.google.com##[data-attrid^=\"VisualDigest\"]"
            "! Hide Short videos section from Google search"
            "www.google.com##.MjjYud:has(span:has-text(/^Short videos$/))"
            "! Hide What people are saying section from Google search"
            "www.google.com##.MjjYud:has(span:has-text(/^What people are saying$/))"
            "! Hide Images preview carousel from Google search"
            "www.google.com##div:has(> div > div[data-iu] span[role=\"heading\"]:has-text(/^Images$/))"
            "! Hide Facebook Reels link"
            "facebook.com##a[href*=\"/reel\"]"
            "! Hide YouTube comments"
            "youtube.com##ytd-comments"
          ];
        };
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
