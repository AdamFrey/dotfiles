{ config, lib, pkgs, ... }:
let
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
  fileSystems."${root}/art"        = nasMount "art";
  fileSystems."${root}/immich"     = nasMount "immich";
  fileSystems."${root}/episteme"   = nasMount "episteme";
  fileSystems."${root}/logseq"     = nasMount "logseq";
  fileSystems."${root}/techne"     = nasMount "techne";
  fileSystems."${root}/prosopikos" = nasMount "prosopikos";
}
