{
  inputs = {
    nixpkgs.url          = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url      = "github:numtide/flake-utils";

    agenix.url = "github:ryantm/agenix";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix/release-25.05";

    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake/a7f42f42426130a51b0542a651a2cb29f99ac2b6";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

    # outputs is a function taking inputs, and destructuring
  outputs =
    { self,
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
      home-manager,
      niri,
      stylix,
      agenix,
      claude-desktop,
      zen-browser }@inputs:
    let
      system = "x86_64-linux";
      makeSystem = { extraModules, envVars }: nixpkgs.lib.nixosSystem {
        # specialArgs is passed as an argument set to every module in the module list
        specialArgs = {
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
          inherit inputs;
        };

        modules = [
          ./configuration.nix

          agenix.nixosModules.default # secrets
          # agenix.homeManagerModules.default

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.adam = import ./home.nix;
            home-manager.extraSpecialArgs = {
              inherit envVars;
              inherit inputs;
            };
            # sharedModules = [
            #   inputs.agenix.homeManagerModules.default
            # ];
          }



          niri.nixosModules.niri
          {
            programs.niri.enable = true;
            programs.niri.package = inputs.niri.packages.${system}.niri-unstable;
            environment.variables.NIXOS_OZONE_WL = "1";

          }

          stylix.nixosModules.stylix
          ./style.nix

        ] ++ extraModules;
      };
    in  {
      nixpkgs.overlays = [ niri.overlays.niri ];

      nixosConfigurations = {
        desktop = makeSystem {
          extraModules = [
            ./desktop-hardware-configuration.nix
            ./desktop.nix
          ];

          envVars = {
            EMACS_FONT_SIZE = 12;
          };
        };
        laptop = makeSystem {
          extraModules = [
            ./laptop-hardware-configuration.nix
            ./laptop.nix
          ];
          envVars = {
            EMACS_FONT_SIZE = 18;
          };
        };
        framework-laptop = makeSystem {
          extraModules = [
            ./framework-laptop-hardware-configuration.nix 
            ./framework-laptop.nix
          ];
          envVars = {
            EMACS_FONT_SIZE = 12;
          };
        };
      };
    };
}
