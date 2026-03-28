WowLogsUI = {}

local frame
local rows = {}
local headerCells = {}
local visibleRows = 14
local rowHeight = 24

local savedFilters = {
  POINTS = {
    raidId = "ALL", bossId = "ALL", bossVariant = "ALL",
    difficulty = "ALL", className = "ALL", spec = "ALL",
    role = "ALL", ladder = "ALL",
  },
  PERFORMANCE = {
    raidId = "ALL", bossId = "ALL", bossVariant = "ALL",
    difficulty = "ALL", className = "ALL", spec = "ALL",
    role = "ALL", ladder = "ALL",
  },
}

local filters = {
  view = "POINTS", -- POINTS | PERFORMANCE
  raidId = "ALL",
  bossId = "ALL",
  bossVariant = "ALL",
  difficulty = "ALL",
  className = "ALL",
  spec = "ALL",
  role = "ALL",
  ladder = "ALL",
}

local function saveCurrentFilters()
  local sv = savedFilters[filters.view]
  sv.raidId = filters.raidId
  sv.bossId = filters.bossId
  sv.bossVariant = filters.bossVariant
  sv.difficulty = filters.difficulty
  sv.className = filters.className
  sv.spec = filters.spec
  sv.role = filters.role
  sv.ladder = filters.ladder
end

local function restoreFilters(view)
  local sv = savedFilters[view]
  filters.raidId = sv.raidId
  filters.bossId = sv.bossId
  filters.bossVariant = sv.bossVariant
  filters.difficulty = sv.difficulty
  filters.className = sv.className
  filters.spec = sv.spec
  filters.role = sv.role
  filters.ladder = sv.ladder
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

local function getActiveRows()
  local db = getDB()
  if filters.view == "PERFORMANCE" then
    return (db.rankings and db.rankings.performanceRows) or {}
  end
  return (db.rankings and db.rankings.rows) or {}
end

local function getActiveFilterMeta()
  local db = getDB()
  if filters.view == "PERFORMANCE" then
    return (db.rankings and db.rankings.performanceFilters) or {}
  end
  return (db.rankings and db.rankings.filters) or {}
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

local function getDifficultyOrder(value)
  local order = {
    TEN_NM = 1,
    TEN_HC = 2,
    TWENTY_FIVE_NM = 3,
    TWENTY_FIVE_HC = 4,
    OTHERS = 99,
  }
  return order[value] or 999
end

local function getDiffIconTag(value)
  local isHeroic = value == "TEN_HC" or value == "TWENTY_FIVE_HC"
  if isHeroic then
    return "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:12|t"
  end
  return "|TInterface\\Icons\\INV_Shield_06:12|t"
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

local function findNameById(list, id)
  for _, item in ipairs(list or {}) do
    if tostring(item.id) == tostring(id) then
      return item.name
    end
  end
  return nil
end

local function findValue(list, value)
  for _, item in ipairs(list or {}) do
    if tostring(item) == tostring(value) then
      return item
    end
  end
  return nil
end

local function getBossVariants()
  local out = WowLogsDataStore.QueryBosses(filters.view == "PERFORMANCE", filters.raidId, filters.difficulty)

  table.sort(out, function(a, b)
    if a.bossName == b.bossName then
      return getDifficultyOrder(a.difficulty) < getDifficultyOrder(b.difficulty)
    end
    return a.bossName < b.bossName
  end)

  return out
end

local function getBossDisplayText()
  if filters.bossId == "ALL" then
    return "All"
  end

  local variants = getBossVariants()
  local currentKey = tostring(filters.bossId) .. "|" .. tostring(filters.difficulty)
  for _, v in ipairs(variants) do
    if v.key == currentKey then
      return string.format("%s %s %s", getDiffIconTag(v.difficulty), formatDifficulty(v.difficulty), v.bossName)
    end
  end

  return "Boss"
end

local function createDropdown(name, parent, x, y, width, label)
  local l = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  l:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y + 16)
  l:SetText(label)
  l:SetTextColor(THEME.muted[1], THEME.muted[2], THEME.muted[3], THEME.muted[4])

  local dd = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
  dd:SetPoint("TOPLEFT", parent, "TOPLEFT", x - 12, y)
  UIDropDownMenu_SetWidth(dd, width)
  UIDropDownMenu_JustifyText(dd, "LEFT")
  dd.label = l
  return dd
end

local function getColumns()
  local db = getDB()
  local isPremium = db.rankings and db.rankings.isPremium

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
  local out = WowLogsDataStore.Query(filters.view == "PERFORMANCE", filters)

  table.sort(out, function(a, b)
    if filters.view == "PERFORMANCE" then
      local av = WowLogsDataStore.GetPercentile(a) or 0
      local bv = WowLogsDataStore.GetPercentile(b) or 0
      if av == bv then
        return (WowLogsDataStore.GetAmount(a) or 0) > (WowLogsDataStore.GetAmount(b) or 0)
      end
      return av > bv
    else
      local av = WowLogsDataStore.GetPoints(a) or 0
      local bv = WowLogsDataStore.GetPoints(b) or 0
      return av > bv
    end
  end)

  return out
end

local function initViewTabs()
  if filters.view == "POINTS" then
    frame.pointsTab:SetText("Points (Active)")
    frame.perfTab:SetText("Performance")
    frame.pointsTab:Disable()
    frame.perfTab:Enable()
    if frame.modeText then
      frame.modeText:SetText("Viewing: Points Leaderboard")
    end
  else
    frame.pointsTab:SetText("Points")
    frame.perfTab:SetText("Performance (Active)")
    frame.pointsTab:Enable()
    frame.perfTab:Disable()
    if frame.modeText then
      frame.modeText:SetText("Viewing: Performance Leaderboard")
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
  local db = getDB()
  local isPremium = db.rankings and db.rankings.isPremium
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

      -- Show followed star marker in name
      local nameText = WowLogsDataStore.GetPlayerName(entry) or "-"
      if WowLogsDataStore.GetIsFollowed(entry) then
        nameText = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:10|t " .. nameText
      end

      setCellText(row.rankCell, tostring(WowLogsDataStore.GetCategoryRank(entry) or (offset + i)), THEME.text, "LEFT")
      setCellText(row.playerCell, nameText, WowLogsDataStore.GetIsFollowed(entry) and THEME.gold or THEME.text, "LEFT")
      setCellText(row.diffCell, formatDifficulty(WowLogsDataStore.GetDifficulty(entry)), THEME.muted, "LEFT")

      if filters.view == "PERFORMANCE" then
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

        -- Trend column: show DNA for non-premium, colored +/- for premium
        if not isPremium then
          setCellText(row.trendCell, "DNA", THEME.muted, "RIGHT")
          setCellText(row.latestDateCell, "DNA", THEME.muted, "RIGHT")
        elseif WowLogsDataStore.GetTrend(entry) ~= nil then
          local trendVal = WowLogsDataStore.GetTrend(entry) or 0
          local trendStr, trendColor
          if trendVal > 0 then
            trendStr  = string.format("+%.1f", trendVal)
            trendColor = THEME.green
          elseif trendVal < 0 then
            trendStr  = string.format("%.1f", trendVal)
            trendColor = THEME.red
          else
            trendStr  = "~"
            trendColor = THEME.muted
          end
          setCellText(row.trendCell, trendStr, trendColor, "RIGHT")
          setCellText(row.latestDateCell, WowLogsDataStore.GetLatestDate(entry) or "-", THEME.muted, "RIGHT")
        else
          setCellText(row.trendCell, "N/A", THEME.muted, "RIGHT")
          setCellText(row.latestDateCell, "-", THEME.muted, "RIGHT")
        end
      else
        row.playerCell:SetWidth(300)
        row.diffCell:ClearAllPoints()
        row.diffCell:SetPoint("LEFT", row, "LEFT", 392, 0)
        row.diffCell:SetWidth(90)

        setCellText(row.pointsCell, string.format("%.2f", WowLogsDataStore.GetPoints(entry) or 0), THEME.accent, "RIGHT")
      end
    else
      row:Hide()
    end
  end

  frame.totalText:SetText(string.format("%d rows", total))
end

local function initSimpleDropdown(dropdown, listBuilder)
  UIDropDownMenu_Initialize(dropdown, function(self, level)
    listBuilder()
  end)
end

local function refreshDropdowns()
  local meta = getActiveFilterMeta()

  initSimpleDropdown(frame.raidDropdown, function()
    local info = UIDropDownMenu_CreateInfo()
    info.text = "All Raids"
    info.value = "ALL"
    info.func = function()
      filters.raidId = "ALL"
      filters.bossId = "ALL"
      filters.bossVariant = "ALL"
      filters.difficulty = "ALL"
      WowLogsUI.Refresh()
    end
    UIDropDownMenu_AddButton(info)

    for _, r in ipairs(meta.raids or {}) do
      info = UIDropDownMenu_CreateInfo()
      info.text = r.name
      info.value = tostring(r.id)
      info.func = function()
        filters.raidId = tostring(r.id)
        filters.bossId = "ALL"
        filters.bossVariant = "ALL"
        filters.difficulty = "ALL"
        WowLogsUI.Refresh()
      end
      UIDropDownMenu_AddButton(info)
    end
  end)

  if filters.raidId == "ALL" then
    UIDropDownMenu_SetText(frame.raidDropdown, "All")
  else
    UIDropDownMenu_SetText(frame.raidDropdown, findNameById(meta.raids, filters.raidId) or "Raid")
  end

  initSimpleDropdown(frame.bossDropdown, function()
    if filters.view ~= "PERFORMANCE" then
      local info = UIDropDownMenu_CreateInfo()
      info.text = "All Bosses"
      info.value = "ALL"
      info.func = function()
        filters.bossId = "ALL"
        filters.bossVariant = "ALL"
        WowLogsUI.Refresh()
      end
      UIDropDownMenu_AddButton(info)
    end

    local variants = getBossVariants()
    for _, v in ipairs(variants) do
      info = UIDropDownMenu_CreateInfo()
      info.text = string.format("%s %s %s", getDiffIconTag(v.difficulty), formatDifficulty(v.difficulty), v.bossName)
      info.value = v.key
      info.func = function()
        filters.bossId = tostring(v.bossId)
        filters.bossVariant = v.key
        filters.difficulty = v.difficulty
        WowLogsUI.Refresh()
      end
      UIDropDownMenu_AddButton(info)
    end
  end)
  UIDropDownMenu_SetText(frame.bossDropdown, getBossDisplayText())

  initSimpleDropdown(frame.diffDropdown, function()
    local info = UIDropDownMenu_CreateInfo()
    info.text = "All Difficulties"
    info.value = "ALL"
    info.func = function()
      filters.difficulty = "ALL"
      filters.bossVariant = "ALL"
      refreshRows()
      refreshDropdowns()
    end
    UIDropDownMenu_AddButton(info)

    for _, d in ipairs(meta.difficulties or {}) do
      info = UIDropDownMenu_CreateInfo()
      info.text = string.format("%s %s", getDiffIconTag(d), formatDifficulty(d))
      info.value = d
      info.func = function()
        filters.difficulty = d
        filters.bossVariant = "ALL"
        refreshRows()
        refreshDropdowns()
      end
      UIDropDownMenu_AddButton(info)
    end
  end)

  if filters.difficulty == "ALL" then
    UIDropDownMenu_SetText(frame.diffDropdown, "All")
  else
    UIDropDownMenu_SetText(frame.diffDropdown, formatDifficulty(filters.difficulty))
  end

  initSimpleDropdown(frame.classDropdown, function()
    local info = UIDropDownMenu_CreateInfo()
    info.text = "All Classes"
    info.value = "ALL"
    info.func = function()
      filters.className = "ALL"
      filters.spec = "ALL"
      WowLogsUI.Refresh()
    end
    UIDropDownMenu_AddButton(info)

    for _, cls in ipairs(meta.classes or {}) do
      info = UIDropDownMenu_CreateInfo()
      info.text = string.format("%s %s", getClassIconTag(cls), cls)
      info.value = cls
      info.func = function()
        filters.className = cls
        filters.spec = "ALL"
        WowLogsUI.Refresh()
      end
      UIDropDownMenu_AddButton(info)
    end
  end)

  UIDropDownMenu_SetText(frame.classDropdown, filters.className == "ALL" and "All" or filters.className)

  initSimpleDropdown(frame.specDropdown, function()
    local info = UIDropDownMenu_CreateInfo()
    info.text = "All Specs"
    info.value = "ALL"
    info.func = function()
      filters.spec = "ALL"
      refreshRows()
      refreshDropdowns()
    end
    UIDropDownMenu_AddButton(info)

    local list = {}
    local specsByClass = meta.specsByClass or {}
    if filters.className ~= "ALL" and specsByClass[filters.className] then
      for _, s in ipairs(specsByClass[filters.className]) do
        table.insert(list, { spec = s, className = filters.className })
      end
    else
      for cls, specs in pairs(specsByClass) do
        for _, s in ipairs(specs) do
          table.insert(list, { spec = s, className = cls })
        end
      end
      table.sort(list, function(a, b)
        if a.spec == b.spec then
          return a.className < b.className
        end
        return a.spec < b.spec
      end)
    end

    for _, item in ipairs(list) do
      info = UIDropDownMenu_CreateInfo()
      local iconTag = getSpecIconTag(item.className, item.spec)
      local label =
        filters.className ~= "ALL"
          and item.spec
          or string.format("%s (%s)", item.spec, item.className)
      info.text = string.format("%s %s", iconTag, label)
      info.value = item.spec
      info.func = function()
        if filters.className == "ALL" then
          filters.className = item.className
        end
        filters.spec = item.spec
        refreshRows()
        refreshDropdowns()
      end
      UIDropDownMenu_AddButton(info)
    end
  end)

  UIDropDownMenu_SetText(frame.specDropdown, filters.spec == "ALL" and "All" or filters.spec)

  initSimpleDropdown(frame.roleDropdown, function()
    local info = UIDropDownMenu_CreateInfo()
    info.text = "All Roles"
    info.value = "ALL"
    info.func = function()
      filters.role = "ALL"
      refreshRows()
      refreshDropdowns()
    end
    UIDropDownMenu_AddButton(info)

    for _, r in ipairs(meta.roles or {}) do
      info = UIDropDownMenu_CreateInfo()
      info.text = r
      info.value = r
      info.func = function()
        filters.role = r
        refreshRows()
        refreshDropdowns()
      end
      UIDropDownMenu_AddButton(info)
    end
  end)

  UIDropDownMenu_SetText(frame.roleDropdown, filters.role == "ALL" and "All" or filters.role)

  initSimpleDropdown(frame.ladderDropdown, function()
    local info = UIDropDownMenu_CreateInfo()
    info.text = "All Ladders"
    info.value = "ALL"
    info.func = function()
      filters.ladder = "ALL"
      refreshRows()
      refreshDropdowns()
    end
    UIDropDownMenu_AddButton(info)

    for _, l in ipairs(meta.ladders or {}) do
      info = UIDropDownMenu_CreateInfo()
      info.text = l
      info.value = l
      info.func = function()
        filters.ladder = l
        refreshRows()
        refreshDropdowns()
      end
      UIDropDownMenu_AddButton(info)
    end
  end)

  UIDropDownMenu_SetText(frame.ladderDropdown, filters.ladder == "ALL" and "All" or filters.ladder)
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
  f:SetSize(960, 620)
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
  if frame then return end

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
    saveCurrentFilters()     
    filters.view = "POINTS"
    restoreFilters("POINTS") 
    WowLogsUI.Refresh()
  end)

  frame.perfTab = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.perfTab:SetSize(110, 22)
  frame.perfTab:SetPoint("LEFT", frame.pointsTab, "RIGHT", 6, 0)
  frame.perfTab:SetText("Performance")
  frame.perfTab:SetScript("OnClick", function()
    saveCurrentFilters()          
    filters.view = "PERFORMANCE"
    restoreFilters("PERFORMANCE") 
    if filters.bossId == "ALL" then
      local variants = getBossVariants()
      if #variants > 0 then
        filters.bossId = tostring(variants[1].bossId)
        filters.bossVariant = variants[1].key
        filters.difficulty = variants[1].difficulty
      end
    end
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
  frame.modeText:SetText("Viewing: Points Leaderboard")
  frame.modeText:SetTextColor(THEME.muted[1], THEME.muted[2], THEME.muted[3], THEME.muted[4])

  local filterPanel = CreateFrame("Frame", nil, frame)
  filterPanel:SetSize(220, 500)
  filterPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -88)
  frame.filterPanel = filterPanel

  if filterPanel.SetBackdrop then
    filterPanel:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    filterPanel:SetBackdropColor(THEME.panel[1], THEME.panel[2], THEME.panel[3], THEME.panel[4])
    filterPanel:SetBackdropBorderColor(THEME.border[1], THEME.border[2], THEME.border[3], 0.8)
  end

  local filtersTitle = filterPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  filtersTitle:SetPoint("TOPLEFT", filterPanel, "TOPLEFT", 10, -10)
  filtersTitle:SetText("Filters")

  frame.raidDropdown   = createDropdown("WowLogsRaidDropdown",   filterPanel, 12, -44,  170, "Raid")
  frame.diffDropdown   = createDropdown("WowLogsDiffDropdown",   filterPanel, 12, -94,  170, "Difficulty")
  frame.bossDropdown   = createDropdown("WowLogsBossDropdown",   filterPanel, 12, -144, 170, "Boss")
  frame.classDropdown  = createDropdown("WowLogsClassDropdown",  filterPanel, 12, -194, 170, "Class")
  frame.specDropdown   = createDropdown("WowLogsSpecDropdown",   filterPanel, 12, -244, 170, "Spec")
  frame.roleDropdown   = createDropdown("WowLogsRoleDropdown",   filterPanel, 12, -294, 170, "Role")
  frame.ladderDropdown = createDropdown("WowLogsLadderDropdown", filterPanel, 12, -344, 170, "Ladder")

  local resetBtn = CreateFrame("Button", nil, filterPanel, "UIPanelButtonTemplate")
  resetBtn:SetSize(170, 22)
  resetBtn:SetPoint("BOTTOMLEFT", filterPanel, "BOTTOMLEFT", 12, 12)
  resetBtn:SetText("Reset Filters")
  resetBtn:SetScript("OnClick", function()
    filters.raidId = "ALL"
    filters.bossId = "ALL"
    filters.bossVariant = "ALL"
    filters.difficulty = "ALL"
    filters.className = "ALL"
    filters.spec = "ALL"
    filters.role = "ALL"
    filters.ladder = "ALL"
    WowLogsUI.Refresh()
  end)

  frame.tablePanel = CreateFrame("Frame", nil, frame)
  frame.tablePanel:SetSize(684, 500)
  frame.tablePanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 256, -88)
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
  frame.headerBar:SetSize(612, rowHeight)
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
  frame.scroll:SetPoint("BOTTOMRIGHT", frame.tablePanel, "BOTTOMRIGHT", -28, 14)

  frame.totalText = frame.tablePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.totalText:SetPoint("BOTTOMLEFT", frame.tablePanel, "BOTTOMLEFT", 12, 8)
  frame.totalText:SetText("0 rows")
  frame.totalText:SetTextColor(THEME.muted[1], THEME.muted[2], THEME.muted[3], THEME.muted[4])

  for i = 1, visibleRows do
    local row = CreateFrame("Button", nil, frame.tablePanel)
    row:SetSize(612, rowHeight)
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

  if filters.view == "PERFORMANCE" then
    frame.roleDropdown:Show()
    frame.ladderDropdown:Show()
    if frame.roleDropdown.label then frame.roleDropdown.label:Show() end
    if frame.ladderDropdown.label then frame.ladderDropdown.label:Show() end
    frame.bossDropdown:Show()
    if frame.bossDropdown.label then frame.bossDropdown.label:Show() end
  else
    frame.roleDropdown:Hide()
    frame.ladderDropdown:Hide()
    if frame.roleDropdown.label then frame.roleDropdown.label:Hide() end
    if frame.ladderDropdown.label then frame.ladderDropdown.label:Hide() end
    frame.bossDropdown:Hide()
    if frame.bossDropdown.label then frame.bossDropdown.label:Hide() end
  end

  refreshDropdowns()
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
