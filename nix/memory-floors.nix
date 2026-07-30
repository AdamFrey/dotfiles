{ ... }:

# Reclaim protection for the interactive session.
#
# Nothing on this machine had a memory.low floor, so kernel reclaim treated the
# compositor and the editor as equal candidates to a Clojure test run. Measured
# 2026-07-30: niri held 31 MiB resident against 56 MiB paged out, and the Emacs
# daemon held 471 MiB resident against 1605 MiB paged out. The desktop was
# living in swap.
#
# memory.low is deliberate: it is best-effort protection the kernel may breach
# under genuine exhaustion. memory.min is hard, and hard protection on a machine
# with no OOM history would introduce kills where today there is only stalling.

let
  # session.slice — niri, pipewire, the xdg portals. Measured working set across
  # RAM and swap was 139 MiB; this leaves 3.7x headroom for almost nothing.
  sessionFloorMiB = 512;

  # emacs.service — the daemon's real footprint was 2076 MiB, four fifths of it
  # paged out. Sized to let the whole working set stay resident.
  emacsFloorMiB = 2048;

  # cgroup v2 truncates a child's effective protection to its parent's unclaimed
  # share, so every shared ancestor must cover the sum of its descendants'
  # claims. Setting floors on the leaves alone yields zero protection — hence
  # deriving this rather than writing the number twice.
  ancestorFloorMiB = sessionFloorMiB + emacsFloorMiB;

  mib = n: "${toString n}M";

  # asDropin: extend systemd's own unit definitions instead of replacing them.
  dropinSlice = floor: {
    overrideStrategy = "asDropin";
    sliceConfig.MemoryLow = mib floor;
  };
in
{
  # System-manager chain: user.slice -> user-<uid>.slice -> user@<uid>.service.
  # The template names carry the trailing separator systemd expects.
  systemd.slices = {
    user = dropinSlice ancestorFloorMiB;
    "user-" = dropinSlice ancestorFloorMiB;
  };

  systemd.services."user@" = {
    overrideStrategy = "asDropin";
    serviceConfig.MemoryLow = mib ancestorFloorMiB;
  };

  # User-manager chain: session.slice holds the compositor, app.slice holds Emacs.
  systemd.user.slices = {
    session = dropinSlice sessionFloorMiB;
    app = dropinSlice emacsFloorMiB;
  };

  # The leaf. emacs.nix defines this unit; the floor lives here so the ancestor
  # arithmetic above stays in one file.
  #
  # Caveat: the kernel protects cgroup charge, not named processes. While the
  # CIDER REPLs run inside emacs.service, this floor cannot guarantee the 2 GiB
  # it retains belongs to the daemon rather than a JVM heap. If Emacs still
  # stalls while REPL heaps stay resident, the REPLs need their own slice.
  systemd.user.services.emacs.serviceConfig.MemoryLow = mib emacsFloorMiB;
}
