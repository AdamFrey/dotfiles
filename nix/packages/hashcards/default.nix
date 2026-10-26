{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, pkg-config
, openssl
}:

rustPlatform.buildRustPackage rec {
  pname = "hashcards";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "eudoxia0";
    repo = "hashcards";
    rev = "v${version}";
    sha256 = "sha256-XX3j5ljOpyIxFJq3NPAM7ZPGoc33BH0bGOFMzJJ7XEg=";
  };

  cargoHash = "sha256-CK4k8etB4MZUkJWk/OabuBuIN+AkT/GulsYS1Qa7NVE=";

  doCheck = false;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  meta = with lib; {
    description = "A plain text-based spaced repetition system";
    longDescription = ''
      Hashcards is a spaced repetition system that stores flashcards in plain text files.
      It features content-addressable cards, low-friction card creation, simple card types
      (front-back and cloze), and uses the FSRS algorithm for efficient review scheduling.
    '';
    homepage = "https://github.com/eudoxia0/hashcards";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    platforms = platforms.unix;
    mainProgram = "hashcards";
  };
}
