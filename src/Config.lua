WowLogsConfig = {
  ADDON_NAME = "WoW Logs Addon",
  SCHEMA_VERSION = 1,
  WINDOW_WIDTH = 520,
  WINDOW_HEIGHT = 420,
  MAX_ROWS = 20,
}

function WowLogsNormalizeKey(playerName, realm)
  local name = (playerName or ""):lower()
  local server = (realm or ""):lower()
  
  -- Handle messy realm names (e.g. "Warmane-Lordaeron" -> "lordaeron")
  if server:find("-") then
    server = server:match("-(.-)$") or server
  end
  
  if server == "" then
    return name
  end
  return name .. "-" .. server
end
