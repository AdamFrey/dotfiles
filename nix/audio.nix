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

  # Audio/MIDI packages
  environment.systemPackages = with pkgs; [
    alsa-utils
    pulsemixer  # TUI for audio device/volume control
    qpwgraph
    qsynth
  ];
}
