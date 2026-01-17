{ config, lib, pkgs, ... }:

{
  # Enable tailscale service
  services.tailscale.enable = true;

  # Ensure the service starts on boot
  systemd.services.tailscaled = {
    wantedBy = [ "multi-user.target" ];
  };
}
