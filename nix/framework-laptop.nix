{ pkgs, ... }:
{
  networking.hostName = "framework-laptop-nixos";

  powerManagement.powerDownCommands = ''
  ${pkgs.kmod}/bin/modprobe -r mt7925e || true
'';

  powerManagement.resumeCommands = ''
  ${pkgs.kmod}/bin/modprobe mt7925e || true
'';
}
