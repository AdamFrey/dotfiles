{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.zen-browser.homeModules.default
  ];

  programs.zen-browser = {
    enable = true;
    
    # Policies for browser configuration
    policies = {
      # Disable automatic updates (managed by Nix)
      DisableAppUpdate = true;
      
      # Privacy settings
      DisableTelemetry = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      
      # Browser preferences including keyboard shortcuts
      Preferences = {
        # Tab management shortcuts
        "browser.tabs.warnOnClose" = {
          Value = false;
          Status = "default";
        };
        
        # Custom keyboard shortcuts
        # Note: Firefox/Zen uses different pref names for shortcuts
        # Common shortcuts can be configured here
        "browser.ctrlTab.sortByRecentlyUsed" = {
          Value = true;
          Status = "default";
        };
        
        # Enable custom keyboard shortcuts extension API
        "extensions.shortcuts.enabled" = {
          Value = true;
          Status = "default";
        };
        
        # Example: Set homepage
        "browser.startup.homepage" = {
          Value = "about:home";
          Status = "default";
        };
        
        # Hide bookmark toolbar
        "browser.toolbars.bookmarks.visibility" = {
          Value = "never";
          Status = "default";
        };
        
        # Developer tools shortcuts
        "devtools.toolbox.host" = {
          Value = "right";
          Status = "default";
        };
        
        # Search shortcuts
        "browser.search.openintab" = {
          Value = true;
          Status = "default";
        };
        
        # Downloads
        "browser.download.useDownloadDir" = {
          Value = true;
          Status = "default";
        };
        "browser.download.dir" = {
          Value = "/home/adam/inbox";
          Status = "default";
        };
        
        # Privacy
        "privacy.donottrackheader.enabled" = {
          Value = true;
          Status = "default";
        };
        
        # Performance
        "browser.tabs.unloadOnLowMemory" = {
          Value = true;
          Status = "default";
        };
        
        # Navigation keyboard shortcuts
        # Alt+B for back, Alt+F for forward
        "browser.backspace_action" = {
          Value = 2;  # Disable backspace navigation
          Status = "default";
        };
        
        # Custom key bindings via ui.key
        "ui.key.accelKey" = {
          Value = 18;  # Alt key
          Status = "default";
        };
        "ui.key.menuAccessKey" = {
          Value = 0;  # Disable menu access key to free up Alt
          Status = "default";
        };
      };
      
      # Extension settings (add your favorite extensions here)
      ExtensionSettings = {
        # Example: uBlock Origin
        # "uBlock0@raymondhill.net" = {
        #   install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        #   installation_mode = "force_installed";
        # };
        
        # Example: Vimium (for vim-like keyboard navigation)
        # "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
        #   install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
        #   installation_mode = "normal_installed";
        # };
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