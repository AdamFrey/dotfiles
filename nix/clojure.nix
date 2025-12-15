{ pkgs, pkgs-unstable, ... }:

let
  clojure-mcp-light-src = pkgs.fetchFromGitHub {
    owner = "bhauman";
    repo = "clojure-mcp-light";
    rev = "v0.2.1";
    hash = "sha256-h8eX+HRPQ74hO5Ql5wz9znOoMAY2nncrgXoE+Nk+J54=";
  };

  mkClojureMcpCmd = name: module: pkgs.writeShellScriptBin name ''
    exec ${pkgs-unstable.babashka}/bin/bb --config ${clojure-mcp-light-src}/bb.edn -m ${module} "$@"
  '';

  clj-paren-repair-claude-hook = mkClojureMcpCmd "clj-paren-repair-claude-hook" "clojure-mcp-light.hook";
  clj-nrepl-eval = mkClojureMcpCmd "clj-nrepl-eval" "clojure-mcp-light.nrepl-eval";
  clj-paren-repair = mkClojureMcpCmd "clj-paren-repair" "clojure-mcp-light.paren-repair";
in
{
  environment.systemPackages = [
    clj-paren-repair-claude-hook
    clj-nrepl-eval
    clj-paren-repair
  ];
}
