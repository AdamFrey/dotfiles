{ pkgs, ... }:
{
  networking.hostName = "work-laptop-nixos";

  environment.systemPackages = with pkgs; [
    freelens-bin
  ];

  powerManagement.powerDownCommands = ''
  ${pkgs.kmod}/bin/modprobe -r mt7925e || true
'';

  services.browsersEnabled = true;

  powerManagement.resumeCommands = ''
  ${pkgs.kmod}/bin/modprobe mt7925e || true
'';
}
