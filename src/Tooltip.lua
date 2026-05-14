WowLogsTooltip = {}

local classColors = {
  ["Warrior"] = {0.78, 0.61, 0.43},
  ["Paladin"] = {0.96, 0.55, 0.73},
  ["Hunter"] = {0.67, 0.83, 0.45},
  ["Rogue"] = {1.0, 0.96, 0.41},
  ["Priest"] = {1.0, 1.0, 1.0},
  ["Death Knight"] = {0.77, 0.12, 0.23},
  ["Shaman"] = {0.0, 0.44, 0.87},
  ["Mage"] = {0.41, 0.8, 0.94},
  ["Warlock"] = {0.58, 0.51, 0.79},
  ["Druid"] = {1.0, 0.49, 0.04}
}

local diffOrder = {
  ["TWENTY_FIVE_HC"] = 1,
  ["TEN_HC"] = 2,
  ["TWENTY_FIVE_NM"] = 3,
  ["TEN_NM"] = 4
}

local diffNames = {
  ["TWENTY_FIVE_HC"] = "25Hc",
  ["TEN_HC"] = "10Hc",
  ["TWENTY_FIVE_NM"] = "25Nm",
  ["TEN_NM"] = "10Nm",
  ["V2"] = "V2",
}

function WowLogsTooltip.ShowForPlayer(r, playerName)
  local header = "WoW Logs Ranking"
  if playerName then
    header = header .. " - " .. playerName
  end

  GameTooltip:AddLine(header, 1, 0.82, 0)
  GameTooltip:AddLine("-----------------------------", 0.4, 0.4, 0.4)

  if not r then
    GameTooltip:AddLine("Ranking data not available", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("(Top 20 only)", 0.5, 0.5, 0.5)
    GameTooltip:Show()
    return
  end


  if r.rankings and #r.rankings > 0 then
    -- Sort by points desc
    local sortedRanks = {}
    for _, rankObj in ipairs(r.rankings) do
      table.insert(sortedRanks, rankObj)
    end
    table.sort(sortedRanks, function(a, b)
      return (a.points or 0) > (b.points or 0)
    end)

    local c = classColors[r.playerClass] or {0.8, 0.8, 0.8}

    for _, ranking in ipairs(sortedRanks) do
      local dns  = diffNames[ranking.difficulty] or ranking.difficulty
      local spec = ranking.spec or "Unknown"
      local rnk  = ranking.rank or "-"
      local pts  = ranking.points or 0

      local left = string.format("|cffFFD700#%s|r |cff%02x%02x%02x%s|r %s",
        rnk,
        math.floor(c[1]*255), math.floor(c[2]*255), math.floor(c[3]*255),
        spec,
        dns
      )
      local right = string.format("%.1f", pts)

      GameTooltip:AddDoubleLine(left, right, 1, 1, 1, 0, 1, 1)
    end
  end

  GameTooltip:AddLine(" ")
  GameTooltip:Show()
end

local function onTooltipSetUnit()
  local _, unit = GameTooltip:GetUnit()
  if not unit then return end
  if not UnitIsPlayer(unit) then return end

  local name, realm = UnitName(unit)
  if not name then return end

  if not realm or realm == "" then
    realm = GetRealmName()
  end

  local ranking = WowLogsDataStore.GetPlayerRanking(name, realm)
  WowLogsTooltip.ShowForPlayer(ranking, name)
end

function WowLogsTooltip.Init()
  GameTooltip:HookScript("OnTooltipSetUnit", onTooltipSetUnit)
end
