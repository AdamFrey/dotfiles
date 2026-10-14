{ config, lib, ... }:

# SMB mounts of the pithos datasets, served by matte-black-cadillac over the
# tailnet. See machines/desktop/samba.nix for the other end.
#
# Skipped on matte-black-cadillac, which holds the datasets itself.
#
let
  servesTheseDatasets = config.networking.hostName == "matte-black-cadillac";

  server = "matte-black-cadillac";
  datasets = [ "art" "episteme" "techne" "logseq" "prosopikos" "memories" ];

  smbMount = share: {
    device = "//${server}/${share}";
    fsType = "cifs";
    options = [
      "credentials=${config.age.secrets.pithos-smb-credentials.path}"

      # The server forces adam:users; match it so the client agrees.
      "uid=1000"
      "gid=100"
      "iocharset=utf8"
      "vers=3.1.1"

      "x-systemd.automount"
      "x-systemd.requires=tailscaled.service" # the address only resolves on the tailnet
      "x-systemd.idle-timeout=600"            # unmount after 10 minutes unused
      "x-systemd.mount-timeout=5"
      "noauto"
      "soft" # return errors rather than hanging when the desktop is away
    ];
  };

  root = "/home/adam/nas";
in
{
  age.secrets = lib.mkIf (!servesTheseDatasets) {
    pithos-smb-credentials.file = ./secrets/pithos-smb-credentials.age;
  };

  # mount.cifs ships only when this is set -- declaring a cifs fileSystem is
  # not enough.
  boot.supportedFilesystems.cifs = lib.mkIf (!servesTheseDatasets) true;

  fileSystems = lib.mkIf (!servesTheseDatasets) (
    lib.listToAttrs (
      map (d: lib.nameValuePair "${root}/${d}" (smbMount d)) datasets
    )
  );
}
