{ lib, ... }:

# SMB over the tailnet, for the pithos datasets.
#
# SMB rather than NFS because the iOS Files app speaks only SMB.
#
let
  # art is the shared media pool: emby, audiobookshelf, sonarr and qbittorrent
  # all read and write it, so it is owned by the media group. The rest is
  # adam's own material and stays adam:users.
  datasets = {
    art = "media";
    episteme = "users";
    techne = "users";
    logseq = "users";
    prosopikos = "users";
    memories = "users";
  };
in
{
  services.samba = {
    enable = true;

    # Broadcast name service. It cannot cross the tailnet, so clients find
    # this host by MagicDNS instead.
    nmbd.enable = false;

    # We don't need Windows support
    winbindd.enable = false;

    # Would open 139 and 445 on every interface. The rule at the bottom is
    # tailnet-only, matching how selfhosted.nix scopes its admin ports.
    openFirewall = false;

    settings = {
      global = {
        "server string" = "matte-black-cadillac";
        "server min protocol" = "SMB3";
        "map to guest" = "never";
      };
    }
    // lib.mapAttrs (name: group: {
      path = "/pithos/${name}";
      browseable = "yes";
      "read only" = "no";
      "valid users" = "adam";

      # Clients present their own ids. Pinning the owner keeps what lands
      # here readable from the console, by the services, and by the borg job.
      "force user" = "adam";
      "force group" = group;
      "create mask" = "0664";
      "directory mask" = "2775";
    }) datasets;
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 445 ];
}
