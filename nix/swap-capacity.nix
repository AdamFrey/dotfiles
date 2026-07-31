{ ... }:

# Swap capacity for a 15 GiB machine that runs nine Docker services plus a pair
# of Clojure REPLs.
#
# Measured 2026-07-30 on work-laptop-nixos: zram compresses this workload 4.83x,
# and swap demand peaked near 12 GiB. The stock memoryPercent = 50 gives only
# 7.5 GiB of zram, so the overflow landed on /swapfile — a file on ext4 on LUKS
# on NVMe. Paging through that path is what froze the desktop.

let
  # zram capacity as a percentage of RAM, counted in *uncompressed* pages.
  # At the measured ratio, ~15 GiB of capacity costs ~3.1 GiB of RAM.
  zramCapacityPercent = 100;

  # Ceiling on the RAM zram itself may consume. When compressed data reaches it,
  # zram refuses further pages and the kernel falls through to /swapfile — the
  # slow path, but a bounded one. Without this a workload that compresses poorly
  # could spiral: swapping consumes RAM, which raises pressure, which swaps more.
  #
  # NOT expressible as zramSwap.memoryMax. That option caps *disksize*, so
  # setting it to 4 GiB silently overrode zramCapacityPercent and left the
  # machine with less zram than the stock 50% it replaced.
  zramRamCeiling = "4G";
in
{
  zramSwap.memoryPercent = zramCapacityPercent;

  # zram-generator owns disksize; mem_limit has no NixOS option, so it is set on
  # the device itself. "add|change" so a device reset re-applies it.
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="zram0", ATTR{mem_limit}="${zramRamCeiling}"
  '';

  boot.kernel.sysctl = {
    # Prefer evicting anonymous pages to dropping page cache, because compressed
    # swap is cheap here — CPU pressure has never been non-zero.
    #
    # Valid only while zramCapacityPercent keeps zram large. A small zram plus
    # aggressive swapping drives traffic straight onto the encrypted swapfile,
    # which is the failure this module exists to prevent. Move the two together.
    "vm.swappiness" = 150;

    # zram has no seek penalty, so the default 8-page readahead just decompresses
    # pages nobody asked for.
    "vm.page-cluster" = 0;
  };
}
