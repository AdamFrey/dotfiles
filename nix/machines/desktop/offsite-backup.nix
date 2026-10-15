{ config, pkgs, inputs, ... }:

# Encrypted offsite backup to a Hetzner Storage Box, over borg.

let
  storageBoxUser = inputs.private-nix.storageBox.user;

  # One repository per host, so a second machine can be added without
  # entangling retention.
  repository = "ssh://${storageBoxUser}@${storageBoxUser}.your-storagebox.de:23/./borg/matte-black-cadillac";
in
{
  # secrets/borg-repokey-export.age is deliberately NOT declared here. The
  # repository uses repokey mode, so its encryption key lives inside the repo
  # -- lose the repo and the key goes with it, leaving any recovered chunks
  # undecryptable. That export is the independent copy, and it is disaster
  # material for a human, never needed at runtime. Declaring it would decrypt
  # it into /run/agenix on every boot for no reason.
  #   restore with: age -d -i ~/.ssh/id_ed25519 secrets/borg-repokey-export.age
  #                 borg key import <repo> <file>

  age.secrets.borg-repo-passphrase.file = ../../secrets/borg-repo-passphrase.age;
  age.secrets.healthchecks-ping-url.file = ../../secrets/healthchecks-ping-url.age;

  age.secrets.borg-storagebox-key = {
    file = ../../secrets/borg-storagebox-key.age;
    mode = "0400";
  };

  services.borgbackup.jobs.offsite = {
    repo = repository;
    paths = [
      "/home/adam"

      # pithos, except art
      "/pithos/prosopikos"
      "/pithos/episteme"
      "/pithos/techne"
      "/pithos/memories"
      "/pithos/logseq"

      # immich originals. thumbs and video are regenerated from these.
      "/var/lib/immich/library"
      "/var/lib/immich/upload"

      # pg_dump output
      "/var/backup/postgresql"

      "/var/lib/linkwarden"

      # The *arr stack keeps indexers, download clients and root folders in
      # its own databases, which nix cannot declare. Backing them up is what
      # makes the wiring reproducible.
      "/var/lib/sonarr"
      "/var/lib/prowlarr"
      "/var/lib/audiobookshelf"
      "/var/lib/emby"
    ];

    # Rebuildable, machine-local, or enormous-and-replaceable.
    exclude = [
      "/home/adam/.cache"
      "/home/adam/.local/share/Trash"
      "/home/adam/.local/share/containers"
      "/home/adam/nas"          # NFS automounts -- walking these pulls the NAS through
      "/home/adam/src/*/target" # build output
      "/home/adam/src/*/result" # nix build symlinks
      "**/node_modules"
      "**/.direnv"

      # Language package caches.
      "/home/adam/.m2"
      "/home/adam/.npm"
      "/home/adam/.cargo"

      # Tool indexes, regenerated on first use. These are not caught by the
      # /home/adam/.cache rule above -- they live inside project trees.
      "**/.clj-kondo/.cache"
      "**/.lsp/.cache"

      # Doom's clone plus its compiled elisp. x-os-rebuild recreates the
      # checkout and the real configuration lives in sources/doom/*.el.
      "/home/adam/.config/emacs"

      "/home/adam/.gitlibs"        # clojure git deps, re-fetched on demand
      "/home/adam/.migration-logs" # transient, from the 2026-10 consolidation
      "**/GPUCache"                # electron and chromium
    ];

    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat ${config.age.secrets.borg-repo-passphrase.path}";
    };

    environment = {
      # Port 23, and pin the server-side borg to match the 1.4.x client in
      # nixpkgs -- the Storage Box defaults to 1.2 otherwise.
      BORG_RSH = "ssh -p 23 -i ${config.age.secrets.borg-storagebox-key.path}";
      BORG_REMOTE_PATH = "borg-1.4";
    };

    # The repository is created once, by hand.
    doInit = false;

    compression = "zstd,3";
    startAt = "daily";
    persistentTimer = true; # catch up after the machine was off

    # The module runs `compact` after `prune`, so space is actually reclaimed.
    prune.keep = {
      daily = 7;
      weekly = 4;
      monthly = 6;
    };

    # Runs on every exit, success or not; $exitStatus is the job's result.
    postHook = ''
      # Dead-man's switch. healthchecks.io alerts when pings stop arriving,
      # which is the only way a machine that is off, dead or stolen gets
      # noticed -- nothing running here can report its own absence.
      #
      # Never fails the job: a backup that succeeded but could not phone home
      # is still a backup, and the missing ping raises the alarm anyway.
      ping=$(cat ${config.age.secrets.healthchecks-ping-url.path})
      if [ "$exitStatus" != 0 ]; then
        ping="$ping/fail"
      fi
      curl -fsS -m 10 --retry 5 -o /dev/null "$ping" || true
    '';
  };

  systemd.services.borgbackup-job-offsite.path = [ pkgs.curl ];

  # Dumps rather than the live data directory, which is not consistent when
  # copied. Scheduled before the 00:00 borg run so each archive carries that
  # night's dump.
  services.postgresqlBackup = {
    enable = true;
    startAt = "23:45";
    location = "/var/backup/postgresql";
  };
}
