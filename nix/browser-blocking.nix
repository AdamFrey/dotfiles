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
# google.* patterns. Google redirects its country domains to google.com, so
# the google.com entries cover them.
let
  entries = [
    # Google Images and Lens. Regular search stays open.
    { host = "images.google.com"; }
    { host = "google.com"; path = "/search"; query = { tbm = "isch"; }; }
    { host = "google.com"; path = "/search"; query = { udm = "2"; }; }
    # The short videos tab of Google search.
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

  # Work needs these hosts. Evaluation fails if an entry with no path blocks
  # one of them, because such an entry blocks every subdomain of its host.
  protectedHosts = [
    "calendar.google.com"
    "meet.google.com"
    "mail.google.com"
    "accounts.google.com"
    "docs.google.com"
    "drive.google.com"
  ];

  hasSuffix = suffix: s:
    let
      sl = builtins.stringLength suffix;
      l = builtins.stringLength s;
    in l >= sl && builtins.substring (l - sl) sl s == suffix;

  blocksProtectedHost = entry: protected:
    !(entry ? path)
    && (protected == entry.host || hasSuffix ".${entry.host}" protected);

  checkEntry = entry:
    let
      hits = builtins.filter (blocksProtectedHost entry) protectedHosts;
      queryNames = builtins.attrNames (entry.query or { });
    in
    if hits != [ ] then
      throw "browser-blocking.nix: the entry for ${entry.host} blocks the protected host ${builtins.head hits}. Add a path to the entry."
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
