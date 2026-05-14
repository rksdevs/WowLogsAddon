WowLogsUI = {}

local frame
local rows = {}
local headerCells = {}
local visibleRows = 14
local rowHeight = 24

local filters = {
  view = "POINTS", -- POINTS | PERFORMANCE
}

local function strtrim(s)
  if not s then return "" end
  return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""))
end

local THEME = {
  bg        = { 0.09, 0.10, 0.12, 0.95 },
  panel     = { 0.12, 0.13, 0.16, 0.92 },
  header    = { 0.15, 0.17, 0.22, 0.95 },
  rowAlt    = { 0.14, 0.15, 0.18, 0.32 },
  rowHover  = { 0.24, 0.30, 0.42, 0.40 },
  rowFollowed = { 0.32, 0.26, 0.06, 0.55 },
  border    = { 0.34, 0.38, 0.48, 0.95 },
  text      = { 0.94, 0.95, 0.98, 1 },
  muted     = { 0.76, 0.80, 0.87, 1 },
  accent    = { 0.39, 0.58, 0.95, 1 },
  gold      = { 1.00, 0.82, 0.20, 1 },
  green     = { 0.31, 0.88, 0.47, 1 },
  red       = { 0.95, 0.33, 0.33, 1 },
}

local classTokenByName = {
  ["Death Knight"] = "DEATHKNIGHT",
  ["Druid"] = "DRUID",
  ["Hunter"] = "HUNTER",
  ["Mage"] = "MAGE",
  ["Paladin"] = "PALADIN",
  ["Priest"] = "PRIEST",
  ["Rogue"] = "ROGUE",
  ["Shaman"] = "SHAMAN",
  ["Warlock"] = "WARLOCK",
  ["Warrior"] = "WARRIOR",
}

local specIconByClassSpec = {
  ["Death Knight|Blood"] = "Interface\\Icons\\Spell_Deathknight_BloodPresence",
  ["Death Knight|Frost"] = "Interface\\Icons\\Spell_Deathknight_FrostPresence",
  ["Death Knight|Unholy"] = "Interface\\Icons\\Spell_Deathknight_UnholyPresence",
  ["Druid|Balance"] = "Interface\\Icons\\Spell_Nature_StarFall",
  ["Druid|Feral Combat"] = "Interface\\Icons\\Ability_Druid_Maul",
  ["Druid|Restoration"] = "Interface\\Icons\\Spell_Nature_HealingTouch",
  ["Hunter|Beast Mastery"] = "Interface\\Icons\\Ability_Hunter_BeastTaming",
  ["Hunter|Marksmanship"] = "Interface\\Icons\\Ability_Marksmanship",
  ["Hunter|Survival"] = "Interface\\Icons\\Ability_Hunter_SwiftStrike",
  ["Mage|Arcane"] = "Interface\\Icons\\Spell_Holy_MagicalSentry",
  ["Mage|Fire"] = "Interface\\Icons\\Spell_Fire_FireBolt02",
  ["Mage|Frost"] = "Interface\\Icons\\Spell_Frost_FrostBolt02",
  ["Paladin|Holy"] = "Interface\\Icons\\Spell_Holy_HolyBolt",
  ["Paladin|Protection"] = "Interface\\Icons\\Ability_Paladin_ShieldoftheTemplar",
  ["Paladin|Retribution"] = "Interface\\Icons\\Spell_Holy_AuraOfLight",
  ["Priest|Discipline"] = "Interface\\Icons\\Spell_Holy_PowerWordShield",
  ["Priest|Holy"] = "Interface\\Icons\\Spell_Holy_GuardianSpirit",
  ["Priest|Shadow"] = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
  ["Rogue|Assassination"] = "Interface\\Icons\\Ability_Rogue_Eviscerate",
  ["Rogue|Combat"] = "Interface\\Icons\\Ability_BackStab",
  ["Rogue|Subtlety"] = "Interface\\Icons\\Ability_Stealth",
  ["Shaman|Elemental"] = "Interface\\Icons\\Spell_Nature_Lightning",
  ["Shaman|Enhancement"] = "Interface\\Icons\\Spell_Nature_LightningShield",
  ["Shaman|Restoration"] = "Interface\\Icons\\Spell_Nature_MagicImmunity",
  ["Warlock|Affliction"] = "Interface\\Icons\\Spell_Shadow_DeathCoil",
  ["Warlock|Demonology"] = "Interface\\Icons\\Spell_Shadow_Metamorphosis",
  ["Warlock|Destruction"] = "Interface\\Icons\\Spell_Shadow_RainOfFire",
  ["Warrior|Arms"] = "Interface\\Icons\\Ability_Warrior_SavageBlow",
  ["Warrior|Fury"] = "Interface\\Icons\\Ability_Warrior_InnerRage",
  ["Warrior|Protection"] = "Interface\\Icons\\Ability_Warrior_DefensiveStance",
}

local function getDB()
  return WowLogsDataStore.GetDb()
end

local function formatDifficulty(value)
  local map = {
    TEN_NM = "10N",
    TEN_HC = "10H",
    TWENTY_FIVE_NM = "25N",
    TWENTY_FIVE_HC = "25H",
    OTHERS = "Other",
  }
  return map[value] or value or "-"
end

local function setClassIcon(tex, className)
  local token = classTokenByName[className]
  if not token or not CLASS_ICON_TCOORDS or not CLASS_ICON_TCOORDS[token] then
    tex:Hide()
    return
  end
  local coords = CLASS_ICON_TCOORDS[token]
  tex:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
  tex:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
  tex:Show()
end

local function setSpecIcon(tex, className, spec)
  local iconPath = specIconByClassSpec[className .. "|" .. spec]
  if not iconPath then
    tex:Hide()
    return
  end
  tex:SetTexture(iconPath)
  tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  tex:Show()
end

local function getClassIconTag(className)
  local token = classTokenByName[className]
  if not token or not CLASS_ICON_TCOORDS or not CLASS_ICON_TCOORDS[token] then
    return ""
  end
  local coords = CLASS_ICON_TCOORDS[token]
  return string.format(
    "|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:14:14:0:0:256:256:%d:%d:%d:%d|t",
    coords[1] * 256,
    coords[2] * 256,
    coords[3] * 256,
    coords[4] * 256
  )
end

local function getSpecIconTag(className, spec)
  local iconPath = specIconByClassSpec[className .. "|" .. spec]
  if not iconPath then
    return ""
  end
  return string.format("|T%s:14:14|t", iconPath)
end

local function getColumns()
  local rk = WowLogsDataStore.GetRankings()
  local isPremium = rk and rk.isPremium

  if filters.view == "PERFORMANCE" then
    local cols = {
      { key = "rank",      label = "#",         x = 8,   w = 26,  align = "LEFT"  },
      { key = "classIcon", label = "",            x = 40,  w = 20,  align = "LEFT"  },
      { key = "specIcon",  label = "",            x = 62,  w = 20,  align = "LEFT"  },
      { key = "player",    label = "Player",      x = 86,  w = 140, align = "LEFT"  },
      { key = "role",      label = "Role",        x = 232, w = 46,  align = "LEFT"  },
      { key = "ladder",    label = "Ladder",      x = 282, w = 60,  align = "LEFT"  },
      { key = "diff",      label = "Difficulty",  x = 345, w = 46,  align = "LEFT"  },
      { key = "amount",    label = "Amount",      x = 395, w = 50,  align = "RIGHT" },
      { key = "pct",       label = "%Best",       x = 450, w = 40,  align = "RIGHT" },
      { key = "trend",     label = "Trend",       x = 495, w = 46,  align = "RIGHT" },
      { key = "latestDate",label = "Latest",      x = 545, w = 70,  align = "RIGHT" },
    }
    if not isPremium then
      cols[10].label  = "Trend "
      cols[11].label  = "Latest "
    end
    return cols
  end

  if rk and rk.pointsV2 then
    return {
      { key = "rank",      label = "#",         x = 8,   w = 26,  align = "LEFT"  },
      { key = "classIcon", label = "",            x = 40,  w = 20,  align = "LEFT"  },
      { key = "specIcon",  label = "",            x = 62,  w = 20,  align = "LEFT"  },
      { key = "player",   label = "Player",      x = 86,  w = 168, align = "LEFT"  },
      { key = "role",     label = "Role",        x = 258, w = 40,  align = "LEFT"  },
      { key = "points",   label = "Points",      x = 302, w = 72,  align = "RIGHT" },
      { key = "spct",     label = "Spec %",      x = 378, w = 52,  align = "RIGHT" },
      { key = "cpct",     label = "Class %",     x = 434, w = 52,  align = "RIGHT" },
      { key = "rpct",     label = "Role %",      x = 490, w = 52,  align = "RIGHT" },
    }
  end

  return {
    { key = "rank",      label = "#",         x = 8,   w = 26,  align = "LEFT"  },
    { key = "classIcon", label = "",            x = 40,  w = 20,  align = "LEFT"  },
    { key = "specIcon",  label = "",            x = 62,  w = 20,  align = "LEFT"  },
    { key = "player",   label = "Player",      x = 86,  w = 300, align = "LEFT"  },
    { key = "diff",     label = "Difficulty",  x = 392, w = 90,  align = "LEFT"  },
    { key = "points",   label = "Points",      x = 494, w = 108, align = "RIGHT" },
  }
end

local function getFilteredRows()
  local q = ""
  if frame and frame.searchBox then
    q = strtrim(frame.searchBox:GetText() or "")
  end
  local out = WowLogsDataStore.QueryWithSearch(filters.view == "PERFORMANCE", q)

  table.sort(out, function(a, b)
    if filters.view == "PERFORMANCE" then
      local av = WowLogsDataStore.GetPercentile(a) or 0
      local bv = WowLogsDataStore.GetPercentile(b) or 0
      if av == bv then
        return (WowLogsDataStore.GetAmount(a) or 0) > (WowLogsDataStore.GetAmount(b) or 0)
      end
      return av > bv
    else
      local rk = WowLogsDataStore.GetRankings()
      if rk and rk.pointsV2 then
        local ar = tonumber(WowLogsDataStore.GetCategoryRank(a)) or 999999
        local br = tonumber(WowLogsDataStore.GetCategoryRank(b)) or 999999
        if ar == br then
          return (WowLogsDataStore.GetPoints(a) or 0) > (WowLogsDataStore.GetPoints(b) or 0)
        end
        return ar < br
      end
      local av = WowLogsDataStore.GetPoints(a) or 0
      local bv = WowLogsDataStore.GetPoints(b) or 0
      return av > bv
    end
  end)

  return out
end

local function initViewTabs()
  frame.pointsTab:SetText("Points")
  frame.perfTab:SetText("Performance")
  if filters.view == "POINTS" then
    frame.pointsTab:Disable()
    frame.perfTab:Enable()
  else
    frame.pointsTab:Enable()
    frame.perfTab:Disable()
  end
  if frame.modeText then
    frame.modeText:SetText("Use the Native Uploader to refresh data.")
  end
  if frame.leaderboardHeading then
    if filters.view == "PERFORMANCE" then
      frame.leaderboardHeading:SetText("Performance leaderboard")
    else
      local rk = WowLogsDataStore.GetRankings()
      if rk and rk.pointsV2 then
        frame.leaderboardHeading:SetText("Points leaderboard (V2)")
      else
        frame.leaderboardHeading:SetText("Points leaderboard")
      end
    end
  end
  if frame.perfSliceSummary then
    local rk = WowLogsDataStore.GetRankings()
    local sumPerf = (rk and rk.performanceSliceSummary) or ""
    local sumPts = (rk and rk.pointsSliceSummary) or ""
    if filters.view == "PERFORMANCE" and sumPerf ~= "" then
      frame.perfSliceSummary:SetText(sumPerf)
      frame.perfSliceSummary:Show()
    elseif filters.view == "POINTS" and sumPts ~= "" then
      frame.perfSliceSummary:SetText(sumPts)
      frame.perfSliceSummary:Show()
    else
      frame.perfSliceSummary:Hide()
    end
  end
end

local function paintHeader()
  for _, fs in ipairs(headerCells) do
    fs:Hide()
  end

  local cols = getColumns()
  for i, col in ipairs(cols) do
    local fs = headerCells[i]
    if not fs then
      fs = frame.headerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      headerCells[i] = fs
    end
    fs:Show()
    fs:SetPoint("LEFT", frame.headerBar, "LEFT", col.x, 0)
    fs:SetWidth(col.w)
    fs:SetJustifyH(col.align == "RIGHT" and "RIGHT" or "LEFT")
    fs:SetText(col.label)
    fs:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], THEME.text[4])
  end
end

local function setCellText(cell, text, color, align)
  cell:SetText(text or "")
  cell:SetJustifyH(align == "RIGHT" and "RIGHT" or "LEFT")
  local c = color or THEME.text
  cell:SetTextColor(c[1], c[2], c[3], c[4])
end

local function refreshRows()
  local rk = WowLogsDataStore.GetRankings()
  local isPremium = rk and rk.isPremium
  local data = getFilteredRows()
  local total = #data

  FauxScrollFrame_Update(frame.scroll, total, visibleRows, rowHeight)
  local offset = FauxScrollFrame_GetOffset(frame.scroll)

  paintHeader()

  for i = 1, visibleRows do
    local row = rows[i]
    local entry = data[offset + i]
    if entry then
      row:Show()
      if row.bg then
        if WowLogsDataStore.GetIsFollowed(entry) then
          row.bg:SetTexture(THEME.rowFollowed[1], THEME.rowFollowed[2], THEME.rowFollowed[3], THEME.rowFollowed[4])
        elseif math.fmod(i, 2) == 0 then
          row.bg:SetTexture(THEME.rowAlt[1], THEME.rowAlt[2], THEME.rowAlt[3], THEME.rowAlt[4])
        else
          row.bg:SetTexture(0, 0, 0, 0)
        end
      end

      setClassIcon(row.classIcon, WowLogsDataStore.GetPlayerClass(entry))
      setSpecIcon(row.specIcon, WowLogsDataStore.GetPlayerClass(entry), WowLogsDataStore.GetPlayerSpec(entry))

      row.rankCell:Show()
      row.playerCell:Show()
      row.diffCell:Show()
      row.pointsCell:Show()
      row.roleCell:Hide()
      row.ladderCell:Hide()
      row.pctCell:Hide()
      row.amountCell:Hide()
      row.trendCell:Hide()
      row.latestDateCell:Hide()

      local nameText = WowLogsDataStore.GetPlayerName(entry) or "-"
      if WowLogsDataStore.GetIsFollowed(entry) then
        nameText = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:10|t " .. nameText
      end

      setCellText(row.rankCell, tostring(WowLogsDataStore.GetCategoryRank(entry) or (offset + i)), THEME.text, "LEFT")
      setCellText(row.playerCell, nameText, WowLogsDataStore.GetIsFollowed(entry) and THEME.gold or THEME.text, "LEFT")

      if filters.view == "PERFORMANCE" then
        setCellText(row.diffCell, formatDifficulty(WowLogsDataStore.GetDifficulty(entry)), THEME.muted, "LEFT")
        row.playerCell:SetWidth(140)
        row.diffCell:ClearAllPoints()
        row.diffCell:SetPoint("LEFT", row, "LEFT", 345, 0)
        row.diffCell:SetWidth(46)

        row.roleCell:Show()
        row.ladderCell:Show()
        row.pctCell:Show()
        row.amountCell:Show()
        row.trendCell:Show()
        row.latestDateCell:Show()
        row.pointsCell:Hide()

        setCellText(row.roleCell, WowLogsDataStore.GetRole(entry) or "-", THEME.muted, "LEFT")
        setCellText(row.ladderCell, WowLogsDataStore.GetLadder(entry) or "-", THEME.muted, "LEFT")
        setCellText(row.amountCell, string.format("%.1f", WowLogsDataStore.GetAmount(entry) or 0), THEME.text, "RIGHT")
        setCellText(row.pctCell, string.format("%.1f", WowLogsDataStore.GetPercentile(entry) or 0), THEME.accent, "RIGHT")

        if not isPremium then
          setCellText(row.trendCell, "DNA", THEME.muted, "RIGHT")
          setCellText(row.latestDateCell, "DNA", THEME.muted, "RIGHT")
        elseif WowLogsDataStore.GetTrend(entry) ~= nil then
          local trendVal = WowLogsDataStore.GetTrend(entry) or 0
          local trendStr, trendColor
          if trendVal > 0 then
            trendStr = string.format("+%.1f", trendVal)
            trendColor = THEME.green
          elseif trendVal < 0 then
            trendStr = string.format("%.1f", trendVal)
            trendColor = THEME.red
          else
            trendStr = "~"
            trendColor = THEME.muted
          end
          setCellText(row.trendCell, trendStr, trendColor, "RIGHT")
          setCellText(row.latestDateCell, WowLogsDataStore.GetLatestDate(entry) or "-", THEME.muted, "RIGHT")
        else
          setCellText(row.trendCell, "N/A", THEME.muted, "RIGHT")
          setCellText(row.latestDateCell, "-", THEME.muted, "RIGHT")
        end
      else
        if rk.pointsV2 then
          row.playerCell:SetWidth(168)
          row.diffCell:ClearAllPoints()
          row.diffCell:SetPoint("LEFT", row, "LEFT", 258, 0)
          row.diffCell:SetWidth(40)
          row.pointsCell:ClearAllPoints()
          row.pointsCell:SetPoint("LEFT", row, "LEFT", 302, 0)
          row.pointsCell:SetWidth(72)
          row.pctCell:Show()
          row.amountCell:Show()
          row.trendCell:Show()
          row.pctCell:ClearAllPoints()
          row.pctCell:SetPoint("LEFT", row, "LEFT", 378, 0)
          row.pctCell:SetWidth(52)
          row.amountCell:ClearAllPoints()
          row.amountCell:SetPoint("LEFT", row, "LEFT", 434, 0)
          row.amountCell:SetWidth(52)
          row.trendCell:ClearAllPoints()
          row.trendCell:SetPoint("LEFT", row, "LEFT", 490, 0)
          row.trendCell:SetWidth(52)
          setCellText(row.diffCell, WowLogsDataStore.GetRole(entry) or "-", THEME.muted, "LEFT")
          setCellText(row.pointsCell, string.format("%.2f", WowLogsDataStore.GetPoints(entry) or 0), THEME.accent, "RIGHT")
          local sp = WowLogsDataStore.GetV2SpecPct(entry) or 0
          local cp = WowLogsDataStore.GetV2ClassPct(entry) or 0
          local rp = WowLogsDataStore.GetV2RolePct(entry) or 0
          setCellText(row.pctCell, string.format("%.1f%%", sp), THEME.accent, "RIGHT")
          setCellText(row.amountCell, string.format("%.1f%%", cp), THEME.accent, "RIGHT")
          setCellText(row.trendCell, string.format("%.1f%%", rp), THEME.accent, "RIGHT")
        else
          row.playerCell:SetWidth(300)
          row.diffCell:ClearAllPoints()
          row.diffCell:SetPoint("LEFT", row, "LEFT", 392, 0)
          row.diffCell:SetWidth(90)

          setCellText(row.diffCell, formatDifficulty(WowLogsDataStore.GetDifficulty(entry)), THEME.muted, "LEFT")
          setCellText(row.pointsCell, string.format("%.2f", WowLogsDataStore.GetPoints(entry) or 0), THEME.accent, "RIGHT")
        end
      end
    else
      row:Hide()
    end
  end
end

local function makeCell(parent, x, width, align)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fs:SetPoint("LEFT", parent, "LEFT", x, 0)
  fs:SetWidth(width)
  fs:SetJustifyH(align == "RIGHT" and "RIGHT" or "LEFT")
  fs:SetJustifyV("MIDDLE")
  return fs
end

local function createBasicFrame()
  local f = CreateFrame("Frame", "WowLogsRankFrame", UIParent)
  f:SetSize(720, 560)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)

  if f.SetBackdrop then
    f:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(THEME.bg[1], THEME.bg[2], THEME.bg[3], THEME.bg[4])
    f:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], THEME.border[4])
  end

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  title:SetPoint("TOP", f, "TOP", 0, -12)
  title:SetText("WoW Logs Rankings")
  title:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], THEME.text[4])

  local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)

  return f
end

local function ensureFrame()
  if frame and frame.searchPlaceholder and frame.searchBox and frame.leaderboardHeading then
    return
  end
  if frame then
    frame:Hide()
    frame:SetParent(nil)
    frame = nil
    for i = 1, #headerCells do
      headerCells[i] = nil
    end
    for i = 1, #rows do
      rows[i] = nil
    end
  end

  frame = createBasicFrame()
  frame:Hide()

  frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  frame.status:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -34)
  frame.status:SetText("Data updated: never")
  frame.status:SetTextColor(THEME.accent[1], THEME.accent[2], THEME.accent[3], 1)

  frame.pointsTab = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.pointsTab:SetSize(90, 22)
  frame.pointsTab:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -56)
  frame.pointsTab:SetText("Points")
  frame.pointsTab:SetScript("OnClick", function()
    filters.view = "POINTS"
    WowLogsUI.Refresh()
  end)

  frame.perfTab = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.perfTab:SetSize(110, 22)
  frame.perfTab:SetPoint("LEFT", frame.pointsTab, "RIGHT", 6, 0)
  frame.perfTab:SetText("Performance")
  frame.perfTab:SetScript("OnClick", function()
    filters.view = "PERFORMANCE"
    WowLogsUI.Refresh()
  end)

  frame.reloadBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.reloadBtn:SetSize(80, 22)
  frame.reloadBtn:SetPoint("LEFT", frame.perfTab, "RIGHT", 12, 0)
  frame.reloadBtn:SetText("Reload UI")
  frame.reloadBtn:SetScript("OnClick", function()
    ReloadUI()
  end)

  frame.guildExportBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.guildExportBtn:SetSize(96, 22)
  frame.guildExportBtn:SetPoint("LEFT", frame.reloadBtn, "RIGHT", 8, 0)
  frame.guildExportBtn:SetText("Export Guild")
  frame.guildExportBtn:SetScript("OnClick", function()
    if WowLogsGuildExport and WowLogsGuildExport.ShowDialog then
      WowLogsGuildExport.ShowDialog()
    else
      print("|cffff8800[WoW Logs]|r Guild export module not loaded.")
    end
  end)

  frame.modeText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.modeText:SetPoint("LEFT", frame.guildExportBtn, "RIGHT", 12, 0)
  frame.modeText:SetText("Use the Native Uploader to refresh data.")
  frame.modeText:SetTextColor(THEME.muted[1], THEME.muted[2], THEME.muted[3], THEME.muted[4])

  local searchFocused = false

  frame.searchBox = CreateFrame("EditBox", "WowLogsRankSearchBox", frame)
  frame.searchBox:SetSize(640, 22)
  frame.searchBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -82)
  frame.searchBox:SetAutoFocus(false)
  frame.searchBox:SetFontObject("GameFontHighlightSmall")
  frame.searchBox:SetTextInsets(8, 8, 0, 0)
  if frame.searchBox.SetBackdrop then
    frame.searchBox:SetBackdrop({
      bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 8,
      edgeSize = 12,
      insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame.searchBox:SetBackdropColor(0.05, 0.06, 0.08, 0.9)
    frame.searchBox:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], 0.85)
  end

  -- BACKGROUND draws under the EditBox (3.3.x EditBox has no GetFrameLevel / SetFrameLevel).
  frame.searchPlaceholder = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
  frame.searchPlaceholder:SetPoint("LEFT", frame.searchBox, "LEFT", 8, 0)
  frame.searchPlaceholder:SetText("Search Player by Name")
  -- Lighter than THEME.muted@low alpha so it stays readable on the near-black EditBox backdrop (3.3.5).
  frame.searchPlaceholder:SetTextColor(0.58, 0.62, 0.72, 0.92)

  local function updateSearchPlaceholder()
    if not frame.searchBox or not frame.searchPlaceholder then return end
    local empty = (strtrim(frame.searchBox:GetText() or "") == "")
    local show = empty and not searchFocused
    if show then
      frame.searchPlaceholder:Show()
    else
      frame.searchPlaceholder:Hide()
    end
  end

  frame.searchBox:SetScript("OnTextChanged", function()
    updateSearchPlaceholder()
    refreshRows()
  end)
  frame.searchBox:SetScript("OnEditFocusGained", function()
    searchFocused = true
    updateSearchPlaceholder()
  end)
  frame.searchBox:SetScript("OnEditFocusLost", function()
    searchFocused = false
    updateSearchPlaceholder()
  end)
  frame.searchBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    searchFocused = false
    updateSearchPlaceholder()
  end)
  updateSearchPlaceholder()

  frame.leaderboardHeading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.leaderboardHeading:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -108)
  frame.leaderboardHeading:SetWidth(640)
  frame.leaderboardHeading:SetJustifyH("LEFT")
  frame.leaderboardHeading:SetText("Points leaderboard")
  frame.leaderboardHeading:SetTextColor(THEME.text[1], THEME.text[2], THEME.text[3], 1)

  frame.perfSliceSummary = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.perfSliceSummary:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -132)
  frame.perfSliceSummary:SetWidth(640)
  frame.perfSliceSummary:SetJustifyH("LEFT")
  frame.perfSliceSummary:SetText("")
  frame.perfSliceSummary:SetTextColor(THEME.accent[1], THEME.accent[2], THEME.accent[3], 1)
  frame.perfSliceSummary:Hide()

  frame.tablePanel = CreateFrame("Frame", nil, frame)
  frame.tablePanel:SetSize(656, 358)
  frame.tablePanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -172)
  if frame.tablePanel.SetBackdrop then
    frame.tablePanel:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame.tablePanel:SetBackdropColor(THEME.panel[1], THEME.panel[2], THEME.panel[3], THEME.panel[4])
    frame.tablePanel:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], 0.8)
  end

  frame.headerBar = CreateFrame("Frame", nil, frame.tablePanel)
  frame.headerBar:SetSize(620, rowHeight)
  frame.headerBar:SetPoint("TOPLEFT", frame.tablePanel, "TOPLEFT", 10, -10)
  if frame.headerBar.SetBackdrop then
    frame.headerBar:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 10,
      insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame.headerBar:SetBackdropColor(THEME.header[1], THEME.header[2], THEME.header[3], THEME.header[4])
    frame.headerBar:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], 0.9)
  end

  frame.scroll = CreateFrame("ScrollFrame", "WowLogsRankScrollFrame", frame.tablePanel, "FauxScrollFrameTemplate")
  frame.scroll:SetPoint("TOPLEFT", frame.tablePanel, "TOPLEFT", 10, -38)
  frame.scroll:SetPoint("BOTTOMRIGHT", frame.tablePanel, "BOTTOMRIGHT", -28, 8)

  for i = 1, visibleRows do
    local row = CreateFrame("Button", nil, frame.tablePanel)
    row:SetSize(620, rowHeight)
    row:SetPoint("TOPLEFT", frame.tablePanel, "TOPLEFT", 10, -38 - ((i - 1) * rowHeight))

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints(row)

    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    local ht = row:GetHighlightTexture()
    if ht then
      ht:SetBlendMode("ADD")
      ht:SetVertexColor(THEME.rowHover[1], THEME.rowHover[2], THEME.rowHover[3], THEME.rowHover[4])
    end

    row.classIcon = row:CreateTexture(nil, "ARTWORK")
    row.classIcon:SetSize(16, 16)
    row.classIcon:SetPoint("LEFT", row, "LEFT", 40, 0)

    row.specIcon = row:CreateTexture(nil, "ARTWORK")
    row.specIcon:SetSize(16, 16)
    row.specIcon:SetPoint("LEFT", row, "LEFT", 62, 0)

    row.rankCell    = makeCell(row, 8,   26,  "LEFT")
    row.playerCell  = makeCell(row, 86,  300, "LEFT")
    row.diffCell    = makeCell(row, 392, 90,  "LEFT")
    row.pointsCell  = makeCell(row, 494, 108, "RIGHT")

    row.roleCell       = makeCell(row, 232, 46, "LEFT")
    row.ladderCell     = makeCell(row, 282, 60, "LEFT")
    row.amountCell     = makeCell(row, 395, 50, "RIGHT")
    row.pctCell        = makeCell(row, 450, 40, "RIGHT")
    row.trendCell      = makeCell(row, 495, 46, "RIGHT")
    row.latestDateCell = makeCell(row, 545, 70, "RIGHT")

    rows[i] = row
  end

  frame.scroll:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, rowHeight, refreshRows)
  end)
end

function WowLogsUI.Refresh()
  ensureFrame()
  frame.status:SetText(WowLogsBridge.GetStatusText())

  initViewTabs()
  refreshRows()
end

function WowLogsUI.Toggle()
  ensureFrame()
  if frame:IsShown() then
    frame:Hide()
  else
    WowLogsUI.Refresh()
    frame:Show()
  end
end
