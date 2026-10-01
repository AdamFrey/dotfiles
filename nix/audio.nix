{ pkgs, ... }:

{
  # Enable sound with pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # Real-time audio priority for music production
  security.pam.loginLimits = [
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "rtprio"; type = "-"; value = "99"; }
    { domain = "@audio"; item = "nice"; type = "-"; value = "-19"; }
  ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Microphone selection. Three ALSA capture nodes exist on the work laptop,
  # and WirePlumber gave the built-in mic array and the empty 3.5mm jack the
  # same priority.session (2000). Ties fall through to route priority
  # (scripts/default-nodes/find-best-default-node.lua), which kept picking the
  # jack -- and an empty jack records silence.
  #
  # Matches are regexes ("~" prefix) on node.name rather than exact strings:
  # the webcam's node name carries its serial and the internal card's carries a
  # PCI path, neither of which should be pinned in a config shared by every
  # machine.
  #
  # To check after a rebuild, with `wpctl status` reading the Sources list:
  #   webcam plugged in  -> "HD Pro Webcam C920 Analog Stereo" carries the *
  #   webcam unplugged   -> "Digital Microphone" carries it
  #   webcam replugged   -> back to the C920, without logging out
  services.pipewire.wireplumber.extraConfig."51-microphone-priority" = {
    "wireplumber.settings" = {
      # Without this, WirePlumber restores whatever was last made default from
      # ~/.local/state/wireplumber/default-nodes and never consults the
      # priorities below. Accepted cost: a default chosen at runtime -- wpctl
      # set-default, or an application's device dropdown -- no longer survives
      # a restart, and that applies to sinks and cameras as well as sources.
      "node.restore-default-targets" = false;
    };

    "monitor.alsa.rules" = [
      {
        # Logitech C920 webcam mic: preferred whenever it is plugged in.
        matches = [ { "node.name" = "~alsa_input\\.usb-046d_HD_Pro_Webcam_C920_.*"; } ];
        actions.update-props."priority.session" = 3000;
      }
      {
        # Framework's built-in mic array: the fallback when the webcam is away.
        matches = [ { "node.name" = "~alsa_input\\..*\\.HiFi__Mic1__source"; } ];
        actions.update-props."priority.session" = 2000;
      }
      {
        # 3.5mm headset jack: never used here, and silent with nothing plugged
        # in. Ranked below both, but left selectable rather than removed.
        matches = [ { "node.name" = "~alsa_input\\..*\\.HiFi__Headset__source"; } ];
        actions.update-props."priority.session" = 100;
      }
    ];
  };

  # Audio/MIDI packages
  environment.systemPackages = with pkgs; [
    alsa-utils
    pulsemixer  # TUI for audio device/volume control
    qpwgraph
    qsynth
  ];
}
