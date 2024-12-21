{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:danth/stylix/release-24.05";
  };

    # outputs is a function taking inputs, and destructuring
  outputs = { self, nixpkgs, home-manager, niri, stylix }@inputs:
    let
      makeSystem = extraModules: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };

        modules = [
          ./configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.adam = import ./home.nix;
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
        desktop = makeSystem [
          ./desktop-hardware-configuration.nix
          ./desktop.nix
        ];
        laptop  = makeSystem [
          ./laptop-hardware-configuration.nix
          ./laptop.nix
        ];
      };
    };
}
