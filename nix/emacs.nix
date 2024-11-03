{ config, lib, pkgs, ... }:

{
  systemd.user.services.emacs = {
    description                 = "Emacs: the extensible, self-documenting text editor";
    enable                      = true;
    after                       = ["graphical-session.target"];
    wantedBy                    = ["default.target"];

    serviceConfig               = {
      Type      = "forking";
      # Running Emacs this way ensures environment variable are accessible:
      ExecStart = "${pkgs.bash}/bin/bash -c 'source ${config.system.build.setEnvironment}; exec ${pkgs.emacs29-pgtk}/bin/emacs --daemon'";
      ExecStop  = "${pkgs.emacs29-pgtk}/bin/emacsclient --eval (kill-emacs)";
      Restart   = "always";

    };

    environment = {
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
