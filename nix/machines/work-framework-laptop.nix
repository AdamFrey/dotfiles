{ pkgs, pkgs-unstable, ... }:
{
  networking.hostName = "work-laptop-nixos";

  networking.extraHosts = ''
    127.0.0.1 facebook.com
    127.0.0.1 www.facebook.com
    127.0.0.1 wikipedia.org
    127.0.0.1 en.wikipedia.org
    127.0.0.1 scryfall.com
    127.0.0.1 www.scryfall.com
    127.0.0.1 cubecobra.com
    127.0.0.1 www.cubecobra.com
    127.0.0.1 mtg.wiki
    127.0.0.1 www.mtg.wiki
    127.0.0.1 mtgtop8.com
    127.0.0.1 www.mtgtop8.com
    127.0.0.1 manapool.com
    127.0.0.1 www.manapool.com
    127.0.0.1 moxfield.com
    127.0.0.1 www.moxfield.com
    127.0.0.1 mtgstocks.com
    127.0.0.1 www.mtgstocks.com
    127.0.0.1 wizards.com
    127.0.0.1 magic.wizards.com
    127.0.0.1 tcgplayer.com
    127.0.0.1 www.tcgplayer.com
    127.0.0.1 edhrec.com
    127.0.0.1 www.edhrec.com
  '';

  environment.systemPackages = with pkgs; [
    mitmproxy
    podman-desktop
    pkgs-unstable.opencode
    vscode
    (google-cloud-sdk.withExtraComponents (
      with google-cloud-sdk.components;
      [
        gke-gcloud-auth-plugin
      ]
    ))
  ];


  networking.firewall.interfaces."br-+".allowedTCPPorts = [ 8082 ];

  powerManagement.powerDownCommands = ''
  ${pkgs.kmod}/bin/modprobe -r mt7925e || true
'';

  services.browsersEnabled = true;

  services.rh-snapshot-btrfs = {
    enable = true;
    owner = "adam";
    imageSize = "32G"; # TBD: adjust after measuring per workshop/rh-snapshot/SPEC.md §3.3.2
  };

  powerManagement.resumeCommands = ''
  ${pkgs.kmod}/bin/modprobe mt7925e || true
'';
}
