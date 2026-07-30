{ config, lib, pkgs, envVars, ... }:

{
  systemd.user.services.emacs = {
    description                 = "Emacs: the extensible, self-documenting text editor";
    enable                      = true;
    after                       = ["graphical-session.target"];
    wantedBy                    = ["default.target"];

    serviceConfig               = {
      Type      = "forking";
      # Running Emacs this way ensures environment variable are accessible:
      ExecStart = "${pkgs.bash}/bin/bash -c 'source ${config.system.build.setEnvironment}; exec ${pkgs.emacs-pgtk}/bin/emacs --daemon'";
      ExecStop  = "${pkgs.emacs30-pgtk}/bin/emacsclient --eval (kill-emacs)";
      Restart   = "always";

    };

    environment = {
      # Consumed by sources/doom/config.el; set here so the daemon always has
      # it regardless of graphical-session env-import timing.
      EMACS_FONT_SIZE = toString envVars.EMACS_FONT_SIZE;

      # Cap every JVM the daemon launches — the CIDER REPLs above all. Measured
      # 2026-07-30: two uncapped REPLs reached 1448 and 2470 MiB RSS against an
      # ergonomic MaxHeapSize of 3.73 GiB each (25% of RAM), so an idle pair
      # could claim half the machine.
      JDK_JAVA_OPTIONS = lib.concatStringsSep " " [
        "-Xmx1536m"
        # Clojure's class churn grows metaspace without bound by default.
        "-XX:MaxMetaspaceSize=512m"
        # REPLs idle for long stretches; hand unused heap back to the OS every
        # five minutes instead of holding it as swap-eligible pages.
        "-XX:G1PeriodicGCInterval=300000"
      ];

      # Some variables for GTK applications I could launch from Emacs
      #GTK_DATA_PREFIX        = config.system.path;
      #GTK_PATH               = "${config.system.path}/lib/gtk-3.0:${config.system.path}/lib/gtk-2.0";
      #GDK_CORE_DEVICE_EVENTS = "1"; # https://github.com/stumpwm/stumpwm/wiki/FAQ#my-mouse-wheel-doesnt-work-with-gtk3-applications

      # # Aspell will find its dictionaries
      # ASPELL_CONF     = "dict-dir /home/adam/.nix-profile/lib/aspell";

      # Locate will find its database
      LOCATE_PATH     = "/var/cache/locatedb";

      # the last ':' is important for Emacs. See Emacs variable
      # `Info-directory-list'.
      INFOPATH        = "%h/.nix-profile/info:%h/.nix-profile/share/info:/nix/var/nix/profiles/default/info:/nix/var/nix/profiles/default/share/info:/run/current-system/sw/info:/run/current-system/sw/share/info:";

      TERMINFO_DIRS = "/run/current-system/sw/share/terminfo";

      # NIX environment
      NIX_CONF_DIR = "/etc/nix";
      NIX_OTHER_STORES = "/run/nix/remote-stores/*/nix";
      #NIX_PATH = "nixpkgs=%h/nixpkgs:nixos=%h/nixpkgs/nixos:nixos-config=/etc/nixos/configuration.nix";
      NIX_PROFILES = "${pkgs.lib.concatStringsSep " " config.environment.profiles}";
      NIX_REMOTE = "daemon";
      NIX_USER_PROFILE_DIR = "/nix/var/nix/profiles/per-user/%u";
    };
  };
}
