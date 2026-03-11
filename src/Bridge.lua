WowLogsBridge = {}

function WowLogsBridge.RequestRefresh()
  print("[WoW Logs] Open uploader and click 'Update Rankings', then type /reload.")
end

function WowLogsBridge.GetStatusText()
  local updatedAt = WowLogsDataStore.GetUpdatedAt()
  local rankings = WowLogsAddonDB and WowLogsAddonDB.rankings
  local season = (rankings and rankings.season) or "?"
  local server = (rankings and rankings.serverName) or ""

  local updated = "never"
  if updatedAt and updatedAt > 0 then
    updated = date("%Y-%m-%d %H:%M", updatedAt)
  end

  if server ~= "" then
    return string.format("Season %s | %s | Updated: %s (active season only)", season, server, updated)
  end
  return string.format("Season %s | Updated: %s (active season only)", season, updated)
end
