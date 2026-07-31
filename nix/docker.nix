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

  # MemoryHigh throttles reclaim rather than killing. MemoryMax would
  # OOM-kill them mid-transaction. MemorySwapMax bounds the swap that a memory
  # ceiling alone would create, since Docker grants an equal swap allowance by
  # default.
  #
  # Sized from 2026-07-31 measurements under docker + two CIDER REPLs + a test
  # suite. The two ceilings were originally 4G/3G, which proved mis-proportioned:
  #
  #   memory.current  1615 MiB of 4096   (60% of the ceiling unused)
  #   memory.swap     3070 MiB of 3072   (pinned at the ceiling for 14/14 samples)
  #
  # Containers voluntarily shed resident pages to ~1615 MiB and then wanted more
  # swap than they were allowed, so the deficit is swap, not memory. MemoryHigh
  # stays at 4G because that is sized for the `compose up` burst, which peaked at
  # 4092 MiB; lowering it would add startup throttling and push more traffic into
  # swap, and swap-in is already the dominant latency cost at ~13 MiB/s.
  #
  # 5G of container swap costs roughly 1.4 GiB of real RAM at the measured 3.7x
  # zram compression ratio, so the true footprint of this pair is ~5.5 GiB.
  systemd.slices.docker.sliceConfig = {
    MemoryHigh = "4G";
    MemorySwapMax = "5G";
  };

  # Add docker tools to system packages
  environment.systemPackages = with pkgs; [
    docker-compose
    oxker
  ];

  # Add user to docker group
  users.users.adam.extraGroups = [ "docker" ];
}
