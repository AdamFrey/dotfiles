{ ... }:

# Swap capacity for a 15 GiB machine that runs nine Docker services plus a pair
# of Clojure REPLs.
#
# Measured 2026-07-30 on work-laptop-nixos: zram compresses this workload 4.83x,
# and swap demand peaked near 12 GiB. memoryPercent = 50 gives only 7.5 GiB of
# zram, so the overflow landed on /swapfile — a file on ext4 on LUKS on NVMe.
# Paging through that path is what froze the desktop.

{
  zramSwap = {
    # Percent of RAM expressed as *uncompressed* capacity, not RAM consumed:
    # ~15 GiB of swap costs ~3.1 GiB of RAM at the measured ratio. Covers the
    # observed peak without reaching /swapfile. Raise to 150 if /swapfile still
    # accumulates during a spike.
    memoryPercent = 100;

    # Guard against a workload that compresses worse than this one. Without it,
    # a degraded ratio would let zram consume the RAM it exists to conserve.
    memoryMax = 4 * 1024 * 1024 * 1024;
  };

  boot.kernel.sysctl = {
    # Compressed swap is cheap on this machine — CPU pressure has never been
    # non-zero — so prefer evicting anonymous pages to dropping page cache.
    "vm.swappiness" = 150;

    # zram has no seek penalty, so the default 8-page readahead just decompresses
    # pages nobody asked for.
    "vm.page-cluster" = 0;
  };
}
