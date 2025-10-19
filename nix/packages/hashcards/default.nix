{ lib
, stdenv
, fetchFromGitHub
, rustPlatform
, pkg-config
, openssl
}:

rustPlatform.buildRustPackage rec {
  pname = "hashcards";
  version = "10-111-2025";

  src = fetchFromGitHub {
    owner = "eudoxia0";
    repo = "hashcards";
    rev = "ef6d4e70c7108a07edb88b34170d4ecb6d115dc7";
    sha256 = "sha256-h3MQxcHdvkL3FQArvoYj+YACnyBNzFF//lZZl6dokUU=";
  };

  cargoHash = "sha256-2Rzc30QVDTsSEk3DLxqvPFN/Bu++1WVXFDMmvFCUAdU=";

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
