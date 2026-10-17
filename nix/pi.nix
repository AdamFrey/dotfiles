{ pkgs, ... }:

# The pi coding agent.
#
# No provider is configured. Pi reads ~/.pi/agent/models.json; see
# `pi --help` and the models.md in its package for the shape, and
#   git show dbc8aba:nix/pi.nix
# for a worked example (a local ollama endpoint, removed 2026-10-17).
#
# Keep any API key out of this file: home.file lands in the world-readable
# nix store. The apiKey field takes an environment variable name, or
# "!cat ${config.age.secrets.<name>.path}" to read an agenix secret.

{
  home.packages = [ pkgs.pi-coding-agent ];
}
