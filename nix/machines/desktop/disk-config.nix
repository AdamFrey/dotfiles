# Disk layout for matte-black-cadillac, consumed by disko.
#
# NOT imported by default.nix. Importing it declares fileSystems that conflict
# with the ext4 layout the machine currently runs on, and disko will happily
# erase both disks. It is switched on only for the reinstall -- see reinstall.md.
#
# Two single-disk pools, no redundancy by choice:
#
#   rpool   NVMe, 2 TB   system, home, databases, immich, service state
#   pithos  WD, 2 TB     bulk media only
#
# The split is not stylistic. The WD is drive-managed SMR, whose write
# amplification makes it a poor host for anything with a random-write pattern.
#
# Dataset names here are load-bearing. zfs.nix snapshots rpool/home,
# rpool/var/lib/postgresql and rpool/var/lib/immich by name, and selfhosted.nix
# binds to /pithos/art, /var/lib/immich and /var/lib/linkwarden. Rename one and
# sanoid errors on every run while services start against missing paths.
#
# Device paths must be set from `ls -l /dev/disk/by-id/` on the target before
# this is used. by-id, never sda -- kernel names are not stable across boots.
{
  disko.devices = {
    disk = {
      nvme = {
        type = "disk";
        device = "/dev/disk/by-id/REPLACE-ME-nvme-Lexar_SSD_NM790_2TB";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };

      hdd = {
        type = "disk";
        device = "/dev/disk/by-id/REPLACE-ME-ata-WDC_WD20EZAZ";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "pithos";
              };
            };
          };
        };
      };
    };

    zpool = {
      rpool = {
        type = "zpool";

        # ashift=12: both disks report 4096-byte physical sectors.
        options.ashift = "12";

        # xattr=sa and acltype=posixacl are not optional -- systemd and
        # journald need them, and setting them later does not fix files
        # already written.
        rootFsOptions = {
          compression = "zstd";
          atime = "off";
          xattr = "sa";
          acltype = "posixacl";
          mountpoint = "none";
        };

        datasets = {
          root = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy";
          };
          nix = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options.mountpoint = "legacy";
          };
          home = {
            type = "zfs_fs";
            mountpoint = "/home";
            options.mountpoint = "legacy";
          };

          # Containers only, so that var/lib/* can be separate datasets.
          var = {
            type = "zfs_fs";
            options = { mountpoint = "none"; canmount = "off"; };
          };
          "var/lib" = {
            type = "zfs_fs";
            options = { mountpoint = "none"; canmount = "off"; };
          };

          "var/lib/postgresql" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/postgresql";
            options.mountpoint = "legacy";
          };
          "var/lib/immich" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/immich";
            options.mountpoint = "legacy";
          };
          "var/lib/linkwarden" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/linkwarden";
            options.mountpoint = "legacy";
          };
        };
      };

      pithos = {
        type = "zpool";
        options.ashift = "12";

        rootFsOptions = {
          compression = "zstd";
          atime = "off";
          xattr = "sa";
          acltype = "posixacl";
          mountpoint = "none";
        };

        datasets = {
          art = { type = "zfs_fs"; mountpoint = "/pithos/art"; options.mountpoint = "legacy"; };
          episteme = { type = "zfs_fs"; mountpoint = "/pithos/episteme"; options.mountpoint = "legacy"; };
          techne = { type = "zfs_fs"; mountpoint = "/pithos/techne"; options.mountpoint = "legacy"; };
          memories = { type = "zfs_fs"; mountpoint = "/pithos/memories"; options.mountpoint = "legacy"; };
          logseq = { type = "zfs_fs"; mountpoint = "/pithos/logseq"; options.mountpoint = "legacy"; };
          prosopikos = { type = "zfs_fs"; mountpoint = "/pithos/prosopikos"; options.mountpoint = "legacy"; };
        };
      };
    };
  };
}
