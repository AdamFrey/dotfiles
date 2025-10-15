# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a NixOS flake-based configuration repository that manages system and user configurations for multiple machines (desktop, laptop, framework-laptop). It uses home-manager for user-level package management and configuration.

## System Architecture

### Flake Structure

The repository uses a modular flake design with `makeSystem` function that creates NixOS configurations:

- **flake.nix**: Main entry point defining inputs, system configurations, and the `makeSystem` function
- **configuration.nix**: Base system configuration imported by all machines
- **home.nix**: User-level configuration managed by home-manager
- Machine-specific files: `desktop.nix`, `laptop.nix`, `framework-laptop.nix` and their corresponding hardware configurations

### Module System

The configuration is split into specialized modules:
- **emacs.nix**: Emacs systemd service configuration (runs as daemon)
- **filesystem.nix**: NFS automounts for NAS at 192.168.0.221
- **podman.nix**: Container runtime with Docker compatibility
- **style.nix**: Stylix theme configuration with base16 color schemes
- **secrets/secrets.nix**: agenix-managed secrets (SSH keys at /home/adam/.ssh/id_ed25519)

### Special Arguments

The flake passes `specialArgs` to modules:
- `pkgs-unstable`: Unstable nixpkgs for bleeding-edge packages (Spotify, Zed editor)
- `inputs`: Direct access to flake inputs (claude-desktop, mcp-servers-nix, zen-browser)
- `envVars`: Machine-specific environment variables (e.g., EMACS_FONT_SIZE)

### Custom Packages

Custom packages are in `packages/` directory:
- **beads**: Custom package loaded in configuration.nix:8 via `callPackage`
- Each package has a `default.nix` following standard Nix package structure

## Common Commands

### System Operations

```sh
# Apply system configuration changes (use machine name: desktop, laptop, or framework-laptop)
sudo nixos-rebuild switch --flake .#desktop

# Update all flake inputs
nix flake update

# Build without activating
sudo nixos-rebuild build --flake .#laptop

# Test configuration without making it default boot option
sudo nixos-rebuild test --flake .#framework-laptop
```

### Development

```sh
# Enter a development environment (if using devenv)
devenv shell

# Check flake
nix flake check

# Show flake outputs
nix flake show
```

## Key Configuration Patterns

### Adding System Packages

Add to `environment.systemPackages` in configuration.nix:140. Use `pkgs-unstable` for packages from unstable channel:

```nix
environment.systemPackages = with pkgs; [
  # stable packages
  git
] ++ [
  # unstable packages
  pkgs-unstable.some-package
];
```

### Adding User Packages

Add to `home.packages` in home.nix:8.

### Machine-Specific Configuration

Each machine configuration is created via `makeSystem` in flake.nix with:
- `extraModules`: Hardware config and machine-specific settings
- `envVars`: Machine-specific environment variables passed to home-manager

### MCP Servers

MCP servers are configured in home.nix:193 using the mcp-servers-nix integration. The configuration is written to `~/.config/Claude/claude_desktop_config.json`. Current servers:
- filesystem: Uses npx workaround for @modelcontextprotocol/server-filesystem
- clojure-mcp: Custom Clojure MCP server via clojure CLI
- postgres: Python-based postgres-mcp via uv

### Secrets Management

Uses agenix with identity at /home/adam/.ssh/id_ed25519 (configuration.nix:12). Secrets are defined in secrets/secrets.nix.

## Important Notes

- The system uses Niri (Wayland compositor) as the window manager with GNOME as desktop environment
- Emacs runs as a systemd user service (daemon mode) and should be accessed via emacsclient
- Shell: zsh with direnv, starship, fzf, and zoxide integrations
- NAS mounts are automounted on access (x-systemd.automount)
- Git is configured to rebase on pull by default
- The system uses Stylix for unified theming across applications
