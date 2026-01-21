{ pkgs, pkgs-unstable, ... }:

let
  makeBabashkaCmd = src: name: module: pkgs.writeShellScriptBin name ''
    exec ${pkgs-unstable.babashka}/bin/bb --config ${src}/bb.edn -m ${module} "$@"
  '';

  clojure-mcp-light-src = pkgs.fetchFromGitHub {
    owner = "bhauman";
    repo = "clojure-mcp-light";
    rev = "v0.2.1";
    hash = "sha256-h8eX+HRPQ74hO5Ql5wz9znOoMAY2nncrgXoE+Nk+J54=";
  };

  mkClojureMcpCmd = makeBabashkaCmd clojure-mcp-light-src;

  clj-paren-repair-claude-hook = mkClojureMcpCmd "clj-paren-repair-claude-hook" "clojure-mcp-light.hook";
  clj-nrepl-eval = mkClojureMcpCmd "clj-nrepl-eval" "clojure-mcp-light.nrepl-eval";
  clj-paren-repair = mkClojureMcpCmd "clj-paren-repair" "clojure-mcp-light.paren-repair";

  invoker-src = let
    rev = "656d3657f1532182ad2a3acd6afbaa255d8ca397";
    shortSha = builtins.substring 0 7 rev;
    src = pkgs.fetchFromGitHub {
      owner = "filipesilva";
      repo = "invoker";
      inherit rev;
      hash = "sha256-aSTaYdDfU9QFpY+aIPvqn+kEgdU3SF058g/vFwje/5M=";
    };
  # Instead of letting invoker shell out to find SHA, hardcode it in the source  
  in pkgs.runCommand "invoker-patched" {} ''
    cp -r ${src} $out
    chmod -R u+w $out
    substituteInPlace $out/src/invoker/utils.clj \
      --replace-fail \
        'sha (str/trim (:out (process/sh opts "git rev-parse HEAD")))' \
        'sha "${rev}"' \
      --replace-fail \
        'out (str/trim (:out (process/sh opts "git describe --tags --dirty --always --long")))' \
        'out "nix-0-g${shortSha}"'
  '';

  nvk = makeBabashkaCmd invoker-src "nvk" "invoker.nvk";
in
{
  environment.systemPackages = [
    clj-paren-repair-claude-hook
    clj-nrepl-eval
    clj-paren-repair
    nvk
  ];
}
