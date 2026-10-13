# Reinstalling matte-black-cadillac onto ZFS

The desktop is being rebuilt from ext4 onto two single-disk ZFS pools as part
of folding the TrueNAS box into it. This is the procedure.

The layout is declared in `disk-config.nix` and applied by disko, driven
remotely by nixos-anywhere. No installer USB, and nothing typed by hand at the
machine -- which matters because the dataset names have to match `zfs.nix`
exactly.

---

## 1. Preconditions

Do not start until all of these hold. Each one is recoverable before the disks
are wiped and not after.

| Check | How |
|---|---|
| Staging on the NAS is complete | `zfs list -r pithos/migration` shows `desktop-home` 16.5 G, `desktop-sda1` 48 G, `desktop-sda2-home` 47 G, `k3s-volumes` 16 G |
| Offsite backup has a recent archive | `borg list` against the Storage Box shows an archive from the last day |
| healthchecks.io is green | its dashboard |
| `restore-exclude.txt` and `restore-notes.md` exist | on the NAS at `/mnt/pithos/migration/` |
| The NAS is healthy | `zpool status pithos` — ONLINE, no errors |
| The laptop can reach the desktop as root over plain SSH | see 4.1 |

**The desktop's disks hold nothing unique at this point.** Everything was
staged to the NAS and verified by file count. The offsite copy is a third
copy of `/home`. That is what makes the wipe safe.

---

## 2. Hardware facts

Confirmed 2026-10-13.

| Device | Model | Size | Note |
|---|---|---|---|
| `nvme0n1` | Lexar NM790 | 2 TB | becomes `rpool` |
| `sda` | WDC WD20EZAZ | 2 TB | becomes `pithos`. **Drive-managed SMR**, 5400 rpm |

Both report 4096-byte physical sectors, so `ashift=12`.

The SMR disk is why every database and service state directory lives on the
NVMe and only bulk media goes on `sda`.

---

## 3. Disk layout

`disk-config.nix` in this directory declares both pools and every dataset.
Nothing is typed by hand.

**It is not imported by `default.nix`.** Importing it declares filesystems that
conflict with the ext4 layout the machine runs on today, and disko erases disks
without asking. It is switched on as part of step 4.

Device paths come from `private-nix`. Verify them against the machine if a disk has been swapped:

```sh
ls -l /dev/disk/by-id/ | grep -E 'nvme-Lexar|WDC_WD20EZAZ'
```

by-id rather than by-path throughout: by-path names a physical slot, so a moved
cable would point disko at a different disk and erase it.

---

## 4. Install with nixos-anywhere

No installer USB. `nixos-anywhere` kexecs into an installer over SSH, partitions
per `disk-config.nix`, and installs — all from the laptop.

### 4.1 Give it an SSH route in

The desktop has no sshd; Tailscale SSH is not enough, because nixos-anywhere
needs plain SSH as root. Add temporarily:

```nix
services.openssh = {
  enable = true;
  settings.PermitRootLogin = "prohibit-password";
};
users.users.root.openssh.authorizedKeys.keys = [ "<adam's id_ed25519.pub>" ];
```

Rebuild, confirm `ssh root@192.168.0.10 true` works from the laptop, then
**remove it again once the install is done**.

### 4.2 Switch on the reinstall modules

In `machines/desktop/default.nix`, add the four modules that have been waiting:

```nix
imports = [ ./disk-config.nix ./zfs.nix ./selfhosted.nix ./ollama.nix ./offsite-backup.nix ];
```

and in `flake.nix`'s desktop block, add `disko.nixosModules.disko`.

`hardware-configuration.nix` must stop declaring `fileSystems` — disko owns
them now. Keep its kernel modules and CPU settings.

Commit and push; nixos-anywhere evaluates from the flake.

**Check before running:**

```sh
nix eval .#nixosConfigurations.desktop.config.fileSystems --apply builtins.attrNames
```

Thirteen entries: `/`, `/boot`, `/home`, `/nix`, six under `/pithos`, and three
under `/var/lib`. If that is wrong, stop — it is far cheaper to fix here.

### 4.3 Run it

```sh
nix run github:nix-community/nixos-anywhere -- \
  --flake /home/adam/src/dotfiles/nix#desktop \
  --target-host root@192.168.0.10
```

**This erases both disks.** Everything irreplaceable is staged on the NAS and
in the Hetzner repository — that is what section 1 verifies.

The machine reboots into the new system when it finishes. If the kexec stage
fails the desktop may sit unreachable, so be ready to switch the monitor to it.

---

## 5. First boot, before restoring anything

| Check | Expected |
|---|---|
| `zpool status` | both pools ONLINE |
| `zfs list` | all datasets mounted where `disk-config.nix` declares them |
| `systemctl --failed` | empty, or only services waiting on absent data |
| `tailscale status` | node online — **this needs `sudo tailscale login`**, enrolment is manual by design |
| `systemctl list-timers` | `borgbackup-job-offsite` and `sanoid` present |

Services will be unhappy until section 6 — `/pithos/art` is empty, immich has
no library. That is expected, not a fault.

---

## 6. Restore

Four transfers with different destinations. `restore-notes.md` on the NAS is
authoritative; this is the summary.

```sh
# 1. bulk media  (~1.1 TB — the long one)
rsync -aHAX --info=progress2 \
  --exclude-from=/mnt/pithos/migration/restore-exclude.txt \
  admin@192.168.0.221:/mnt/pithos/ /pithos/

# 2. home
rsync -aHAX admin@192.168.0.221:/mnt/pithos/migration/desktop-home/ /home/adam/

# 3. immich originals -> NVMe, not pithos
rsync -aHAX admin@192.168.0.221:/mnt/pithos/immich/library/ /var/lib/immich/library/
rsync -aHAX admin@192.168.0.221:/mnt/pithos/immich/video/   /var/lib/immich/video/

# 4. linkwarden archives
rsync -aHAX admin@192.168.0.221:/mnt/pithos/migration/k3s-volumes/linkwarden-archives/ \
  /var/lib/linkwarden/
```

**Expect roughly three hours at 100 Mbit.** The Archer C54's LAN ports are
Fast Ethernet; moving both machines onto the EAP211 bridge's gigabit ports
would cut this to about 25 minutes. Worth doing first if the cabling is in hand.

`desktop-sda1` and `desktop-sda2-home` are **not** a wholesale restore target.
96 G was staged; about 21 G is kept and filed into existing `pithos`
categories, item by item. `restore-notes.md` section 8 on the NAS has the
per-item mapping and the list of what is dropped.

---

## 7. Post-restore

| Task | Note |
|---|---|
| immich library import | Fresh database by design. `pgData` on the NAS is PG 15 and eighteen months cold; the library is re-imported instead. Asset count should reach ~14,564 |
| linkwarden database | `pgdata` is **PG 16**, target is 17.11 — `pg_upgrade` or dump/restore before first start |
| Renames | `Im.Alan.Partridge.S01-S02...` to `Im Alan Partridge`; both films into per-title folders. See `restore-notes.md` §4 |
| Rewrite `filesystem.nix` | It still NFS-mounts from 192.168.0.221 on all four machines, including this one. The desktop must not mount from itself |
| Measure free VRAM | `cat /sys/class/drm/card*/device/mem_info_vram_*` under a normal niri session, before sizing ollama models |

---

## 8. The gate before the NAS is wiped

**Do not destroy `pithos` on the NAS until every one of these passes.** This is
spec §7.1, and it is the last point at which anything is recoverable.

- All services running and reachable over tailnet or LAN as configured
- immich asset count matches the source
- emby plays from `/pithos/art` and the Roku can reach it
- A borg restore test pulls a sampled file back intact
- `desktop-sda1` and `desktop-sda2-home` have been filed per `restore-notes.md` §8, not merely copied

Then, and only then: wipe `pithos`, remove the SSH key authorised during the
migration, disable the SSH service, remove the node from the tailnet, and ship
both Exos drives with the machine.
