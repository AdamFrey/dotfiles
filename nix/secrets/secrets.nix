# agenix recipient manifest. Public keys only — safe to track.
#
# Every machine decrypts with `age.identityPaths` (configuration.nix), which
# points at adam's *user* key rather than a host key: no machine in this flake
# runs sshd, so /etc/ssh/ssh_host_ed25519_key does not exist to encrypt to.
let
  adamUserKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICxnBNepKp/F//SWNkI9aIa3qXEtcr2hA0JgI6iiUvgJ adam@adamfrey.me";
in
{
  "ssh-config-entries.age".publicKeys = [ adamUserKey ];
}
