{ config, ... }:

{
  networking.hostName = "matte-black-cadillac";

  # Remote access via Tailscale SSH.
  #
  # tailscaled terminates the SSH session itself, so there is no sshd, no host
  # key and no authorized_keys file. Who may open a shell is decided by the
  # tailnet policy file in the admin console, not by this repo.
  #
  age.secrets.tailscale-authkey.file = ./secrets/tailscale-authkey.age;

  services.tailscale = {
    authKeyFile = config.age.secrets.tailscale-authkey.path;

    extraUpFlags = [ "--ssh" ];
    extraSetFlags = [ "--ssh" ];

    openFirewall = true;
  };
}
