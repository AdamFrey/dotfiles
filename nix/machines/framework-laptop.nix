{ pkgs, pkgs-unstable, ... }:
{
  networking.hostName = "framework-laptop-nixos";

  environment.systemPackages = [ pkgs-unstable.spotify ];

  powerManagement.powerDownCommands = ''
  ${pkgs.kmod}/bin/modprobe -r mt7925e || true
'';

  services.browsersEnabled = true;

  powerManagement.resumeCommands = ''
  ${pkgs.kmod}/bin/modprobe mt7925e || true
'';
}
