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
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "dirge-code";
    repo = "dirge";
    rev = "v${version}";
    hash = "sha256-iioljMOhmCC0z1bzBfTt1/oIkHsmhKoN0j1Ph+4dwbk=";
  };

  cargoHash = "sha256-JqS6AuYcTM0odeHMLFMZYaeti+aqWWduBAlhH8JUDg8=";

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
