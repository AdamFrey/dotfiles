# Zen enterprise policies, shared by two module systems.
#
# The home-manager module writes these into the wrapper package's
# distribution/ directory -- which Zen never reads, because the wrapper
# symlinks its lib dir through to the unwrapped package and Gecko resolves
# XREAppDist to the unwrapped path, whose distribution/policies.json is empty.
#
# So configuration.nix also installs them at /etc/zen/policies/policies.json.
# EnterprisePoliciesParent checks SysConfD ("/etc/" + MOZ_APP_NAME, and Zen's
# MOZ_APP_NAME is "zen") *before* the app directory, so that copy is the one
# that takes effect.
#
# Defined here rather than in either module so the two cannot drift apart.
{
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
        "*://www.tmz.com"
      ];
    };

    # Force-install uBlock Origin (no manual extension install needed)
    ExtensionSettings = {
      "uBlock0@raymondhill.net" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        allowed_in_private_browsing = true;
      };

      # web-pause, built locally by `bb pause:package` in the polyrepo.
      # ExtensionSettings takes URLs rather than paths, hence file://.
      # Rebuild the artifact after changing the extension; the filename is
      # pinned so this URL stays valid across version bumps.
      "web-pause@adamfrey.me" = {
        installation_mode = "force_installed";
        install_url = "file:///home/adam/src/polyrepo/projects/web-pause/web-ext-artifacts/web-pause.zip";
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

    # Sites that pause behind a typing gate, rather than being blocked
    # outright by WebsiteFilter above.
    #
    # An entry is a host, optionally followed by a path prefix. A bare host
    # covers its subdomains too, so scryfall.com also matches www.scryfall.com.
    # Adding a path narrows the match to part of a site -- google.com/search
    # would pause searching while leaving mail.google.com alone.
    "3rdparty".Extensions."web-pause@adamfrey.me" = {
      patterns = [
        "scryfall.com"
        "cubecobra.com"
        "mtg.wiki"
        "pitchfork.com"
        "luckypaper.co"
        "nba.com"
        "espn.com"
        "yahoo.com"
        "nytimes.com"
        "hipstersofthecoast.com"
        "google.com/search"
      ];
      prompts = [
        "Romans 5:17 For if, because of one man's trespass, death reigned through that one man, much more will those who receive the abundance of grace and the free gift of righteousness reign in life through the one man Jesus Christ."
        "2 Corinthians 10:17-18 Let the one who boasts, boast in the Lord. For it is not the one who commends himself who is approved, but the one whom the Lord commends."
      ];
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
}
