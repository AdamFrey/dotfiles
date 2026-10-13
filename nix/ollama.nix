{ pkgs, ... }:

# Local model inference on the RX 580.
#
# Vulkan, not ROCm: the card is Polaris (gfx803), which ROCm dropped years
# ago. Mesa's RADV drives it fine and llama.cpp's Vulkan backend sidesteps the
# problem entirely.
#
# 8 GiB VRAM is the ceiling, and the desktop session shares it -- comfortable
# for 7-8B at Q4, tight above that.

{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;

    # Reachable from the laptops over the tailnet, not from the LAN.
    host = "0.0.0.0";
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 11434 ];
}
