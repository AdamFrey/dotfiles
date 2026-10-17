{ config, lib, pkgs, ... }:

# Local model inference on the RX 580.
#
# Vulkan, not ROCm: the card is Polaris (gfx803), which ROCm dropped years
# ago. Mesa's RADV drives it fine and llama.cpp's Vulkan backend sidesteps the
# problem entirely.
#
# 8 GiB VRAM is the ceiling, and the desktop session shares it -- comfortable
# for 7-9B at Q4, tight above that.

let
  # Weights come from HuggingFace by hash rather than `ollama pull` by tag.
  # A tag can be repointed upstream and is not reproducible; this is content
  # addressed and cached in the store.
  #
  # To add one: nix store prefetch-file --name <file>.gguf <url>
  #
  # numCtx must also be set as contextWindow in ../../pi.nix. Ollama defaults
  # to 4096 and silently truncates past it, while clients assume far more.
  models = {
    "qwen3.5:9b" = {
      gguf = pkgs.fetchurl {
        url = "https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/resolve/main/Qwen3.5-9B-Q4_K_M.gguf";
        hash = "sha256-A7dHJ6hgpWM44ELEQguz8Esv7Fc0F19MufqFPa9St+g=";
      };

      # 5.7 GiB of weights leaves room for this much cache: only 8 of the 32
      # layers are full attention, so a token costs 32 KiB rather than the
      # ~128 KiB a conventional 9B would want.
      numCtx = 32768;
    };
  };

  # The prompt template ships in the GGUF metadata, so FROM and the context
  # length are the whole file.
  modelfile = name: m: pkgs.writeText "Modelfile-${lib.replaceStrings [ ":" ] [ "-" ] name}" ''
    FROM ${m.gguf}
    PARAMETER num_ctx ${toString m.numCtx}
  '';

  importScript = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: m: ''
      if ollama show ${lib.escapeShellArg name} >/dev/null 2>&1; then
        echo "${name}: already present"
      else
        echo "${name}: importing"
        ollama create ${lib.escapeShellArg name} -f ${modelfile name m}
      fi
    '') models
  );
in
{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;

    # Reachable from the laptops over the tailnet, not from the LAN.
    host = "0.0.0.0";
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 11434 ];

  # Imports are idempotent, so this converges rather than re-importing on
  # every rebuild. Removing a model from the set above does not delete
  # automatically; `ollama rm` it by hand.
  systemd.services.ollama-import-models = lib.mkIf (models != { }) {
    description = "Import nix-provided GGUF models into ollama";
    after = [ "ollama.service" ];
    requires = [ "ollama.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ config.services.ollama.package ];
    environment = {
      OLLAMA_HOST = "127.0.0.1:${toString config.services.ollama.port}";

      # The cli resolves the model directory at startup and aborts if it
      # cannot, which it cannot without one of these two.
      OLLAMA_MODELS = config.services.ollama.models;
      HOME = config.services.ollama.home;
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = config.services.ollama.user;
      Group = config.services.ollama.group;
    };
    script = importScript;
  };
}
