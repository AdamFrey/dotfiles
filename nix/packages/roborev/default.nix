{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "roborev";
  version = "0.61.0";

  src = fetchFromGitHub {
    owner = "kenn-io";
    repo = "roborev";
    rev = "v${version}";
    hash = "sha256-fa/lToln99LgG2rTHL7je7kO6qOT6LX52JIKgI5pVO4=";
  };

  vendorHash = "sha256-nc2lw0qKnGRNbpz+kt8262Ot9wJJ6Kl+5jSEtjXdpMc=";

  subPackages = [ "cmd/roborev" ];

  ldflags = [
    "-s"
    "-w"
    "-X go.kenn.io/roborev/internal/version.Version=v${version}"
  ];

  doCheck = false;

  meta = with lib; {
    description = "AI-powered code review tool";
    homepage = "https://github.com/kenn-io/roborev";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "roborev";
  };
}
