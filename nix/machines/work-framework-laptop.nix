{ pkgs, ... }:
{
  networking.hostName = "work-laptop-nixos";

  networking.extraHosts = ''
    127.0.0.1 facebook.com
    127.0.0.1 www.facebook.com
  '';

  environment.systemPackages = with pkgs; [
    freelens-bin
    lens
    mitmproxy
    podman-desktop
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
