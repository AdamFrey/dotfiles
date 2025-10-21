{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "beads";
  version = "0.9.11";

  src = fetchFromGitHub {
    owner = "steveyegge";
    repo = "beads";
    rev = "01aeed6997ec7c4cc014f72ad8dde98dd0f6d11a";
    hash = "sha256-opsWmeXzPwTihnTEhWboSginYM0XvFGwtnr6MS974qs=";
  };

  vendorHash = "sha256-9xtp1ZG7aYXatz02PDTmSRXwBDaW0kM7AMQa1RUau4U=";

  # Enable CGO for C bindings
  env.CGO_ENABLED = 1;

  # Skip tests that require filesystem access not available in Nix sandbox
  doCheck = false;

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
