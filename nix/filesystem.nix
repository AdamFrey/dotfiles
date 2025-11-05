{ config, lib, pkgs, ... }:
let
  nasMount = path: {
    device = "192.168.0.221:/mnt/pithos/${path}";
    fsType = "nfs";
    options = [ "x-systemd.automount" "x-systemd.requires=network-online.target" "x-systemd.device-timeout=500ms" ];
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
