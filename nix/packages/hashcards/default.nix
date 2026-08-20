{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, pkg-config
, openssl
}:

rustPlatform.buildRustPackage rec {
  pname = "hashcards";
  version = "05-16-2026";

  src = fetchFromGitHub {
    owner = "eudoxia0";
    repo = "hashcards";
    rev = "3d45bf5a345599fc937c66d9ee7fd143a3aab5fc";
    sha256 = "sha256-zMJ/noq0FRcSzU5yj6I604Gv7z1kjB1dtQgr++sNyTc=";
  };

  cargoHash = "sha256-kH1rRYngqsPEyT+kGAaPbLYm3lSBefqsTCcDlxQGXEA=";

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
