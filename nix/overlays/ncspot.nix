# ncspot, adjusted for this machine.
#
# Three changes. (1) and (2) always apply; (3) is opt-in via spotifyClientId.
#
# 1. Search page limit. This is the bug that makes search return nothing.
#    ncspot asks /v1/search for limit=50, but Spotify now caps that endpoint
#    at 10 and rejects anything higher with
#      400 {"error":{"status":400,"message":"Invalid limit"}}
#    ncspot's api_with_retry has no arm for 400, so it logs "unhandled api
#    error", returns None, and the search view renders an empty list with no
#    message. The library endpoints still accept limit=50, which is exactly
#    why the library loads while search stays blank.
#    See ncspot-search-page-limit.patch. This is an upstream bug, not a local
#    preference -- worth reporting to hrkfdn/ncspot.
#
# 2. No podcast search. Removes the Shows and Episodes tabs from the search
#    screen, which also drops a plain-text search from six concurrent Web API
#    requests to four. See ncspot-remove-podcast-search.patch.
#
# 3. Private OAuth app. IN USE -- flake.nix supplies spotifyClientId from the
#    private-nix input.
#
#    Why: upstream hardcodes one client id shared by every ncspot install,
#    and Spotify meters the Web API rate limit per application over a rolling
#    30-second window, so that one quota is contended by all of them. Measured
#    on the shared app, one session of normal use logged 28 HTTP 429s against
#    16 successes and 17 forced Retry-After sleeps of up to 29 seconds each.
#    Search worked but was unusably slow. On our own app it is immediate.
#
#    Accepted cost: a self-registered app is in Development Mode, and
#    Spotify's February 2026 changes (immediate for apps created after
#    2026-02-11, 2026-03-09 for older ones) restrict that mode. /v1/search is
#    capped at limit=10 -- handled by change (2)'s patch -- and these return
#    403 outright, so the corresponding ncspot features do not work:
#      GET /browse/categories        -> Browse tab
#      GET /browse/categories/{id}   -> Browse category playlists
#      GET /artists/{id}/top-tracks  -> artist view top tracks
#      POST /users/{id}/playlists    -> creating playlists
#      GET /browse/new-releases, GET /tracks and GET /artists (batch forms),
#      GET /me/tracks/contains, GET /markets
#    Extended Quota Mode apps are exempt, and ncspot's bundled app behaves as
#    though it has that exemption. We trade those features for a quota that
#    is actually usable.
#
#    Upstream builds its redirect URI from a random free port per login
#    attempt. We pin it, so exactly one redirect URI needs registering.
#
#    Preconditions:
#      - the app's registered redirect URI is exactly
#        http://127.0.0.1:<oauthRedirectPort>/login  (Spotify rejects
#        "localhost"; the numeric loopback is required)
#      - that port is free whenever the OAuth flow runs
#      - ~/.cache/ncspot/rspotify_token.json is deleted, since its refresh
#        token is bound to the previous client id
{
  # Our own Spotify app's PKCE client id, supplied by the caller. flake.nix
  # reads it from private-nix at sources/ncspot/spotify-client-id, not from
  # this public repository: a client id is not a secret -- it travels in
  # plaintext in every OAuth redirect -- but anyone holding it can spend the
  # quota, which is the only reason to register an app at all.
  #
  # null falls back to upstream's shared, heavily contended app. That is not
  # the intended configuration here, so it warns rather than passing silently.
  spotifyClientId ? null,
}:
let
  oauthRedirectPort = 8989;
in
final: prev: {
  # A null client id means private-nix did not supply one -- a missing file or
  # a stale flake.lock -- and ncspot would silently drop back to upstream's
  # shared, rate-limited app. Say so rather than passing quietly.
  ncspot = prev.lib.warnIf (spotifyClientId == null)
    "overlays/ncspot.nix: spotifyClientId is null; expected it from private-nix at sources/ncspot/spotify-client-id. ncspot will use upstream's shared, heavily rate-limited app."
    (prev.ncspot.overrideAttrs (old: {
      # Order matters: the page-limit patch's hunks were generated against a
      # tree with the podcast patch already applied.
      patches = (old.patches or [ ]) ++ [
        ./ncspot-remove-podcast-search.patch
        ./ncspot-search-page-limit.patch
      ];
    } // prev.lib.optionalAttrs (spotifyClientId != null) {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace src/authentication.rs \
          --replace-fail 'd420a117a32841c2b3474932e49fb54b' '${spotifyClientId}' \
          --replace-fail 'find_free_port().expect("Could not find free port")' '${toString oauthRedirectPort}u16'
      '';
    }));
}
