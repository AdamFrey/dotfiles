{ config, lib, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # Add docker tools to system packages
  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  # Add user to docker group
  users.users.adam.extraGroups = [ "docker" ];
}
