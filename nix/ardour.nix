{ pkgs, ... }:

{
  # Ardour DAW with essential plugins for a GarageBand-like experience
  # Requires audio.nix for PipeWire/JACK and realtime audio settings

  environment.systemPackages = with pkgs; [
    # DAW
    ardour

    # LV2/LADSPA plugin suites
    x42-plugins         # High-quality meters, EQ, compression
    calf                # Synths, effects, and processing
    lsp-plugins         # Comprehensive plugin suite (compressors, EQs, etc.)
    distrho-ports       # Collection of DISTRHO plugins

    # Reverb and effects
    dragonfly-reverb    # Quality algorithmic reverbs
    zam-plugins         # Mastering and mixing tools
    gxplugins-lv2       # Guitar amp simulations

    # Synthesizers
    yoshimi             # Software synthesizer (ZynAddSubFX fork)
    surge-XT            # Hybrid synthesizer
    vital               # Wavetable synthesizer

    # Drums and samplers
    drumgizmo           # Acoustic drum sampling
    hydrogen            # Drum machine/pattern sequencer
    drumkv1             # Simple drum sampler

    # Utilities
    carla               # Plugin host (useful for bridging/testing plugins)
    jack_capture        # Simple audio recording
  ];
}
