<!--
Draft bug report for hrkfdn/ncspot, following the project's issue template.
Documents the defect worked around locally by ncspot-search-page-limit.patch.

SCOPE NOTE (read before posting): Spotify's February 2026 changes apply only to
Development Mode apps. ncspot's bundled client id appears to be in Extended
Quota Mode, so a default install is NOT affected. This report matters for
anyone running ncspot against their own registered client id, and the silent
error handling it exposes is a defect regardless.

Before posting:
  - confirm the Terminal line below
  - do NOT attach ~/inbox/ncspot-debug-1.log as-is: 134 of its lines contain a
    full plaintext Bearer access token (201 lines carry an authorization
    header). The excerpt quoted below is token-free. The log contains no
    refresh token and no client id.
-->

**Describe the bug**

Two related problems, one of which is a defect independent of any Spotify account configuration.

**1. Unhandled `400` responses are silently swallowed.** `api_with_retry` in `src/spotify_api.rs` has arms for `429` (line 126) and `401` (line 134) but none for `400`. A `400` falls through to `_ =>` (line 139), which logs `unhandled api error` and returns `None`. `WebApi::search` maps that to `Err(())` and the search view renders an empty list. To the user, a hard API rejection is indistinguishable from "no matches" — nothing appears in the UI, and the cause is only visible with `-d`.

**2. The hardcoded search page size is above the Development Mode cap.** ncspot requests `limit=50` from `/v1/search`. Spotify's [February 2026 Web API changes](https://developer.spotify.com/documentation/web-api/references/changes/february-2026) reduced that endpoint's maximum to 10 for Development Mode apps, and anything higher is rejected:

```json
{"error": {"status": 400, "message": "Invalid limit"}}
```

Combined, these mean search returns nothing with no error shown, while library, playlists and queue continue to load normally (the `/me/*` endpoints are unaffected by the limit change).

**Scope:** per the [migration guide](https://developer.spotify.com/documentation/web-api/tutorials/february-2026-migration-guide), *"Apps in extended quota mode are not affected by any of the changes described in this guide."* So this does not affect a default install using ncspot's bundled client id. It affects builds pointed at a self-registered client id, which is Development Mode by default.

**To Reproduce**

Steps to reproduce the behavior:
1. Build ncspot with `NCSPOT_CLIENT_ID` replaced by a self-registered Spotify app's client id (Development Mode)
2. Start ncspot with debug logging: `ncspot -d /tmp/ncspot.log`
3. Press `/`, type any query (e.g. `MIA`), press Enter
4. No results appear in any tab, and no error is shown; the log contains one `400 Bad Request` per search type

The API behaviour can be confirmed independently with a Development Mode app's user access token:

```sh
curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $TOKEN" \
  'https://api.spotify.com/v1/search?q=MIA&type=track&limit=50'   # 400
curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $TOKEN" \
  'https://api.spotify.com/v1/search?q=MIA&type=track&limit=10'   # 200
```

The boundary sits exactly at 10: `limit=10` returns `200`, `limit=11` returns `400`.

**Expected behavior**

Searching returns results in the Tracks, Albums, Artists and Playlists tabs.

Independently of the page size: an API error ncspot cannot handle should be surfaced in the UI rather than rendered as an empty result set.

**Screenshots**

Not applicable — the search screen renders correctly, it is simply empty.

**System (please complete the following information):**
 - OS: Linux (NixOS 26.05)
 - Terminal: kitty
 - Version: 1.4.0
 - Installed from: nixpkgs (nixos-unstable), patched to use a self-registered client id

**Backtrace/Debug log**

ncspot did not crash, so there is no backtrace. Relevant debug log lines, showing search failing while a library call in the same second succeeds:

```
[2026-09-04][16:10:51] [ureq::unit] [DEBUG] response 400 to GET https://api.spotify.com/v1/search?type=playlist&q=MIA&limit=50&market=from_token&offset=0
[2026-09-04][16:10:51] [ncspot::spotify_api] [DEBUG] http error: StatusCode(Response[status: 400, status_text: Bad Request, url: https://api.spotify.com/v1/search?type=playlist&q=MIA&limit=50&market=from_token&offset=0])
[2026-09-04][16:10:51] [ncspot::spotify_api] [ERROR] unhandled api error: Response[status: 400, status_text: Bad Request, url: https://api.spotify.com/v1/search?type=playlist&q=MIA&limit=50&market=from_token&offset=0]
[2026-09-04][16:10:51] [ureq::unit] [DEBUG] response 400 to GET https://api.spotify.com/v1/search?q=MIA&type=track&market=from_token&offset=0&limit=50
[2026-09-04][16:10:51] [ureq::unit] [DEBUG] response 400 to GET https://api.spotify.com/v1/search?offset=0&limit=50&type=artist&market=from_token&q=MIA
[2026-09-04][16:10:51] [ureq::unit] [DEBUG] response 400 to GET https://api.spotify.com/v1/search?market=from_token&q=MIA&type=album&offset=0&limit=50
[2026-09-04][16:10:51] [ureq::unit] [DEBUG] response 200 to GET https://api.spotify.com/v1/me/albums?limit=50&offset=250&market=from_token
```

**Additional context**

Six call sites in `src/ui/search_results.rs` pass the literal `50` (line numbers from tag `v1.4.0`):

| line | call |
|---|---|
| 132 | `.search(SearchType::Track, query, 50, offset as u32)` |
| 173 | `.search(SearchType::Album, query, 50, offset as u32)` |
| 214 | `.search(SearchType::Artist, query, 50, offset as u32)` |
| 255 | `.search(SearchType::Playlist, query, 50, offset as u32)` |
| 296 | `.search(SearchType::Show, query, 50, offset as u32)` |
| 337 | `.search(SearchType::Episode, query, 50, offset as u32)` |

A named constant capped at the Development Mode maximum restores search, and stays valid for Extended Quota apps since 10 is within their allowance too:

```rust
/// Page size for `/v1/search` requests. Spotify caps `limit` on the search
/// endpoint at 10 for Development Mode apps and rejects anything higher with
/// `400 {"error":{"status":400,"message":"Invalid limit"}}`.
const SEARCH_PAGE_LIMIT: u32 = 10;
```

`offset` still accepts `0..1000`, so pagination is unaffected other than page size.

For context on the wider blast radius if ncspot's bundled app were ever moved out of Extended Quota Mode, these endpoints return `403` for a Development Mode app (measured, not inferred): `GET /browse/categories`, `GET /browse/new-releases`, `GET /tracks` and `GET /artists` (batch forms), `GET /me/tracks/contains`, `GET /artists/{id}/top-tracks`, and `GET /markets`. The single-object forms such as `GET /tracks/{id}` still work, as do `GET /me/tracks`, `GET /me/albums` and `GET /me/playlists`.
