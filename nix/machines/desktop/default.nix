{
  imports = [ ./offsite-backup.nix ];

  networking.hostName = "matte-black-cadillac";

  # Remote access via Tailscale SSH.
  #
  # tailscaled terminates the SSH session itself, so there is no sshd, no host
  # key and no authorized_keys file. Who may open a shell is decided by the
  # tailnet policy file in the admin console, not by this repo.
  #
  # Enrollment is manual. The node key lives in
  # /var/lib/tailscale with expiry disabled, so it survives reboots and
  # rebuilds indefinitely. Rejoining after a reinstall, or after losing
  # /var/lib/tailscale, needs `sudo tailscale login` at the machine.
  services.tailscale = {
    extraSetFlags = [ "--ssh" ];

    openFirewall = true;
  };
}
