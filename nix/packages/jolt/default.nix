{ lib
, stdenv
, fetchFromGitHub
, chez
, xxd
, lz4
, zlib
, ncurses
, libuuid
, openssl
, patchelf
, makeWrapper
, git
, unzip
}:

stdenv.mkDerivation rec {
  pname = "jolt";
  version = "0.6.8";

  src = fetchFromGitHub {
    owner = "jolt-lang";
    repo = "jolt";
    rev = "v${version}";
    # vendor/irregex, fs, process and grenadine are compiled into the binary;
    # sci and clojure-test-suite come along but are only used for tests
    fetchSubmodules = true;
    hash = "sha256-MN5vK3SXXpAa0zzk5BT9s9TO30vgN4t/9c3gjx95xSY=";
  };

  # Upstream's `make build` git-clones makeplus/makes at Makefile parse time, so
  # it can't run in the sandbox. Drive the same script make would (Makefile:248).
  nativeBuildInputs = [ chez xxd patchelf makeWrapper ];
  buildInputs = [ lz4 zlib ncurses libuuid ];

  # stdlib/jolt/mvn_http.clj dlopens libcrypto.so.3/libssl.so.3 by bare soname
  # for dependency fetching, so OpenSSL is never a DT_NEEDED entry and listing it
  # in buildInputs earns no -rpath. Add one by hand at the launcher-stub link:
  # build-jolt.ss embeds that stub into every binary `jolt build` produces, so the
  # entry reaches those too. Without it, every maven/clojars fetch fails.
  NIX_LDFLAGS = "-rpath ${lib.getLib openssl}/lib";

  # fixupPhase's `patchelf --shrink-rpath` drops rpath entries no DT_NEEDED
  # library resolves through — which is exactly the dlopen-only entry above.
  dontPatchELF = true;

  # build-jolt.ss derives the version from `git describe` when JOLT_VERSION is
  # unset; the fetched source has no .git, which would bake in "dev".
  JOLT_VERSION = "v${version}";

  buildPhase = ''
    runHook preBuild
    scheme --script host/chez/build-jolt.ss release target/release/jolt
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 target/release/jolt $out/bin/jolt

    # jolt-core/jolt/deps.clj shells out to `unzip` to extract jars and to `git`
    # for :git/url deps, resolving both off PATH. Suffix rather than prefix, so a
    # caller's own git still wins — git deps read the user's git config.
    wrapProgram $out/bin/jolt --suffix PATH : ${lib.makeBinPath [ git unzip ]}

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/jolt --version | grep -q "v${version}"
    [ "$($out/bin/jolt -e '(+ 1 2)')" = "3" ]
    # The sandbox has no network, so assert the two dependencies jolt resolves
    # outside the derivation are still reachable, rather than fetching anything.
    # wrapProgram moved the ELF aside, so the rpath check follows it there;
    # grepping for the path would false-pass, since the embedded launcher stub
    # carries it as a string even when the rpath itself is gone.
    patchelf --print-rpath $out/bin/.jolt-wrapped | grep -q "${lib.getLib openssl}/lib"
    grep -q "${git}/bin" $out/bin/jolt
    grep -q "${unzip}/bin" $out/bin/jolt
    runHook postInstallCheck
  '';

  meta = with lib; {
    description = "Clojure dialect that compiles to a self-contained Chez Scheme binary";
    homepage = "https://github.com/jolt-lang/jolt";
    license = licenses.epl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "jolt";
  };
}
