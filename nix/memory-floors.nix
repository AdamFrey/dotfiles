{ config, ... }:

# Reclaim protection for the interactive session.
#
# Sibling slices under user@1000.service, one per workload with its own
# protection need:
#
#   session.slice   512M   niri, pipewire, portals — the machine's controls
#   term.slice     1024M   kitty terminals opened with Mod+Return
#   app.slice       512M   the browser, Slack, podman-desktop — reclaimable
#   emacs.slice    1024M   the Emacs daemon alone
#   repl.slice      512M   the Clojure REPL JVMs
#
# A slice only protects its children when its floor EXCEEDS its own usage.
# Measured 2026-07-31: session.slice (92 MiB used, 512M floor) delivered 88% of
# its events to niri, which claims nothing; app.slice at 2048M over 3223 MiB of
# usage delivered zero to any of its twelve children. session.slice, term.slice
# and emacs.slice are sized above their usage for that reason; app.slice and
# repl.slice are deliberately left below theirs.
#
# The split exists because one app.slice holding both Emacs and the terminals did
# not work. Measured 2026-07-31: app.slice recorded 708,281 deflected reclaim
# attempts and emacs.service took 708,072 of them — 99.97% — while every kitty
# scope stayed at zero. A child that claims protection absorbs what its
# unprotected siblings would otherwise receive.
#
# session.slice demonstrates the working shape: no child claims anything, so its
# whole floor is surplus, and niri — memory.low = 0 — collected 130,529 of that
# slice's 134,304 events. Every slice here is floored at the slice level with no
# claiming child beneath it, so the surplus reaches the leaves.
#
# memory.low is deliberate: best-effort protection the kernel may breach under
# genuine exhaustion. memory.min is hard, and hard protection on a machine with
# no OOM history would introduce kills where today there is only stalling.

let
  # niri, pipewire, the xdg portals. Measured working set 139 MiB across RAM and
  # swap; generous because losing these means losing control of the machine.
  sessionFloorMiB = 512;

  # kitty terminals spawned by Mod+Return, which sources/niri.kdl wraps in
  # systemd-run --slice=term.slice. Measured ~853 MiB across four terminals;
  # 1024 leaves 20% headroom.
  #
  # Terminals were moved here rather than the browser being moved out of
  # app.slice: Mod+Return is one line, whereas relocating the browser meant
  # desktop-entry overrides plus the BROWSER= env path plus a keybinding.
  termFloorMiB = 1024;

  # The browser, Slack, podman-desktop. Deliberately below its ~2100 MiB usage:
  # the frame designated the browser sacrificeable, and 512 leaves Slack a
  # working set. Protection here is distributed by usage, so the browser gets the
  # larger share regardless — there is no way to favour Slack inside one slice.
  appFloorMiB = 512;

  # The Emacs daemon alone once the REPLs move to repl.slice — ~540-875 MiB
  # measured. 512 would have put this slice above its own usage, the same
  # configuration that delivered nothing to app.slice's children.
  emacsFloorMiB = 1024;

  # The two CIDER JVMs. 512 MiB covers 44% of their measured live heap
  # (441 + 726 MiB), so it reduces GC-pause risk rather than removing it.
  replFloorMiB = 512;

  # cgroup v2 truncates a child's effective protection to its parent's unclaimed
  # share, so every shared ancestor must cover the sum of its descendants'
  # claims — and must not exceed it. Surplus at this level would be distributed
  # by usage, and repl.slice is by far the largest user.
  ancestorFloorMiB =
    sessionFloorMiB + termFloorMiB + appFloorMiB + emacsFloorMiB + replFloorMiB;

  # Concrete unit names, not the user-.slice and user@.service templates. The
  # templates matched every gdm-greeter account too, so five login-screen users
  # each claimed the full reservation from a parent that only offers it once.
  uid = toString config.users.users.adam.uid;

  mib = n: "${toString n}M";

  # asDropin extends systemd's own unit definitions instead of replacing them.
  # Only for slices systemd ships; the two we introduce are defined outright.
  dropinSlice = floor: {
    overrideStrategy = "asDropin";
    sliceConfig.MemoryLow = mib floor;
  };
in
{
  # System-manager chain: user.slice -> user-<uid>.slice -> user@<uid>.service.
  systemd.slices = {
    user = dropinSlice ancestorFloorMiB;
    "user-${uid}" = dropinSlice ancestorFloorMiB;
  };

  systemd.services."user@${uid}" = {
    overrideStrategy = "asDropin";
    serviceConfig.MemoryLow = mib ancestorFloorMiB;
  };

  systemd.user.slices = {
    # Shipped by systemd.
    session = dropinSlice sessionFloorMiB;
    app = dropinSlice appFloorMiB;

    # Ours. Each is populated by a systemd-run --scope at launch:
    #   term.slice  <- sources/niri.kdl, Mod+Return
    #   repl.slice  <- sources/doom/config.el, advice on nrepl-start-server-process
    #   emacs.slice <- emacs-daemon.nix, Slice= on the unit
    term = {
      description = "Interactive terminals";
      sliceConfig.MemoryLow = mib termFloorMiB;
    };

    emacs = {
      description = "Emacs daemon";
      sliceConfig.MemoryLow = mib emacsFloorMiB;
    };

    repl = {
      description = "Clojure REPL JVMs";
      sliceConfig.MemoryLow = mib replFloorMiB;
    };
  };
}
