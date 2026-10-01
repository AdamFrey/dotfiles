{
  inputs = {
    nixpkgs.url          = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url      = "github:numtide/flake-utils";

    agenix.url = "github:ryantm/agenix";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix/release-26.05";

    # Deliberately no `inputs.nixpkgs.follows`. This flake is only built and
    # cached against its own pinned nixpkgs; pointing it at ours changes every
    # output hash, so cache.numtide.com (see configuration.nix) would miss on
    # every rebuild and claude-code would be refetched locally each time.
    llm-agents.url = "github:numtide/llm-agents.nix";

    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    private-nix = {
      url = "git+ssh://git@github.com/AdamFrey/private-nix.git?ref=master";
    };
  };

    # outputs is a function taking inputs, and destructuring
  outputs =
    { self,
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
      home-manager,
      stylix,
      agenix,
      llm-agents,
      claude-desktop,
      zen-browser,
      private-nix
      }@inputs:
    let
      system = "x86_64-linux";

      # Our own Spotify app's PKCE client id, consumed by overlays/ncspot.nix.
      # Kept in the private-nix input rather than this public repo -- see that
      # overlay for why. null falls back to ncspot's shared upstream app.
      ncspotClientId =
        let
          clientIdFile = "${private-nix}/sources/ncspot/spotify-client-id";
        in
          if builtins.pathExists clientIdFile
          then builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile clientIdFile)
          else null;

      makeSystem = { extraModules, envVars }: nixpkgs.lib.nixosSystem {
        inherit system;
        # specialArgs is passed as an argument set to every module in the module list
        specialArgs = {
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              (import ./overlays/ncspot.nix { spotifyClientId = ncspotClientId; })
            ];
          };
          inherit inputs;
          inherit envVars;
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



          ({ pkgs, ... }: {
            # nixpkgs' programs.niri module (nixos/modules/programs/wayland/niri.nix)
            # replaces niri-flake: it registers the session, portals, and systemd
            # units, and defaults the package to pkgs.niri.
            programs.niri.enable = true;
            environment.variables.NIXOS_OZONE_WL = "1";

            # The one thing that module does not provide, and niri-flake did.
            # Without an agent, anything calling polkit from a niri session gets
            # no authentication dialog; GNOME's own agent runs only in a GNOME
            # session. Same binary and unit shape as niri-flake-polkit.service.
            systemd.user.services.niri-polkit-agent = {
              description = "PolicyKit authentication agent for the niri session";
              wantedBy = [ "niri.service" ];
              after = [ "graphical-session.target" ];
              partOf = [ "graphical-session.target" ];
              serviceConfig = {
                Type = "simple";
                ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
                Restart = "on-failure";
                RestartSec = 1;
                TimeoutStopSec = 10;
              };
            };
          })

          stylix.nixosModules.stylix
          ./style.nix

        ] ++ extraModules;
      };
    in  {
      nixosConfigurations = {
        desktop = makeSystem {
          extraModules = [
            ./desktop-hardware-configuration.nix
            ./desktop.nix
            ./podman.nix
          ];

          envVars = {
            EMACS_FONT_SIZE = 12;
          };
        };
        framework-laptop = makeSystem {
          extraModules = [
            ./machines/framework-laptop-hardware-configuration.nix
            ./machines/framework-laptop.nix
            ./podman.nix
            ./ardour.nix
            ./sqlite.nix
          ];
          envVars = {
            EMACS_FONT_SIZE = 14;
          };
        };
	      work-framework-laptop = makeSystem {
	        extraModules = [
	          ./machines/work-framework-laptop-hardware-configuration.nix
	          ./machines/work-framework-laptop.nix
	          ./docker.nix
	          ./btrfs-rh-data.nix
	          ./swap-capacity.nix
	          ./memory-floors.nix
	        ];
          envVars = {
            EMACS_FONT_SIZE = 14;
            KITTY_STARTUP_DIR = "~/rh";
          };
	      };
      };
    };
}
