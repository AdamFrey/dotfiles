{ config, pkgs, ... }:
{
  home = {
    username = "adam";
    homeDirectory = "/home/adam";
    stateVersion = "24.05";

    packages = with pkgs; [
      antares
      fd
      logseq
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

  services.emacs = {
    enable = true;
    defaultEditor = true;
  };

  services.flameshot.enable = true;

  programs.git = {
    enable = true;
    userName = "Adam Frey";
    userEmail = "adam@adamfrey.me";
    extraConfig = {
      pull = { rebase = true; };
    };
  };


  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.tealdeer.enable = true;

  programs.zsh = {
    enable = true;
  };


  stylix.targets.niri.enable = false;
}
