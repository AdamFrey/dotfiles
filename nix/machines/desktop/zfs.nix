{ ... }:

# ZFS policy for the machine that holds the consolidated data.
#
# Two single-disk pools, no redundancy right now: `rpool` on the NVMe carries
# the system, home, databases and immich; `pithos` on the 2 TB WD carries bulk
# media. The WD is drive-managed SMR, so anything with a random-write pattern
# stays off it.
#
# Mountpoints come from the hardware configuration generated at reinstall.
# This module holds only what is policy rather than layout.

{
  boot.supportedFilesystems = [ "zfs" ];

  # Refuse to import a pool another system still claims. Worth the manual step
  # on the rare occasion it triggers.
  boot.zfs.forceImportRoot = false;

  # Pools record this value as their owner. It must be stable across
  # reinstalls, or every import afterwards needs -f.
  networking.hostId = "8f3a1c7e";

  services.zfs = {
    autoScrub = {
      enable = true;
      interval = "monthly";
    };

    # Matters for the NVMe pool; inert on the spinning disk.
    trim.enable = true;
  };

  # Local snapshots. These are an undo button, not a backup -- they live on
  # the same disks as the data. The offsite copy is offsite-backup.nix.
  services.sanoid = {
    enable = true;

    templates = {
      # Things being actively edited, where losing an hour would hurt.
      working = {
        hourly = 24;
        daily = 14;
        monthly = 3;
        autosnap = true;
        autoprune = true;
      };

      # Write-once media.
      bulk = {
        hourly = 0;
        daily = 7;
        monthly = 2;
        autosnap = true;
        autoprune = true;
      };
    };

    datasets = {
      "rpool/home".use_template = [ "working" ];

      # Crash-consistent, not application-consistent: rolling back lands
      # postgres where a power cut would, which it recovers from on start.
      "rpool/var/lib/postgresql".use_template = [ "working" ];

      "rpool/var/lib/immich".use_template = [ "bulk" ];

      "pithos" = {
        use_template = [ "bulk" ];
        recursive = true;
      };
    };
  };
}
