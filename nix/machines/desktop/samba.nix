{ lib, ... }:

# SMB over the tailnet, for the pithos datasets.
#
# SMB rather than NFS because the iOS Files app speaks only SMB.
#
let
  datasets = [ "art" "episteme" "techne" "logseq" "prosopikos" "memories" ];
in
{
  services.samba = {
    enable = true;

    # Broadcast name service. It cannot cross the tailnet, so clients find
    # this host by MagicDNS instead.
    nmbd.enable = false;

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
    // lib.genAttrs datasets (name: {
      path = "/pithos/${name}";
      browseable = "yes";
      "read only" = "no";
      "valid users" = "adam";

      # Clients present their own ids; pin everything to adam:users so the
      # files stay readable from the console and inside the borg job.
      "force user" = "adam";
      "force group" = "users";
      "create mask" = "0644";
      "directory mask" = "0755";
    });
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 445 ];
}
