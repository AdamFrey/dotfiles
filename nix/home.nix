{ config, pkgs, ... }:
{
  home = {
    username = "adam";
    homeDirectory = "/home/adam";
    stateVersion = "24.05";

    packages = with pkgs; [
      antares
      devenv
      fd
      logseq
      nodePackages.prettier
      nyxt
      pavucontrol
      ripgrep
      slack

      #music
      orca-c
      vital
    ];

    sessionPath = [
      ".local/bin"
    ];

    shellAliases = {
      ls = "ls -1 --color";
    };

    file = {
      ".local/bin" = {
        source = ./sources/scripts;
        recursive = true;
      };

      ".config/niri/config.kdl".source = ./sources/niri.kdl;
      ".config/doom/init.el".source = ./sources/doom/init.el;
      ".config/doom/config.el".source = ./sources/doom/config.el;
      ".config/doom/packages.el".source = ./sources/doom/packages.el;
      ".config/kitty/kitty.conf".source = ./sources/kitty.conf;
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
  };

  stylix.targets.niri.enable = false;

  xdg.desktopEntries.antares = {
    name = "Antares";
    exec = "antares  --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=WaylandWindowDecorations";
  };
}
