{ config, pkgs, ... }:
{
  home = {
    username = "adam";
    homeDirectory = "/home/adam";
    stateVersion = "24.05";

    packages = with pkgs; [
      ripgrep
      fd
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
    };
    

  };

  programs.home-manager.enable = true;
        programs.git = {
       enable = true;
        userName = "Adam Frey";
        userEmail = "adam@adamfrey.me";
        extraConfig = {
          pull = { rebase = true; };
        };
     };

  stylix = {
    image = "~/Downloads/aerial-forest-wallpaper.jpg";
    # image = pkgs.fetchurl {
    #   url = "https://images.unsplash.com/photo-1542919242-b32f2a7bce8d?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb";
    #   sha256 = "foobar";
    # };
    enable = false;
  };
}
