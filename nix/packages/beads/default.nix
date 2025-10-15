{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "beads";
  version = "unstable-2024-10-15";

  src = fetchFromGitHub {
    owner = "steveyegge";
    repo = "beads";
    rev = "953858b853bb9d477215966665851406eccb8183";
    hash = "sha256-AAZed/mI/0mVRaQO+PsTzOSrWnmfSAi+eQcEFSywv/o=";
  };

  vendorHash = "sha256-WvwT48izxMxx9qQmZp/6zwv7hHgTVd9KmOJFm7RWvrI=";

  # Enable CGO for C bindings
  env.CGO_ENABLED = 1;

  # Build only the bd binary from cmd/bd subdirectory
  subPackages = [ "cmd/bd" ];

  # Version information injected at build time
  ldflags = [
    "-linkmode=external"
    "-X main.version=${version}"
  ];

  # Optional: create both 'bd' and 'beads' commands
  # postInstall = ''
  #   ln -s $out/bin/bd $out/bin/beads
  # '';

  meta = with lib; {
    description = "A memory upgrade for your coding agent";
    longDescription = ''
      Beads is a tool that provides memory and context management
      for coding agents, helping them maintain state across sessions.
    '';
    homepage = "https://github.com/steveyegge/beads";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "bd";
    platforms = platforms.linux ++ platforms.darwin;
  };
}
