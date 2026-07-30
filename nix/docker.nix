{ config, lib, pkgs, ... }:

{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;

    # Park every container under one slice so the ceiling below reaches all of
    # them — including the ones started with `docker run` rather than compose,
    # which carry no compose labels and so cannot be capped from a compose file.
    daemon.settings.cgroup-parent = "docker.slice";
  };

  # Measured 2026-07-30: nine containers held 2245 MiB resident plus 3754 MiB
  # swapped, with no limit of any kind. MemoryHigh throttles reclaim rather than
  # killing. MemoryMax would OOM-kill them mid-transaction.
  # MemorySwapMax caps the swap leak that a memory ceiling alone would create,
  # since Docker grants an equal swap allowance by default.
  systemd.slices.docker.sliceConfig = {
    MemoryHigh = "4G";
    MemorySwapMax = "3G";
  };

  # Add docker tools to system packages
  environment.systemPackages = with pkgs; [
    docker-compose
    oxker
  ];

  # Add user to docker group
  users.users.adam.extraGroups = [ "docker" ];
}
