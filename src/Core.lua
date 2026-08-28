local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function handleCommand(msg)
  msg = string.lower(trim(msg or ""))

  if msg == "showicon" then
    msg = "minimap show"
  elseif msg == "hideicon" then
    msg = "minimap hide"
  end

  if msg == "refresh" then
    WowLogsBridge.RequestRefresh()
    return
  end

  if msg == "status" then
    print("[WoW Logs] " .. WowLogsBridge.GetStatusText())
    return
  end

  if msg == "exportguild" or msg == "guildexport" then
    if WowLogsGuildExport and WowLogsGuildExport.ShowDialog then
      WowLogsGuildExport.ShowDialog()
    else
      print("[WoW Logs] Guild export module not loaded.")
    end
    return
  end

  if msg == "exportraid" or msg == "exportparty" or msg == "exportroster" or msg == "raidpartyexport" then
    if WowLogsRaidPartyExport and WowLogsRaidPartyExport.ShowDialog then
      WowLogsRaidPartyExport.ShowDialog()
    else
      print("[WoW Logs] Raid/Party export module not loaded.")
    end
    return
  end

  if msg == "raidparty" or msg == "raidrankings" or msg == "partyrankings" then
    if WowLogsRaidPartyUI and WowLogsRaidPartyUI.Toggle then
      WowLogsRaidPartyUI.Toggle()
    else
      print("[WoW Logs] Raid/Party rankings UI not loaded.")
    end
    return
  end

  if msg == "minimap hide" then
    WowLogsAddonDB = WowLogsAddonDB or {}
    WowLogsAddonDB.meta = WowLogsAddonDB.meta or {}
    WowLogsAddonDB.meta.minimap = WowLogsAddonDB.meta.minimap or { angle = 210, hidden = false }
    WowLogsAddonDB.meta.minimap.hidden = true
    if WowLogsMinimapButton then WowLogsMinimapButton:Hide() end
    print("[WoW Logs] Minimap icon hidden. Use /wla showicon")
    return
  end

  if msg == "minimap show" then
    WowLogsAddonDB = WowLogsAddonDB or {}
    WowLogsAddonDB.meta = WowLogsAddonDB.meta or {}
    WowLogsAddonDB.meta.minimap = WowLogsAddonDB.meta.minimap or { angle = 210, hidden = false }
    WowLogsAddonDB.meta.minimap.hidden = false
    if WowLogsMinimapButton then WowLogsMinimapButton:Show() end
    print("[WoW Logs] Minimap icon shown. Use /wla hideicon")
    return
  end

  if msg == "tooltip hide" then
    WowLogsDataStore.SetHideUnrankedTooltip(true)
    print("[WoW Logs] Unranked player tooltips hidden. /wla tooltip show to restore.")
    return
  end

  if msg == "tooltip show" then
    WowLogsDataStore.SetHideUnrankedTooltip(false)
    print("[WoW Logs] Unranked player tooltips shown.")
    return
  end

  if msg:find("^tooltip") then
    local targetName = msg:match("^tooltip%s+(.+)")
    if targetName then
      local realm = WowLogsResolveRealmForLookup(GetRealmName())
      local ranking = WowLogsDataStore.GetPlayerRanking(targetName, realm)
      GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
      WowLogsTooltip.ShowForPlayer(ranking, targetName)
      return
    end
  end

  WowLogsUI.Toggle()
end

-- Register slash commands as early as possible.
SLASH_WOWLOGS1 = "/wla"
SLASH_WOWLOGS2 = "/wowlogs"
SlashCmdList["WOWLOGS"] = handleCommand

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    WowLogsDataStore.Init()
    WowLogsTooltip.Init()
    if WowLogsMinimap and WowLogsMinimap.Init then
      WowLogsMinimap.Init()
    end
    print("[WoW Logs] Addon loaded. Use /wla")
  end
end)
