# Reinstalling matte-black-cadillac onto ZFS

The desktop is being rebuilt from ext4 onto two single-disk ZFS pools as part
of folding the TrueNAS box into it. This is the procedure.

ZFS root cannot be set up the way `nix/README.md` describes for a new machine.
`nixos-generate-config` *describes* pools; it does not create them. Everything
in section 3 happens by hand, before `nixos-install` runs.

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
| You have a NixOS installer USB | 26.05 or newer, so the ZFS in the installer matches |

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

## 3. Create the pools

Boot the installer. Identify disks by `/dev/disk/by-id/` rather than `sda` —
kernel names are not stable across boots.

### 3.1 Partition the NVMe

1 GiB ESP plus the rest for ZFS. **The current ESP is 512 MiB and sits at 83%
full**, which leaves no room for more than a couple of generations; 1 GiB
avoids that.

```sh
DISK=/dev/disk/by-id/nvme-Lexar_SSD_NM790_2TB_...   # tab-complete the real one
sgdisk --zap-all "$DISK"
sgdisk -n1:1M:+1G  -t1:EF00 -c1:ESP   "$DISK"
sgdisk -n2:0:0     -t2:BF00 -c2:rpool "$DISK"
partprobe "$DISK"
mkfs.vfat -F32 -n ESP "${DISK}-part1"
```

### 3.2 Create `rpool`

```sh
zpool create -f \
  -o ashift=12 \
  -O compression=zstd \
  -O atime=off \
  -O xattr=sa -O acltype=posixacl \
  -O mountpoint=none \
  rpool "${DISK}-part2"
```

`xattr=sa` and `acltype=posixacl` are not optional — systemd and journald
need them, and adding them after the fact does not fix already-written files.

### 3.3 Create the rpool datasets

The names are fixed by `zfs.nix`, which snapshots `rpool/home`,
`rpool/var/lib/postgresql` and `rpool/var/lib/immich` by name.

```sh
zfs create -o mountpoint=legacy rpool/root
zfs create -o mountpoint=legacy rpool/nix
zfs create -o mountpoint=legacy rpool/home

zfs create -o canmount=off -o mountpoint=none rpool/var
zfs create -o canmount=off -o mountpoint=none rpool/var/lib
zfs create -o mountpoint=legacy rpool/var/lib/postgresql
zfs create -o mountpoint=legacy rpool/var/lib/immich
zfs create -o mountpoint=legacy rpool/var/lib/linkwarden
```

### 3.4 Create `pithos` on the spinning disk

Dataset names mirror the NAS so the laptops' NFS paths do not change.

```sh
HDD=/dev/disk/by-id/ata-WDC_WD20EZAZ-...        # tab-complete the real one
sgdisk --zap-all "$HDD"
sgdisk -n1:0:0 -t1:BF00 -c1:pithos "$HDD"
partprobe "$HDD"

zpool create -f \
  -o ashift=12 \
  -O compression=zstd \
  -O atime=off \
  -O xattr=sa -O acltype=posixacl \
  -O mountpoint=none \
  pithos "${HDD}-part1"

for d in art episteme techne memories logseq prosopikos; do
  zfs create -o mountpoint=legacy "pithos/$d"
done
```

**`recordsize` is left at the default.** Raising it to 1M suits large media
and would reduce metadata on an SMR disk, but it is not reversible for
already-written data, and the default is adequate. Decide before copying
1.1 TB, not after.

---

## 4. Install

```sh
mount -t zfs rpool/root /mnt
mkdir -p /mnt/{boot,nix,home,var/lib/{postgresql,immich,linkwarden},pithos/{art,episteme,techne,memories,logseq,prosopikos}}
mount "${DISK}-part1" /mnt/boot
mount -t zfs rpool/nix  /mnt/nix
mount -t zfs rpool/home /mnt/home
for d in postgresql immich linkwarden; do mount -t zfs "rpool/var/lib/$d" "/mnt/var/lib/$d"; done
for d in art episteme techne memories logseq prosopikos; do mount -t zfs "pithos/$d" "/mnt/pithos/$d"; done

nixos-generate-config --root /mnt
```

Then, **before installing**:

1. Copy the generated `/mnt/etc/nixos/hardware-configuration.nix` over
   `nix/desktop-hardware-configuration.nix` in the repo.
2. Add the three modules to `desktop.nix`:
   `imports = [ ./zfs.nix ./selfhosted.nix ./ollama.nix ./offsite-backup.nix ];`
3. Commit and push, so the installer can fetch the flake.

```sh
nixos-install --flake github:AdamFrey/dotfiles?dir=nix#desktop
```

**`networking.hostId` must survive.** `zfs.nix` pins it to `8f3a1c7e`; if the
generated config sets a different one, the pools will need `-f` on every
import. Check before installing.

---

## 5. First boot, before restoring anything

| Check | Expected |
|---|---|
| `zpool status` | both pools ONLINE |
| `zfs list` | all datasets mounted where section 3 put them |
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
