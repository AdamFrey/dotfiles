{ pkgs, ... }:
{
  networking.hostName = "work-laptop-nixos";

  environment.systemPackages = with pkgs; [
    freelens-bin
    (google-cloud-sdk.withExtraComponents (
      with google-cloud-sdk.components;
      [
        gke-gcloud-auth-plugin
      ]
    ))
  ];

  powerManagement.powerDownCommands = ''
  ${pkgs.kmod}/bin/modprobe -r mt7925e || true
'';

  services.browsersEnabled = true;

  powerManagement.resumeCommands = ''
  ${pkgs.kmod}/bin/modprobe mt7925e || true
'';
}
