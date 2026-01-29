{ config, pkgs, lib, envVars, inputs, ... }:

{
  imports = [
    ./zen-browser.nix
  ];

  home = {
    username = "adam";
    homeDirectory = "/home/adam";
    stateVersion = "24.05";

    packages = with pkgs; [
      antares
      fd
      forge-mtg
      mozart2-binary
      nodePackages.prettier
      pavucontrol
      ripgrep
      wbg
      #music
      orca-c
      vital
    ];

    sessionPath = [
      "/home/adam/.local/bin"
    ];

    sessionVariables = envVars // {
      UV_PYTHON_DOWNLOADS = "never";
    };

    shellAliases = {
      ls     = "ls -1 --color";
      duct   = "clojure -M:duct";
    };

    file = {
      ".local/bin" = {
        source = ./sources/scripts;
        recursive = true;
      };

      ".config/clojure/deps.edn" = {
        source = ./sources/clojure/deps.edn;
        force = true;
      };

      ".config/beets/config.yaml".source = ./sources/beets/config.yaml;
      ".config/containers/config.json".source = ./sources/docker/config.json;
      ".config/docker/config.json".source = ./sources/docker/config.json;
      ".config/doom/init.el".source = ./sources/doom/init.el;
      ".config/doom/config.el".source = ./sources/doom/config.el;
      ".config/doom/packages.el".source = ./sources/doom/packages.el;
      ".config/emacs/.local/cache/.mc-lists.el".source = ./sources/emacs/mc-lists.el;
      # ".config/kitty/kitty.conf".source = ./sources/kitty.conf; # Now managed by stylix
      ".config/niri/config.kdl".source = ./sources/niri.kdl;
      ".lein/profiles.clj".source = ./sources/lein/profiles.clj;
      ".zen/Adams Profile/zen-keyboard-shortcuts.json" = {
        source = ./sources/zen/zen-keyboard-shortcuts.json;
        force = true;
      };
      ".zprintrc".source = ./sources/zprint/.zprintrc;
      ".claude/settings.json".source = ./sources/claude/settings.json;
    } // lib.optionalAttrs (envVars ? KITTY_STARTUP_DIR) {
      ".config/kitty/startup.session".text = ''
        cd ${envVars.KITTY_STARTUP_DIR}
      '';
    };
  };

  programs.home-manager.enable = true;

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  
  services.batsignal.enable = true; # battery life notifier
  services.flameshot.enable = true;

  # RAM usage monitor - notifies at 90% usage
  systemd.user.services.ram-monitor = {
    Unit.Description = "RAM usage monitor";
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "ram-monitor" ''
        threshold=90
        usage=$(${pkgs.procps}/bin/free | ${pkgs.gawk}/bin/awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
        if [ "$usage" -ge "$threshold" ]; then
          ${pkgs.libnotify}/bin/notify-send -u critical "High RAM Usage" "RAM usage is at ''${usage}%"
        fi
      '';
    };
  };

  systemd.user.timers.ram-monitor = {
    Unit.Description = "Check RAM usage every 30 seconds";
    Timer = {
      OnBootSec = "1min";
      OnUnitActiveSec = "30s";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Adam Frey";
        email = "adam@adamfrey.me";
      };
      pull = { rebase = true; };
      alias = {
        co = "checkout";
        b  = "branch";
        l  = "!git log --oneline | head";
      };
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = (inputs.private-nix.sshHosts or {}) // {
      "*" = {
        addKeysToAgent = "yes";
      };
    };
  };

  services.ssh-agent.enable = true;

  programs.tealdeer.enable = true;

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  #environment.pathsToLink = [ "/share/zsh" ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    defaultKeymap = "emacs";
    dotDir = "${config.xdg.configHome}/zsh";
    history = {
      path = "${config.xdg.dataHome}/zsh/zsh_history";
      save = 10000000;
      size = 10000000;
      expireDuplicatesFirst = true;
    };
    # babashka tab completion
    initContent = ''
    _bb_tasks() {
      local matches=(`bb tasks |tail -n +3 |cut -f1 -d ' '`)
      compadd -a matches
      _files # autocomplete filenames as well
    }
    compdef _bb_tasks bb
  '';
  };

  stylix.targets.niri.enable = false;
  stylix.targets.kitty.enable = true;

  programs.kitty = {
    enable = true;
    settings = {
      enable_audio_bell = false;
      confirm_os_window_close = 0;
      window_padding_width = 15;
      # Stylix will override the colors, but we can set other preferences
    } // lib.optionalAttrs (envVars ? KITTY_STARTUP_DIR) {
      startup_session = "${config.xdg.configHome}/kitty/startup.session";
    };
    keybindings = {
      "ctrl+plus" = "change_font_size all +2.0";
      "ctrl+minus" = "change_font_size all -2.0";
      "ctrl+backspace" = "change_font_size all 0";
    };
  };

  xdg.desktopEntries.antares = {
    name = "Antares";
    exec = "antares --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=WaylandWindowDecorations";
    icon = "antares";
  };

  xdg.desktopEntries.todoist-wayland = {
    name = "Todoist Wayland";
    exec = "todoist-electron --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=WaylandWindowDecorations";
    icon = "todoist";
    mimeType = ["x-scheme-handler/todoist"
                "x-scheme-handler/com.todoist"];
  };

  xdg.desktopEntries.slack = {
    name = "Slack";
    exec = "slack --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland";
    icon = "slack";
    mimeType = ["x-scheme-handler/slack"
                "x-scheme-handler/com.slack"];
    categories = ["Network" "InstantMessaging"];
  };

}
