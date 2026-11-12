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
# The site blocks, uBlock filters and web-pause settings come from
# browser-blocking.nix, which Chrome shares.
let
  blocking = import ./browser-blocking.nix;
in
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

    WebsiteFilter.Block = blocking.zenWebsiteFilterBlock;

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
        userFilters = blocking.ublockUserFilters;
      };
    };

    "3rdparty".Extensions."web-pause@adamfrey.me" = blocking.webPause;

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
