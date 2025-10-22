{ config, pkgs, envVars, inputs, ... }:

let
  mcpConfig = inputs.mcp-servers-nix.lib.mkConfig pkgs {
    # Configure built-in modules
    programs = {
      # Cannot find package 'zod-to-json-schema'
      # filesystem = {
      #   enable = true;
      #   args = [ "/home/adam/src/dotfiles" ];
      # };
      fetch.enable = true;
    };

    # Add custom MCP servers
    settings.servers = {
      # Use npx version of filesystem server as a workaround
      filesystem = {
        command = "${pkgs.lib.getExe' pkgs.nodejs "npx"}";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/home/adam/src/dotfiles"
        ];
      };
      beads = {
        command = "uv";
        args = [
          "run"
          "--with"
          "beads-mcp"
          "beads-mcp"
        ];
      };
      clojure-mcp = {
        command = "/bin/sh";
        args = [
          "-c"
          "cd /home/adam && clojure -Sdeps '{:deps {org.slf4j/slf4j-nop {:mvn/version \"2.0.16\"} com.bhauman/clojure-mcp {:git/url \"https://github.com/bhauman/clojure-mcp.git\" :git/tag \"v0.1.10-alpha\" :git/sha \"8bd96c3\"}}}' -A:mcp -X clojure-mcp.main/start-mcp-server :port 7888"
        ];
      };
      postgres = {
        command = "uv";
        args = [
          "run"
          "--with"
          "postgres-mcp"
          "postgres-mcp"
          "--access-mode=unrestricted"
        ];
        env = {
          DATABASE_URI = "postgresql://app:app@localhost:5432/cljcollage_dev";
        };
      };
    };
  };
in
{
  home = {
    username = "adam";
    homeDirectory = "/home/adam";
    stateVersion = "24.05";

    packages = with pkgs; [
      antares
      babashka
      devenv
      fd
      logseq
      mozart2-binary
      nodePackages.prettier
      pavucontrol
      ripgrep
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
      claude = "~/.claude/local/claude";
      duct   = "clojure -M:duct";
      # mkdir -p ~/.claude/local
      # ln -s ~/.local/share/claude/node_modules/@anthropic-ai/claude-code/cli.js ~/.claude/local/claude

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
      ".config/kitty/kitty.conf".source = ./sources/kitty.conf;
      ".config/niri/config.kdl".source = ./sources/niri.kdl;
      ".lein/profiles.clj".source = ./sources/lein/profiles.clj;
    };
  };

  programs.home-manager.enable = true;

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  services.flameshot.enable = true;

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    userName = "Adam Frey";
    userEmail = "adam@adamfrey.me";
    extraConfig = {
      pull = { rebase = true; };
    };
    aliases = {
      co = "checkout";
      b  = "branch";
      l  = "!git log --oneline | head";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    matchBlocks = inputs.private-nix.sshHosts or {};
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
    dotDir = ".config/zsh";
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

  xdg.desktopEntries.slack-wayland = {
    name = "Slack Wayland";
    exec = "slack --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=WaylandWindowDecorations";
    icon = "slack";
    mimeType = ["x-scheme-handler/slack"
                "x-scheme-handler/com.slack"];
  };

  # MCP Servers configuration
  xdg.configFile."Claude/claude_desktop_config.json".source = mcpConfig;
}
