# The docker-compose stack this machine replaced

Salvaged from `pithos/containers/stacks/` on the TrueNAS box before it was
wiped. The compose files themselves are superseded by `selfhosted.nix`; what
is recorded here is the part that still has consequences.

## Everything ran as uid/gid 568

Every container was given `PUID=568`/`PGID=568` (emby used `UID`/`GID`). The
restored service state under `containers/container-data/` is therefore owned
by 568, and the native services run as something else entirely:

| Service | Was | Now |
|---|---|---|
| sonarr | 568 | 274 |
| audiobookshelf | 568 | 999 |
| prowlarr | 568 | DynamicUser, `/var/lib/private/prowlarr` |
| emby | 568 | 1000 (container `UID`) |
| qbittorrent | 568 | `qbittorrent` |

**Restoring that state without a `chown` leaves every service unable to read
its own config.** Chown to the uid that already owns the destination state
directory rather than to 568.

## Clients pointed at the NAS need repointing before it is wiped

| Service | Was | Now |
|---|---|---|
| emby | 10079 | 8096 |
| miniflux | 5002 | 8081 |
| qbittorrent | 5003 | 8080 |
| audiobookshelf | 5005 | 8000 |
| sonarr | 8989 | 8989 |
| prowlarr | 9696 | 9696 |
| grampsweb | 5004 | dropped |
| datalevin | 8898 | dropped |

## emby had GPU passthrough and no longer does

The old container carried `devices: [/dev/dri:/dev/dri]`. The current one in
`selfhosted.nix` does not, so transcoding is CPU-only. The hardware is still
there -- `/dev/dri/card1` and `renderD128` on the Polaris card. Restoring it
is one line, if transcoding turns out to matter.

## The old Postgres was 18, the new one is 17

`containers/container-data/postgres` is a **PostgreSQL 18** cluster;
`services.postgresql` runs 17. That direction is a downgrade, so there is no
`pg_upgrade` path: dumping it needs PG 18 binaries, and the dump only restores
into 17 if nothing 18-only was used. Relevant if anything in that cluster is
still wanted -- miniflux was its main tenant and is being set up fresh.

Two other clusters are in the same family of problem: `immich/pgData`, and
`k3s-volumes/linkwarden-pgdata` at PG 16.

## What each service could see

Worth keeping because it records the intended media layout, which the bind
mounts in `selfhosted.nix` have to match:

- emby: `art/movies`, `art/tv`, `art/music-recordings`, all read-only
- sonarr: `art/tv` plus the qbittorrent download staging
- audiobookshelf: all of `art`
- qbittorrent: `art`, `episteme`, `techne`, plus its own downloads

## Credentials that lived in those `.env` files

`postgres/.env` held `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DATABASES`;
`miniflux/.env` held `MINIFLUX_DB_PASSWORD`, `ADMIN_USERNAME`, `ADMIN_PASSWORD`.
Nothing here is carried forward -- the native services use agenix secrets. Noted
only so that a password reused elsewhere is known to have been sitting in
plaintext on the NAS.
