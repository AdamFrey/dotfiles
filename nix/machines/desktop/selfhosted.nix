{ config, lib, pkgs, pkgs-unstable, inputs, ... }:

# The household services, run natively rather than as containers.

let
  media = "/pithos/art";

  # Must sit inside the pithos/art dataset; see the tmpfiles rule below.
  downloadInbox = "${media}/.bittorrent-downloads";

  # Opening a port here also opens it to the tailnet.
  lanPorts = {
    emby = 8096;
    immich = 2283;
    audiobookshelf = 8000;
  };

  # Admin surfaces and personal data.
  tailnetPorts = {
    sonarr = 8989;
    prowlarr = 9696;
    qbittorrent = 8080;
    miniflux = 8081;
    linkwarden = 3000;
    hashcards = 8082;
  };

  port = lanPorts // tailnetPorts;

  hashcards = pkgs.callPackage ../../packages/hashcards { };

  hashcardsLauncher = pkgs.callPackage
    "${inputs.polyrepo}/projects/hashcards-launcher/package.nix"
    { babashka = pkgs-unstable.babashka; };

  # The drill sessions listen here. Loopback only: the launcher forwards to it.
  hashcardsDrillPort = 8083;

  hashcardsLauncherConfig = pkgs.writeText "hashcards-launcher.edn" ''
    {:afrey.hashcards-launcher/drill-session
     {:hashcards-bin "${hashcards}/bin/hashcards"
      :port          ${toString hashcardsDrillPort}
      :card-limit    60
      :collections   [{:name "Flashcards"
                       :dir  "/pithos/prosopikos/hashcards/decks"}]}

     :afrey.hashcards-launcher/http-server
     {:host          "0.0.0.0"
      :port          ${toString port.hashcards}
      :drill-session #ig/ref :afrey.hashcards-launcher/drill-session}}
  '';
in
{
  # One cluster. immich and miniflux attach to it rather than running their
  # own, and `CREATE DATABASE` stays available for whatever comes later.
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
  };

  services.immich = {
    enable = true;
    # 26.05 ships immich 2.7.5, which nixpkgs marks insecure (CVE-2026-59258,
    # CVE-2026-82272). Unstable carries 3.2.2 unflagged. Same pattern the repo
    # already uses for bbin and friends.
    package = pkgs-unstable.immich;
    port = port.immich;
    # Defaults to localhost, which makes the lanPorts firewall hole useless.
    host = "0.0.0.0";
    mediaLocation = "/var/lib/immich";
    machine-learning.enable = true;
    database.createDB = true;
  };

  services.miniflux = {
    enable = true;
    createDatabaseLocally = true;
    adminCredentialsFile = config.age.secrets.miniflux-admin.path;
    config.LISTEN_ADDR = "0.0.0.0:${toString port.miniflux}";
  };

  # Rescued from the old k3s apps system. Its 3.7 GiB of page archives are
  # named by row id -- 1023.png, 652.pdf -- so they are unreadable without
  # the database that maps them back to URLs. The app is what makes the data
  # mean anything.
  services.linkwarden = {
    enable = true;
    host = "0.0.0.0";
    port = port.linkwarden;
    storageLocation = "/var/lib/linkwarden";
    database.createLocally = true;
    secretFiles.NEXTAUTH_SECRET = config.age.secrets.linkwarden-nextauth.path;
  };

  services.audiobookshelf = {
    # Defaults to 127.0.0.1, which makes the lanPorts firewall hole useless.
    host = "0.0.0.0";
    enable = true;
    port = port.audiobookshelf;
  };

  # Starts hashcards drill sessions from any device on the tailnet. The source
  # is projects/hashcards-launcher in the polyrepo flake input. To ship a
  # change, push the polyrepo, then run `nix flake update polyrepo`.
  systemd.services.hashcards-launcher = {
    description = "hashcards drill launcher";
    wantedBy = [ "multi-user.target" ];
    unitConfig.RequiresMountsFor = [ "/pithos/prosopikos" ];
    # git pulls the collection before each session.
    path = [ pkgs.git pkgs.openssh ];
    serviceConfig = {
      User = "adam";
      ExecStart = "${hashcardsLauncher}/bin/hashcards-launcher ${hashcardsLauncherConfig}";
      Restart = "on-failure";
      # The default 100 ms gives up after five quick failures.
      RestartSec = 10;
    };
  };

  services.sonarr.enable = true;
  services.prowlarr.enable = true;

  users.users.prowlarr = {
    isSystemUser = true;
    group = "prowlarr";
    home = "/var/lib/prowlarr";
  };
  users.groups.prowlarr = { };
  systemd.services.prowlarr.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "prowlarr";
    Group = "prowlarr";
    StateDirectory = "prowlarr";
  };

  services.qbittorrent = {
    enable = true;
    webuiPort = port.qbittorrent;
    serverConfig = {
      # qbittorrent-nox blocks on first run without this.
      LegalNotice.Accepted = true;
      Preferences.WebUI.Username = "adam";
      Preferences.WebUI.Password_PBKDF2 = inputs.private-nix.qbittorrent.webuiPasswordHash;

      # Skip auth for connections from the machine itself, so the torrents
      # can be managed by script. Reaching localhost already means shell
      # access here, and the WebUI port is tailnet-only.
      Preferences.WebUI.LocalHostAuth = false;
      BitTorrent.Session.DefaultSavePath = downloadInbox;
      BitTorrent.Session.TempPathEnabled = false;
    };
  };

  # Sonarr hardlinks imports rather than copying.
  #
  # fs.protected_hardlinks is 1, so sonarr may only link files it can read
  # AND write. Hence the shared group, the setgid bit, and qbittorrent's
  # UMask below -- without all three, imports silently fall back to copying.
  users.groups.media = { };
  users.users.qbittorrent.extraGroups = [ "media" ];
  users.users.sonarr.extraGroups = [ "media" ];
  users.users.adam.extraGroups = [ "media" ];
  users.users.audiobookshelf.extraGroups = [ "media" ];
  systemd.services.qbittorrent.serviceConfig.UMask = "0002";

  systemd.tmpfiles.rules = [
    # setgid: downloads inherit the media group so sonarr can link them.
    "d ${downloadInbox} 2775 qbittorrent media -"

    # podman will not create a bind-mount source, and a container has no
    # StateDirectory= to do it instead. 1000 is the uid emby runs as below.
    "d /var/lib/emby 0750 1000 100 -"
  ];

  virtualisation.oci-containers.containers.emby = {
    image = "emby/embyserver:latest";
    ports = [ "${toString port.emby}:8096" ];
    volumes = [
      "/var/lib/emby:/config"

      "${media}:${media}:ro"
    ];
    environment.UID = "1000";

    # Use the GPU for tanscoding
    devices = [ "/dev/dri:/dev/dri" ];
  };

  age.secrets.miniflux-admin.file = ../../secrets/miniflux-admin.age;

  age.secrets.linkwarden-nextauth = {
    file = ../../secrets/linkwarden-nextauth.age;
    owner = "linkwarden";
  };

  networking.firewall = {
    allowedTCPPorts = builtins.attrValues lanPorts;

    # Emby clients find the server by broadcast rather than by typed address.
    allowedUDPPorts = [ 7359 ];

    interfaces."tailscale0".allowedTCPPorts = builtins.attrValues tailnetPorts;
  };
}
