# Site blocking shared by Zen and Chrome.
#
# zen-policies.nix and browsers.nix import this file. Each block entry is
# written once here, and this file generates the syntax for each browser.
#
# An entry has these fields:
#   host   The entry also blocks every subdomain of the host. Required.
#   path   The entry blocks URLs whose path starts with this value. Optional.
#   query  One query parameter, as { name = "value"; }. Optional.
#
# Chrome cannot put a wildcard inside a host or a path. So this file has no
# google.* patterns.
let
  entries = [
    # Google Images and Lens. Regular search stays open.
    { host = "images.google.com"; }
    { host = "google.com"; path = "/search"; query = { tbm = "isch"; }; }
    { host = "google.com"; path = "/search"; query = { udm = "2"; }; }
    # The videos and short videos tabs of Google search. Google uses the
    # named values now. The numbers are older forms of the same tabs.
    { host = "google.com"; path = "/search"; query = { udm = "vids"; }; }
    { host = "google.com"; path = "/search"; query = { udm = "7"; }; }
    { host = "google.com"; path = "/search"; query = { tbm = "vid"; }; }
    { host = "google.com"; path = "/search"; query = { udm = "short_vids"; }; }
    { host = "google.com"; path = "/search"; query = { udm = "39"; }; }
    { host = "google.com"; path = "/imghp"; }
    { host = "lens.google.com"; }

    { host = "tiktok.com"; }
    { host = "x.com"; }
    { host = "twitter.com"; }
    { host = "reddit.com"; }
    { host = "youtube.com"; }
    # This prefix also matches /reels.
    { host = "facebook.com"; path = "/reel"; }
    { host = "tmz.com"; }
  ];

  # Work needs these URLs. Each path is the start of the path that the app
  # uses. Evaluation fails if an entry blocks one of these URLs.
  protectedUrls = [
    { host = "calendar.google.com"; path = "/calendar"; }
    { host = "meet.google.com"; path = "/"; }
    { host = "mail.google.com"; path = "/mail"; }
    { host = "accounts.google.com"; path = "/"; }
    { host = "docs.google.com"; path = "/"; }
    { host = "drive.google.com"; path = "/drive"; }
  ];

  hasPrefix = prefix: s:
    builtins.substring 0 (builtins.stringLength prefix) s == prefix;

  hasSuffix = suffix: s:
    let
      sl = builtins.stringLength suffix;
      l = builtins.stringLength s;
    in l >= sl && builtins.substring (l - sl) sl s == suffix;

  # An entry blocks a protected URL when both of these are true:
  #   - The entry host is the protected host or a parent domain of it.
  #   - The entry path is a prefix of the protected path. No path is the
  #     empty prefix, so it blocks every path.
  blocksProtectedUrl = entry: protected:
    (protected.host == entry.host || hasSuffix ".${entry.host}" protected.host)
    && hasPrefix (entry.path or "") protected.path;

  checkEntry = entry:
    let
      hits = builtins.filter (blocksProtectedUrl entry) protectedUrls;
      queryNames = builtins.attrNames (entry.query or { });
    in
    if hits != [ ] then
      let hit = builtins.head hits;
      in throw "browser-blocking.nix: the entry for ${entry.host}${entry.path or ""} blocks the protected URL ${hit.host}${hit.path}."
    else if builtins.length queryNames > 1 then
      throw "browser-blocking.nix: the entry for ${entry.host} has more than one query parameter."
    else
      entry;

  checkedEntries = map checkEntry entries;

  queryPair = entry:
    let name = builtins.head (builtins.attrNames entry.query);
    in "${name}=${entry.query.${name}}";

  # A Firefox match pattern. "*.host" matches the host and its subdomains.
  # Firefox includes the query string in the path that the pattern matches.
  toZenPattern = entry:
    if entry ? query then "*://*.${entry.host}${entry.path}*${queryPair entry}*"
    else if entry ? path then "*://*.${entry.host}${entry.path}*"
    else "*://*.${entry.host}/*";

  # A Chrome URL filter. A host with no leading dot also matches its
  # subdomains. A path matches as a prefix.
  toChromeFilter = entry:
    if entry ? query then "${entry.host}${entry.path}?${queryPair entry}"
    else if entry ? path then "${entry.host}${entry.path}"
    else entry.host;
in
{
  zenWebsiteFilterBlock = map toZenPattern checkedEntries;
  chromeUrlBlocklist = map toChromeFilter checkedEntries;

  # The default search engine in both browsers. udm=14 opens the Web tab of
  # Google search. That tab shows no image grid, AI Overview or knowledge
  # panel. This file holds it because it hides distracting Google content too.
  googleWebSearch = {
    name = "Google Web";
    url = "https://www.google.com/search?q={searchTerms}&udm=14";
  };

  # uBlock Origin custom filters. Only Zen uses them. uBlock Origin Lite in
  # Chrome has no policy for custom filters.
  ublockUserFilters = [
    "! Hide Google Image previews in search results"
    "www.google.com##[data-attrid^=\"VisualDigest\"]"
    "! Hide Short videos section from Google search"
    "www.google.com##.MjjYud:has(span:has-text(/^Short videos$/))"
    "! Hide What people are saying section from Google search"
    "www.google.com##.MjjYud:has(span:has-text(/^What people are saying$/))"
    "! Hide Images preview carousel from Google search"
    "www.google.com##div:has(> div > div[data-iu] span[role=\"heading\"]:has-text(/^Images$/))"
    "! Hide Facebook Reels link"
    "facebook.com##a[href*=\"/reel\"]"
    "! Hide YouTube comments"
    "youtube.com##ytd-comments"
  ];

  # Sites that pause behind a typing gate. A WebsiteFilter or URLBlocklist
  # entry stops these sites outright, so do not put a site in both places.
  #
  # An entry is a host, optionally followed by a path prefix. A bare host
  # covers its subdomains too, so scryfall.com also matches www.scryfall.com.
  # Adding a path narrows the match to part of a site -- google.com/search
  # would pause searching while leaving mail.google.com alone.
  webPause = {
    patterns = [
      "scryfall.com"
      "cubecobra.com"
      "discord.com"
      "mtg.wiki"
      "pitchfork.com"
      "luckypaper.co"
      "nba.com"
      "espn.com"
      "yahoo.com"
      "nytimes.com"
      "hipstersofthecoast.com"
      "fastmail.com"
      "app.slack.com/client/T03RZGPFR/C06MAR553"
      "facebook.com"
    ];
    prompts = [
      "Romans 5:17 For if, because of one man's trespass, death reigned through that one man, much more will those who receive the abundance of grace and the free gift of righteousness reign in life through the one man Jesus Christ."
      "2 Corinthians 10:17-18 Let the one who boasts, boast in the Lord. For it is not the one who commends himself who is approved, but the one whom the Lord commends."
    ];
  };
}
