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
  if server == "" then
    return name
  end
  return name .. "-" .. server
end
