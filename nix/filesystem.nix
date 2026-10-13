{ config, lib, pkgs, ... }:

# NFS automounts for the shared datasets.
#
# Skipped on matte-black-cadillac, which holds the datasets itself once the
# NAS is folded into it -- a machine has no business NFS-mounting its own
# storage, and after the NAS is gone these would point at nothing.
#
# The address is still the NAS. It moves to the desktop once that machine
# serves NFS; until then the laptops keep reading from 192.168.0.221.
let
  servesTheseDatasets = config.networking.hostName == "matte-black-cadillac";

  nasMount = path: {
    device = "192.168.0.221:/mnt/pithos/${path}";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "x-systemd.requires=network-online.target"
      "x-systemd.device-timeout=500ms"
      "x-systemd.mount-timeout=2" # Fail mount attempts after 2 seconds
      "x-systemd.idle-timeout=600" # disconnects after 10 minutes of inactivity
      "noauto"
      "soft"      # Return errors instead of hanging
      "timeo=10"  # NFS timeout in deciseconds (1 second)
      "retrans=1" # Only retry once before failing
    ];
  };
  root = "/home/adam/nas";
in
{
  fileSystems = lib.mkIf (!servesTheseDatasets) {
    "${root}/art"        = nasMount "art";
    "${root}/immich"     = nasMount "immich";
    "${root}/episteme"   = nasMount "episteme";
    "${root}/logseq"     = nasMount "logseq";
    "${root}/techne"     = nasMount "techne";
    "${root}/prosopikos" = nasMount "prosopikos";
  };
}
