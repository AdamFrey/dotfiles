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

Three things did fail on the 2026-10-13 install, and two were config bugs:

- **`swapfile.swap`** — "it appears to have holes". ZFS allocates the file
  sparsely and `swapon` refuses it. Fixed in `configuration.nix`: the swapfile
  is now declared only on a non-ZFS root. zram carries swap on this machine.
- **`podman-emby`** — "statfs /var/lib/emby: no such file or directory".
  podman will not create a bind-mount source. Fixed in `selfhosted.nix` with a
  `systemd.tmpfiles` rule.
- **`/run/agenix` empty, so miniflux and the borg job cannot start.** Not a
  bug — `age.identityPaths` is `/home/adam/.ssh/id_ed25519`, and `/home` is an
  empty dataset until section 6. **Every secret stays undecryptable until the
  home restore lands, the offsite backup included** -- and `nixos-rebuild`
  itself fails on `agenixChown` until then, so this blocks fixing anything
  else. Copy the identity across before the first rebuild:

  ```sh
  rsync -a --exclude=config --rsync-path="sudo -n rsync" \
    admin@192.168.0.221:/mnt/pithos/migration/desktop-home/.ssh/ /home/adam/.ssh/
  chown -R adam:users /home/adam/.ssh && chmod 700 /home/adam/.ssh
  ```

  Exclude `config`: home-manager owns it as a store symlink, and copying the
  staged one points it at a store path that no longer exists. Then
  `/run/current-system/bin/switch-to-configuration switch` and check
  `ls /run/agenix/` shows five secrets.

---

## 6. Restore

`restore-notes.md` on the NAS is authoritative; this is the summary.

### 6.0 The link is the whole schedule

Measure it before planning anything:

```sh
cat /sys/class/net/e*/speed   # on both machines
```

At **100 Mbit** (12.5 MB/s) the 1.165 TB of media alone is **~26 hours**, and
the whole restore ~31. At gigabit it is **~3 hours**. Both NICs are
gigabit-capable; the Archer C54's LAN ports are Fast Ethernet and the EAP211
bridge has three unused gigabit ports. Move both cables before the bulk copy —
it is the single largest factor in how long this takes.

### 6.1 The exclude file has a format trap

`rsync --exclude-from` treats a line as a comment **only when the line starts
with `#`**. A trailing comment becomes part of the pattern, so the pattern
silently matches nothing. The 2026-10-13 revision of `restore-exclude.txt` had
trailing comments on its five largest entries — `/art/INBOX`, `/immich`,
`/migration`, `/ix-applications`, `qbittorrent-downloads` — and every one was
inert. INBOX's 616 G would have gone onto a pool that cannot hold it. Verify
with a dry run and read the byte count, never the file:

```sh
rsync -n -aHAX --stats --exclude-from=... src/ dst/ | grep "Total file size"
```

Post-exclude the media is 1,164,661,534,322 bytes across 2,964 files — about
60% of the 1.81 T pool once the small datasets land.

### 6.2 Transfer per dataset, not the whole tree

`/pithos` itself is a plain directory on `rpool/root`; only the six children
are mounted datasets. A single `rsync /mnt/pithos/ /pithos/` therefore writes
`containers`, `lifedb`, `data`, `adams-home`, `media-test` and
`lifedb-datalevin` onto the **NVMe**, which is not where any of it belongs.
Copy each dataset to its own mountpoint instead.

```sh
# pull from the desktop; admin can sudo passwordlessly on the NAS
SSH='ssh -i /root/.ssh/id_ed25519'

# 1. the five small datasets  (~18 G)
for ds in episteme techne logseq prosopikos memories; do
  rsync -aHAX --rsync-path="sudo -n rsync" -e "$SSH" \
    admin@192.168.0.221:/mnt/pithos/$ds/ /pithos/$ds/
done

# 2. media  (1.165 TB — the long one; exclude paths are art-relative here)
rsync -aHAX --info=progress2 --rsync-path="sudo -n rsync" -e "$SSH" \
  --exclude-from=/root/exclude-art.txt \
  admin@192.168.0.221:/mnt/pithos/art/ /pithos/art/

# 3. home — do this early, it is what unlocks agenix
rsync -aHAX --rsync-path="sudo -n rsync" -e "$SSH" \
  admin@192.168.0.221:/mnt/pithos/migration/desktop-home/ /home/adam/

# 4. immich originals -> NVMe, not pithos
rsync -aHAX --rsync-path="sudo -n rsync" -e "$SSH" \
  admin@192.168.0.221:/mnt/pithos/immich/library/ /var/lib/immich/library/
rsync -aHAX --rsync-path="sudo -n rsync" -e "$SSH" \
  admin@192.168.0.221:/mnt/pithos/immich/video/ /var/lib/immich/video/

# 5. linkwarden archives
rsync -aHAX --rsync-path="sudo -n rsync" -e "$SSH" \
  admin@192.168.0.221:/mnt/pithos/migration/k3s-volumes/linkwarden-archives/ \
  /var/lib/linkwarden/

# 6. service state (~152 M) -> /var/lib/<service>, per service
#    emby 85M, sonarr 32M, postgres 16M, qbittorrent 7.5M, prowlarr 7.0M,
#    audiobookshelf 3.9M, all under containers/container-data/
```

### 6.3 Not covered by any of the above

The top-level directories that belong to no dataset, triaged 2026-10-13.
Nothing here is deleted on the NAS -- "dropped" means not copied forward, and
the wipe takes care of the rest.

Keep, filed after art lands:

| Source | Destination |
|---|---|
| `data/magic-the-gathering/` | `prosopikos/collections/magic-the-gathering/` |
| `data/my-health/weight/` minus `.clerk/cache` | `prosopikos/health/weight/` |
| `data/world-wide-web/my-bookmarks-feb-2024.html` | `episteme/bookmarks/` |
| `media-test/The Wind-Up Bird Chronicle.epub` | `art/literature/` |

`data/authentication/github-recovery-codes.txt` is already moved, to
`prosopikos/authentication/`, mode 600. It is plaintext recovery codes, so it
wants to end up in Bitwarden rather than living on a dataset indefinitely.

Dropped:

| Source | Why |
|---|---|
| `adams-home` | `.bashrc`/`.profile`/`.bash_logout` skeleton |
| `lifedb` | PG 16 cluster, 11 weight readings and 15 exercise rows, superseded |
| `lifedb-datalevin` | service dropped |
| `containers/dockge` | the compose manager is gone |
| `containers/stacks` | captured in `legacy-stack.md` |
| `containers/data/postgres` | stale PG 18 copy; the compose file used `container-data/postgres` |
| `containers/container-data/postgres` | PG 18, held only miniflux -- see below |

The MTG export is a personal inventory, not a card database: its columns are
Quantity, Condition, Date Added and Purchase Price across 2,750 rows.

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
