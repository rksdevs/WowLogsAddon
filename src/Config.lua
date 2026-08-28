WowLogsConfig = {
  ADDON_NAME = "WoW Logs Addon",
  SCHEMA_VERSION = 1,
  WINDOW_WIDTH = 520,
  WINDOW_HEIGHT = 420,
  MAX_ROWS = 20,
}

--- Maps in-game GetRealmName() strings (and payload realm labels) to canonical
--- ADDON_REALM_LABELS values used in RankingsPayload (e.g. CircleWow → x100).
local REALM_LOOKUP_ALIASES = {
  ["wow circle 3.3.5a x1"] = "x1",
  ["wow circle 3.3.5a x4 hardcore"] = "x4",
  ["wow circle 3.3.5a x4"] = "x4",
  ["wow circle 3.3.5a x100"] = "x100",
  ["x1"] = "x1",
  ["x4"] = "x4",
  ["x100"] = "x100",
  -- Wow Patagonia: GetRealmName() is Andes; rankings payload still labels Patagonia
  ["andes"] = "patagonia",
}

function WowLogsResolveRealmForLookup(realm)
  local server = (realm or ""):lower()
  server = server:gsub("^%s+", ""):gsub("%s+$", "")

  if REALM_LOOKUP_ALIASES[server] then
    return REALM_LOOKUP_ALIASES[server]
  end

  -- Handle messy realm names (e.g. "Warmane-Lordaeron" -> "lordaeron")
  if server:find("-") then
    server = server:match("-(.-)$") or server
  end

  return server
end

function WowLogsNormalizeKey(playerName, realm)
  local name = (playerName or ""):lower()
  local server = WowLogsResolveRealmForLookup(realm)

  if server == "" then
    return name
  end
  return name .. "-" .. server
end
