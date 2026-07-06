{ config, lib, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # The RH dev compose network (fixed bridge name rh-dev0) may reach the
  # host-run api service's RPC port; all other container->host traffic
  # stays blocked by the default firewall.
  networking.firewall.interfaces."rh-dev0".allowedTCPPorts = [ 8082 ];

  # Add docker tools to system packages
  environment.systemPackages = with pkgs; [
    docker-compose
    oxker
  ];

  # Add user to docker group
  users.users.adam.extraGroups = [ "docker" ];
}
