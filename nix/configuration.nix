# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, pkgs-unstable, inputs, ... }:

{
  # secret decryption
  age.identityPaths = [ "/home/adam/.ssh/id_ed25519" ];
  #age.secrets.ssh-config-entries.file = secrets/ssh-config-entries.age;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports =
    [ ./filesystem.nix
      ./emacs.nix
      ./podman.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [ "mem_sleep_default=deep" ];

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  environment.sessionVariables = {
    GDK_BACKEND        = "wayland";
    NIXOS_OZONE_WL     = "1";
    MOX_ENABLE_WAYLAND = "1";
    XDG_CACHE_HOME     = "$HOME/.cache";
    XDG_CONFIG_HOME    = "$HOME/.config";
    XDG_DATA_HOME      = "$HOME/.local/share";
    XDG_STATE_HOME     = "$HOME/.local/state";
    BROWSER            = "firefox";
    EDITOR             = "emacsclient --create frame";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };


  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.adam = {
    isNormalUser = true;
    description = "Adam Frey";
    extraGroups = [ "networkmanager" "wheel" "podman" ];
    packages = with pkgs; [
       beeper
       beets
       bitwarden
       #deltachat-desktop
       git
       httpie
       lagrange
       pgcli
       psst
       todoist-electron
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.permittedInsecurePackages = [
    "electron-27.3.11" # used by logseq
    "emacs-pgtk-29.4"
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search nixpkgs wget
  environment.systemPackages = with pkgs; [
    bash
    bluetui
    calibre
    clojure
    cljfmt
    direnv
    duckdb
    emote
    fuzzel
    glxinfo
    gnumake
    google-chrome
    google-cloud-sdk
    graphviz
    gpt4all
    htop
    ispell
    just
    kitty
    leiningen
    libnotify
    impala
    mako # notifications
    nodejs_22
    ollama
    pandoc
    pciutils
    postgresql
    pulsemixer
    python3
    rclone
    rlwrap
    unzip
    uv
    waybar
    zeal
    zenith
    zip
    zoxide
    #inputs.claude-desktop.packages.${system}.claude-desktop-with-fhs
    inputs.zen-browser.packages.${pkgs.system}.default
  ] ++ [
    pkgs-unstable.emacs-pgtk
    pkgs-unstable.spotify
    pkgs-unstable.zed-editor
  ]
  ;

  # install fonts
  fonts.packages = with pkgs; [
    jetbrains-mono
    dejavu_fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.dejavu-sans-mono
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;

  programs.fish.enable = true;
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # udev rules for keyboardio
  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="2301", SYMLINK+="Model01",  ENV{ID_MM_DEVICE_IGNORE}="1", ENV{ID_MM_CANDIDATE}="0", TAG+="uaccess", TAG+="seat"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="2300", SYMLINK+="Model01",  ENV{ID_MM_DEVICE_IGNORE}="1", ENV{ID_MM_CANDIDATE}="0", TAG+="uaccess", TAG+="seat"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="3496", ATTRS{idProduct}=="0006", SYMLINK+="Model100",  ENV{ID_MM_DEVICE_IGNORE}="1", ENV{ID_MM_CANDIDATE}="0", TAG+="uaccess", TAG+="seat"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="3496", ATTRS{idProduct}=="0005", SYMLINK+="Model100",  ENV{ID_MM_DEVICE_IGNORE}="1", ENV{ID_MM_CANDIDATE}="0", TAG+="uaccess", TAG+="seat"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="2303", SYMLINK+="Atreus",  ENV{ID_MM_DEVICE_IGNORE}="1", ENV{ID_MM_CANDIDATE}="0", TAG+="uaccess", TAG+="seat"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="2302", SYMLINK+="Atreus",  ENV{ID_MM_DEVICE_IGNORE}="1", ENV{ID_MM_CANDIDATE}="0", TAG+="uaccess", TAG+="seat"
  '';

  nix.extraOptions = ''
        trusted-users = root adam
        extra-substituters = https://devenv.cachix.org
        extra-trusted-public-keys = devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
