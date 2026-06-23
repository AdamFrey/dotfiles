{ lib
, fetchFromGitHub
, rustPlatform
, pkg-config
, openssl
, clang
, mold
}:

rustPlatform.buildRustPackage rec {
  pname = "dirge";
  version = "0.2.3";

  src = fetchFromGitHub {
    owner = "dirge-code";
    repo = "dirge";
    rev = "v${version}";
    hash = "sha256-uHIWUmnT0WCuwHOp2QQX6SiEpaDi7RmGOeKWB6TzIKM=";
  };

  cargoHash = "sha256-Lyt7jsUo9K4UqKqiKsBz6cMWhOMGFNlngEgBGqxQ9Bk=";

  nativeBuildInputs = [ pkg-config rustPlatform.bindgenHook clang mold ];
  buildInputs = [ openssl ];

  doCheck = false;

  meta = with lib; {
    description = "Dynamic Intent Resolution Grounding Engine — minimalistic coding agent in Rust";
    homepage = "https://github.com/dirge-code/dirge";
    license = licenses.gpl3Only;
    platforms = platforms.unix;
    mainProgram = "dirge";
  };
}
