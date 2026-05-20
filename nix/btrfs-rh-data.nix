{ config, lib, pkgs, utils, ... }:

# NixOS module: loop-mounted Btrfs image backing the rh-snapshot dev tool.
#
# Contract:
#   pre  — host has free space on / for the image; user account exists.
#   post — `findmnt /mnt/btrfs-rh-data` reports fstype=btrfs with
#          `user_subvol_rm_allowed`; mountpoint is owned by `cfg.owner`;
#          subvolume create/delete succeeds as that user without sudo.
#   inv  — the image file is created exactly once per generation:
#          ConditionPathExists guards re-init.

let
  inherit (lib) mkOption mkIf mkEnableOption types;
  cfg = config.services.rh-snapshot-btrfs;
  mountUnit = "${utils.escapeSystemdPath cfg.mountPoint}.mount";
in
{
  options.services.rh-snapshot-btrfs = {
    enable = mkEnableOption "Btrfs loop-mounted image backing the rh-snapshot dev tool";

    imagePath = mkOption {
      type = types.str;
      default = "/var/lib/btrfs-rh-data.img";
      description = "Path to the btrfs image file backing the mount.";
    };

    mountPoint = mkOption {
      type = types.str;
      default = "/mnt/btrfs-rh-data";
      description = "Where the btrfs filesystem is mounted.";
    };

    imageSize = mkOption {
      type = types.str;
      default = "32G";
      example = "64G";
      description = ''
        Size for `truncate -s` on first init. Only used if the image
        doesn't yet exist. Grow later with `truncate -s +NG` followed by
        `sudo btrfs filesystem resize +NG ${cfg.mountPoint}`.
      '';
    };

    owner = mkOption {
      type = types.str;
      example = "adam";
      description = "User who owns the mount point and creates subvolumes.";
    };

    group = mkOption {
      type = types.str;
      default = "users";
      description = "Group for the mount point ownership.";
    };
  };

  config = mkIf cfg.enable {
    boot.supportedFilesystems = [ "btrfs" ];

    environment.systemPackages = [ pkgs.btrfs-progs ];

    fileSystems.${cfg.mountPoint} = {
      device = cfg.imagePath;
      fsType = "btrfs";
      options = [ "loop" "user_subvol_rm_allowed" "noatime" "nofail" ];
    };

    systemd.services."rh-snapshot-btrfs-init" = {
      description = "Initialize Btrfs image for rh-snapshot at ${cfg.imagePath}";
      wantedBy = [ mountUnit ];
      before = [ mountUnit ];
      unitConfig.ConditionPathExists = "!${cfg.imagePath}";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ pkgs.coreutils pkgs.btrfs-progs ];
      script = ''
        set -eu
        truncate -s ${cfg.imageSize} ${cfg.imagePath}
        mkfs.btrfs -f ${cfg.imagePath}
      '';
    };

    # Set ownership/perms of the mounted filesystem root so the user can
    # create subvolumes (under user_subvol_rm_allowed they still need
    # write to the parent dir).
    systemd.tmpfiles.rules = [
      "z ${cfg.mountPoint} 0775 ${cfg.owner} ${cfg.group} -"
    ];
  };
}
