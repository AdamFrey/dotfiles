{
  inputs = {
    agenix.url = "github:ryantm/agenix";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:danth/stylix/release-24.11";

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

    # outputs is a function taking inputs, and destructuring
  outputs = { self, nixpkgs, home-manager, niri, stylix, agenix, zen-browser }@inputs:
    let
      makeSystem = { extraModules, envVars }: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        # specialArgs is passed as an argument set to every module in the module list
        specialArgs = {
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
          }

          niri.nixosModules.niri
          {
            programs.niri.enable = true;
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
      };
    };
}
