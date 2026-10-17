{ pkgs, ... }:

# Pi, pointed at the desktop's ollama over the tailnet.
#
# MagicDNS rather than localhost so the same config works from either laptop
# and from the desktop itself. Reaching it needs tailscale up: ollama's port
# is open on tailscale0 only.

let
  ollamaUrl = "http://matte-black-cadillac:11434/v1";

  # Mirrors machines/desktop/ollama.nix; pi has no way to discover what is
  # installed, so adding a model there means adding it here too.
  #
  # contextWindow must match that model's num_ctx. Pi assumes 128k otherwise
  # and will overrun the window ollama actually allocated.
  models = [
    {
      id = "granite4.2:8b";
      contextWindow = 8192;

      # Leaves three quarters of the window for the conversation.
      maxTokens = 2048;
    }
  ];

  modelsJson = {
    providers.ollama = {
      baseUrl = ollamaUrl;
      api = "openai-completions";

      # Required by pi, ignored by ollama.
      apiKey = "ollama";

      # Ollama rejects the developer role and reasoning_effort that pi sends
      # to reasoning-capable models by default.
      compat = {
        supportsDeveloperRole = false;
        supportsReasoningEffort = false;
      };

      inherit models;
    };
  };

  settingsJson = {
    defaultModel = "ollama/${(builtins.head models).id}";
  };
in
{
  home.packages = [ pkgs.pi-coding-agent ];

  home.file = {
    ".pi/agent/models.json".text = builtins.toJSON modelsJson;
    ".pi/agent/settings.json".text = builtins.toJSON settingsJson;
  };
}
