{ inputs, ... }:

{
  imports = [
    ./disk-config.nix
    ./zfs.nix
    ./selfhosted.nix
    ./ollama.nix
    ./offsite-backup.nix
  ];

  networking.hostName = "matte-black-cadillac";

  # Only applied on a fresh install; mutableUsers leaves passwd alone after.
  users.users.adam.hashedPassword = inputs.private-nix.userPasswords.desktop.adam;

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

  # ---------------------------------------------------------------------
  # TEMPORARY -- remove once the reinstall is done. See reinstall.md 4.1.
  #
  # Contradicts the paragraph above on purpose: nixos-anywhere needs plain
  # SSH as root, which Tailscale SSH cannot provide. It also kexecs into an
  # installer that has no tailscale at all, so the route in has to be the
  # LAN -- hence the rule on enp6s0 rather than tailscale0.
  #
  # Key-only, no passwords, and not reachable beyond the local segment.
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICxnBNepKp/F//SWNkI9aIa3qXEtcr2hA0JgI6iiUvgJ adam@adamfrey.me"
  ];

  networking.firewall.interfaces."enp6s0".allowedTCPPorts = [ 22 ];
  # ---------------------------------------------------------------------
}
