-- Raid/Party character rankings table (guild-rankings-style data from Native Uploader).

WowLogsRaidPartyUI = {}
WowLogsGuildRankUI = {}

local activeMode = "raidParty" -- "raidParty" | "guildRank"

local frame
local rows = {}
local headerCells = {}
local visibleRows = 12
local rowHeight    = 30
local bossCols     = {}

-- boss pagination state
local bossPageOffset  = 0
local MAX_VIS_BOSSES  = 7   -- boss columns visible at once
local BOSS_COL_W      = 52  -- pixels per boss column (wider = more readable)
local FIXED_END_X     = 294 -- x where boss columns start (after Player/Avg/Points)

local THEME = {
  bg     = { 0.09, 0.10, 0.12, 1.0 },
  panel  = { 0.12, 0.13, 0.16, 1.0 },
  header = { 0.15, 0.17, 0.22, 0.95 },
  border = { 0.34, 0.38, 0.48, 0.95 },
  text   = { 0.94, 0.95, 0.98, 1 },
  muted  = { 0.76, 0.80, 0.87, 1 },
  accent = { 0.39, 0.58, 0.95, 1 },
  green  = { 0.31, 0.88, 0.47, 1 },
}

local classTokenByName = {
  ["Death Knight"] = "DEATHKNIGHT",
  ["Druid"]        = "DRUID",
  ["Hunter"]       = "HUNTER",
  ["Mage"]         = "MAGE",
  ["Paladin"]      = "PALADIN",
  ["Priest"]       = "PRIEST",
  ["Rogue"]        = "ROGUE",
  ["Shaman"]       = "SHAMAN",
  ["Warlock"]      = "WARLOCK",
  ["Warrior"]      = "WARRIOR",
}

-- Hand-crafted short labels for every known WotLK / Cata boss.
local BOSS_SHORT = {
  -- Naxxramas
  ["Anub'Rekhan"]            = "Anub'R",
  ["Grand Widow Faerlina"]   = "GWFaerl",
  ["Maexxna"]                = "Maexxna",
  ["Noth the Plaguebringer"] = "Noth",
  ["Heigan the Unclean"]     = "Heigan",
  ["Loatheb"]                = "Loatheb",
  ["Instructor Razuvious"]   = "Ins-Raz",
  ["Gothik the Harvester"]   = "Gothik",
  ["The Four Horsemen"]      = "4Horse",
  ["Patchwerk"]              = "Patchw",
  ["Grobbulus"]              = "Grobb",
  ["Gluth"]                  = "Gluth",
  ["Thaddius"]               = "Thaddius",
  ["Sapphiron"]              = "Sapphi",
  ["Kel'Thuzad"]             = "Kel'Thz",
  -- Ulduar
  ["Flame Leviathan"]        = "FlLev",
  ["Ignis the Furnace Master"] = "Ignis",
  ["Razorscale"]             = "Razorsc",
  ["XT-002 Deconstructor"]   = "XT-002",
  ["Assembly of Iron"]       = "Assemb",
  ["Kologarn"]               = "Kologarn",
  ["Auriaya"]                = "Auriaya",
  ["Hodir"]                  = "Hodir",
  ["Thorim"]                 = "Thorim",
  ["Freya"]                  = "Freya",
  ["Mimiron"]                = "Mimiron",
  ["General Vezax"]          = "Vezax",
  ["Yogg-Saron"]             = "Yogg-S",
  ["Algalon the Observer"]   = "Algalon",
  -- Trial of the Crusader
  ["Northrend Beasts"]       = "Beasts",
  ["Lord Jaraxxus"]          = "Jaraxxus",
  ["Faction Champions"]      = "Faction",
  ["Twin Val'kyr"]           = "TwinVk",
  ["Anub'arak"]              = "Anub'ark",
  -- Icecrown Citadel
  ["Lord Marrowgar"]         = "Marrow",
  ["Lady Deathwhisper"]      = "LadyD",
  ["Gunship Battle"]         = "Gunship",
  ["Deathbringer Saurfang"]  = "DBS",
  ["Festergut"]              = "Fester",
  ["Rotface"]                = "Rotface",
  ["Professor Putricide"]    = "PP",
  ["Blood Prince Council"]   = "BPC",
  ["Blood-Queen Lana'thel"]  = "BQL",
  ["Valithria Dreamwalker"]  = "Valithr",
  ["Sindragosa"]             = "Sindra",
  ["The Lich King"]          = "LK",
  -- Other WotLK / Ruby Sanctum
  ["General Zarithrian"]     = "Zarith",
  ["Saviana Ragefire"]       = "Saviana",
  ["Baltharus the Warborn"]  = "Balthar",
  ["Malygos"]                = "Malygos",
  ["Sartharion"]             = "Sarthar",
  ["Onyxia"]                 = "Onyxia",
  ["Halion"]                 = "Halion",
  ["Archavon the Stone Watcher"] = "Archavon",
  ["Emalon the Storm Watcher"]   = "Emalon",
  ["Koralon the Flame Watcher"]  = "Koralon",
  ["Toravon the Ice Watcher"]    = "Toravon",
}

local function shortBoss(name)
  if not name or name == "" then return "?" end
  local s = BOSS_SHORT[name]
  if s then return s end
  if #name <= 8 then return name end
  return name:sub(1, 7) .. "."
end

local function setClassIcon(tex, className)
  local token = classTokenByName[className]
  if not token or not CLASS_ICON_TCOORDS or not CLASS_ICON_TCOORDS[token] then
    tex:Hide()
    return
  end
  local coords = CLASS_ICON_TCOORDS[token]
  tex:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
  tex:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
  tex:Show()
end

local function makeCell(parent, x, w, align)
  local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fs:SetPoint(align or "LEFT", parent, "LEFT", x, 0)
  fs:SetWidth(w)
  if align == "RIGHT" then
    fs:SetJustifyH("RIGHT")
  else
    fs:SetJustifyH("LEFT")
  end
  return fs
end

-- Alias the shared global so existing call-sites in this file stay unchanged.
local pctColor = WowLogsPctColor

-- Single separator after the name+avg block (Avg % RIGHT=178 → 182) and after Points (232 → 236).
-- The Player column (RIGHT=168) and Avg% (RIGHT=178) are only 10 px apart so they share one border.
local COL_DIVIDERS = { 182, 236 }

-- Draw a 1-px vertical separator on `parent` at the given x offset.
local function makeSep(parent)
  local t = parent:CreateTexture(nil, "ARTWORK")
  t:SetWidth(1)
  t:SetHeight(rowHeight)
  t:SetTexture(THEME.border[1], THEME.border[2], THEME.border[3], THEME.border[4])
  return t
end

-- Place fixed-column + boss-column separators onto a row or header frame.
local function addDividers(parent)
  for _, x in ipairs(COL_DIVIDERS) do
    local t = makeSep(parent)
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", x, 0)
  end
  -- Separator goes 2 px AFTER the right edge of each boss column slot so
  -- numbers never overlap the bar.  Slot s has its right edge at
  -- FIXED_END_X + (s-1)*BOSS_COL_W, so separator is at that + 2.
  for slot = 1, MAX_VIS_BOSSES - 1 do
    local x = FIXED_END_X + (slot - 1) * BOSS_COL_W + 2
    local t = makeSep(parent)
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", x, 0)
  end
end

function WowLogsRaidPartyUI.SetMode(mode)
  if mode == "guildRank" then
    activeMode = "guildRank"
  else
    activeMode = "raidParty"
  end
end

local function hasRankingsData()
  if activeMode == "guildRank" then
    return WowLogsDataStore.HasGuildRankData()
  end
  return WowLogsDataStore.HasRaidPartyData()
end

local function getTableData()
  if activeMode == "guildRank" then
    return WowLogsDataStore.GetGuildRankRows()
  end
  return WowLogsDataStore.GetRaidPartyRows()
end

local function frameTitle()
  if activeMode == "guildRank" then
    return "WoW Logs — Guild Rankings"
  end
  return "WoW Logs — Raid / Party Rankings"
end

-- Update boss header label positions based on current bossPageOffset.
local function refreshBossHeaders()
  local nBosses = #bossCols
  for slot = 1, MAX_VIS_BOSSES do
    local cell = headerCells[4 + slot]
    if not cell then break end
    local bossIdx = bossPageOffset + slot
    if bossIdx <= nBosses then
      cell:SetText(shortBoss(bossCols[bossIdx]))
      cell:Show()
    else
      cell:Hide()
    end
  end

  -- Show/hide nav buttons
  if frame.bossLeft then
    if bossPageOffset > 0 then frame.bossLeft:Show() else frame.bossLeft:Hide() end
  end
  if frame.bossRight then
    if bossPageOffset + MAX_VIS_BOSSES < nBosses then
      frame.bossRight:Show()
    else
      frame.bossRight:Hide()
    end
  end
end

local function refreshHeaders()
  local _, bosses = getTableData()
  bossCols = bosses or {}
  bossPageOffset = 0
  refreshBossHeaders()
end

local function refreshRows()
  local dataRows, _, meta = getTableData()
  local numRows = dataRows and #dataRows or 0
  local offset  = FauxScrollFrame_GetOffset(frame.scroll)

  if frame.footer then
    if meta and meta.sliceSummary and meta.sliceSummary ~= "" then
      frame.footer:SetText(meta.sliceSummary)
    elseif meta then
      frame.footer:SetText(string.format(
        "Raid/Party · %s · %s · %s · %s · %d/%d matched · %d not on site",
        meta.raidName  or "?",
        meta.difficulty or "?",
        meta.ladder    or "?",
        meta.season and ("S"..meta.season) or "?",
        meta.matchedCount   or 0,
        meta.requestedCount or 0,
        meta.notFoundCount  or 0
      ))
    else
      frame.footer:SetText("")
    end
  end

  for i = 1, visibleRows do
    local row   = rows[i]
    local idx   = i + offset
    local entry = dataRows and dataRows[idx]
    if entry then
      row:Show()
      setClassIcon(row.classIcon, entry.class)
      row.playerCell:SetText(entry.playerName or "-")

      -- Avg % — colour-coded by percentile tier
      local avgPct = entry.avgPercentile
      if avgPct then
        row.avgCell:SetText(string.format("%.1f", avgPct))
        row.avgCell:SetTextColor(pctColor(avgPct))
      else
        row.avgCell:SetText("-")
        row.avgCell:SetTextColor(THEME.muted[1], THEME.muted[2], THEME.muted[3], 0.8)
      end

      -- Points: multi-spec breakdown (up to 3) or single value
      local specLineColors = {
        { 0.78, 0.61, 1.00, 1   },
        { 0.40, 0.72, 1.00, 0.9 },
        { 0.40, 0.90, 0.60, 0.9 },
      }
      if entry.specPoints and #entry.specPoints > 1 then
        row.pointsCell:Hide()
        for li = 1, 3 do
          local fl = row["specLine" .. li]
          local sp = entry.specPoints[li]
          if sp and fl then
            local c = specLineColors[li]
            fl:SetText(string.sub(sp.spec or "", 1, 2) .. ":" .. string.format("%.0f", sp.points))
            fl:SetTextColor(c[1], c[2], c[3], c[4])
            fl:Show()
          elseif fl then
            fl:Hide()
          end
        end
      else
        for li = 1, 3 do
          local fl = row["specLine" .. li]
          if fl then fl:Hide() end
        end
        row.pointsCell:SetText(
          entry.allStarPoints and string.format("%.1f", entry.allStarPoints) or "-"
        )
        row.pointsCell:Show()
      end

      -- Boss percentiles — each cell colour-coded by its own tier
      for slot = 1, MAX_VIS_BOSSES do
        local cell    = row.bossCells[slot]
        local bossIdx = bossPageOffset + slot
        if cell and entry.bossPercentiles and bossIdx <= #bossCols then
          cell:Show()
          local val = entry.bossPercentiles[bossIdx]
          if val then
            cell:SetText(string.format("%.0f", val))
            cell:SetTextColor(pctColor(val))
          else
            cell:SetText("-")
            cell:SetTextColor(THEME.muted[1], THEME.muted[2], THEME.muted[3], 0.8)
          end
        elseif cell then
          cell:Hide()
        end
      end
      if idx % 2 == 0 and row.bg then
        row.bg:SetTexture(0.14, 0.15, 0.18, 0.32)
      elseif row.bg then
        row.bg:SetTexture(0, 0, 0, 0)
      end
    else
      row:Hide()
    end
  end

  FauxScrollFrame_Update(frame.scroll, numRows, visibleRows, rowHeight)
end

local function ensureFrame()
  if frame then return frame end

  frame = CreateFrame("Frame", "WowLogsRaidPartyFrame", UIParent)
  frame:SetSize(720, 500)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("FULLSCREEN_DIALOG")
  frame:Hide()
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

  if frame.SetBackdrop then
    frame:SetBackdrop({
      bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 32,
      insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    frame:SetBackdropColor(THEME.bg[1], THEME.bg[2], THEME.bg[3], THEME.bg[4])
  end

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", frame, "TOP", -45, -14)  -- offset left to clear the 3 top-right buttons
  frame.titleText = title
  title:SetText(frameTitle())

  -- ── 3 compact top-right buttons: [◄] [►] [✕] ──
  local btnClose = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  btnClose:SetSize(26, 22)
  btnClose:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -12)
  btnClose:SetText("X")
  btnClose:SetScript("OnClick", function() frame:Hide() end)

  frame.bossRight = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.bossRight:SetSize(26, 22)
  frame.bossRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -40, -12)
  frame.bossRight:SetText(">")
  frame.bossRight:Hide()
  frame.bossRight:SetScript("OnClick", function()
    bossPageOffset = math.min(math.max(0, #bossCols - MAX_VIS_BOSSES), bossPageOffset + 1)
    refreshBossHeaders()
    refreshRows()
  end)

  frame.bossLeft = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.bossLeft:SetSize(26, 22)
  frame.bossLeft:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -70, -12)
  frame.bossLeft:SetText("<")
  frame.bossLeft:Hide()
  frame.bossLeft:SetScript("OnClick", function()
    bossPageOffset = math.max(0, bossPageOffset - 1)
    refreshBossHeaders()
    refreshRows()
  end)

  -- ── header bar ──
  frame.headerBar = CreateFrame("Frame", nil, frame)
  frame.headerBar:SetSize(680, rowHeight)
  frame.headerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -44)

  headerCells[1] = makeCell(frame.headerBar, 28,  140, "LEFT")   -- Player
  headerCells[1]:SetText("Player")
  headerCells[2] = makeCell(frame.headerBar, 178,  48, "RIGHT")  -- Avg %
  headerCells[2]:SetText("Avg %")
  headerCells[3] = makeCell(frame.headerBar, 232,  56, "RIGHT")  -- Points
  headerCells[3]:SetText("Points")
  headerCells[4] = makeCell(frame.headerBar, 292,   4, "LEFT")   -- spacer

  -- Boss header cells (slots 1..MAX_VIS_BOSSES)
  for slot = 1, MAX_VIS_BOSSES do
    local x = FIXED_END_X + (slot - 1) * BOSS_COL_W
    local cell = makeCell(frame.headerBar, x, BOSS_COL_W - 4, "RIGHT")
    cell:Hide()
    headerCells[4 + slot] = cell
  end

  addDividers(frame.headerBar)

  -- ── table panel ──
  frame.tablePanel = CreateFrame("Frame", nil, frame)
  frame.tablePanel:SetSize(680, 370)
  frame.tablePanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -76)

  frame.scroll = CreateFrame(
    "ScrollFrame", "WowLogsRaidPartyScroll",
    frame.tablePanel, "FauxScrollFrameTemplate"
  )
  frame.scroll:SetPoint("TOPLEFT",     frame.tablePanel, "TOPLEFT",     0,   -4)
  frame.scroll:SetPoint("BOTTOMRIGHT", frame.tablePanel, "BOTTOMRIGHT", -24,  4)

  for i = 1, visibleRows do
    local row = CreateFrame("Button", nil, frame.tablePanel)
    row:SetSize(660, rowHeight)
    row:SetPoint("TOPLEFT", frame.tablePanel, "TOPLEFT", 0, -4 - (i - 1) * rowHeight)

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints(row)

    row.classIcon = row:CreateTexture(nil, "ARTWORK")
    row.classIcon:SetSize(16, 16)
    row.classIcon:SetPoint("LEFT", row, "LEFT", 4, 0)

    row.playerCell = makeCell(row,  28, 140, "LEFT")
    row.avgCell    = makeCell(row, 178,  48, "RIGHT")
    row.pointsCell = makeCell(row, 232,  56, "RIGHT")

    -- Extra FontStrings for multi-spec points breakdown (hidden by default).
    -- rowHeight=30: 3 lines of 9pt tile into thirds: y=+10, 0, -10.
    local specLineColors = {
      { 0.78, 0.61, 1.00, 1   },  -- soft purple  (spec 1)
      { 0.40, 0.72, 1.00, 0.9 },  -- soft blue    (spec 2)
      { 0.40, 0.90, 0.60, 0.9 },  -- soft green   (spec 3)
    }
    local specLineY = { 10, 0, -10 }
    for li = 1, 3 do
      local fl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      fl:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
      fl:SetPoint("RIGHT", row, "LEFT", 232, specLineY[li])
      fl:SetWidth(54)
      fl:SetJustifyH("RIGHT")
      fl:Hide()
      row["specLine" .. li] = fl
    end

    row.bossCells = {}
    for slot = 1, MAX_VIS_BOSSES do
      local x    = FIXED_END_X + (slot - 1) * BOSS_COL_W
      local cell = makeCell(row, x, BOSS_COL_W - 4, "RIGHT")
      cell:Hide()
      row.bossCells[slot] = cell
    end

    addDividers(row)
    rows[i] = row
  end

  frame.scroll:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, rowHeight, refreshRows)
  end)

  -- ── footer ──
  frame.footer = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.footer:SetPoint("BOTTOM", frame, "BOTTOM", 0, 14)
  frame.footer:SetWidth(680)
  frame.footer:SetJustifyH("CENTER")
  frame.footer:SetTextColor(THEME.accent[1], THEME.accent[2], THEME.accent[3], 1)

  -- ── empty hint ──
  frame.emptyHint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.emptyHint:SetPoint("CENTER", frame.tablePanel, "CENTER", 0, 0)
  frame.emptyHint:SetWidth(520)
  frame.emptyHint:SetJustifyH("CENTER")
  frame.emptyHint:SetText(
    "No raid/party rankings loaded.\n"..
    "Export roster in-game → paste in Native Uploader → Send to addon → /reload"
  )
  frame.emptyHint:SetTextColor(THEME.muted[1], THEME.muted[2], THEME.muted[3], 1)

  return frame
end

function WowLogsGuildRankUI.Toggle()
  WowLogsRaidPartyUI.SetMode("guildRank")
  WowLogsRaidPartyUI.Toggle()
end

function WowLogsRaidPartyUI.Refresh()
  ensureFrame()
  if frame.titleText then
    frame.titleText:SetText(frameTitle())
  end
  if not hasRankingsData() then
    frame.emptyHint:Show()
    for i = 1, visibleRows do rows[i]:Hide() end
    frame.footer:SetText("")
    return
  end
  frame.emptyHint:Hide()
  refreshHeaders()
  refreshRows()
end

function WowLogsRaidPartyUI.Toggle()
  ensureFrame()
  if frame:IsShown() then
    frame:Hide()
  else
    if not hasRankingsData() then
      if activeMode == "guildRank" then
        print("|cffff8800[WoW Logs]|r No guild rankings in payload. Sync via Native Uploader first.")
      else
        print("|cffff8800[WoW Logs]|r No raid/party rankings in payload. Sync via Native Uploader first.")
      end
    end
    WowLogsRaidPartyUI.Refresh()
    frame:Show()
  end
end
