-- Guild roster JSON export for wow-logs web import (manual copy/paste).
-- WoW 3.3.x API: GetGuildRosterInfo, GuildControlGetNumRanks, GuildControlGetRankName

WowLogsGuildExport = {}

local SCHEMA_VERSION = 1

local function jsonEscape(s)
  if s == nil then
    return ""
  end
  s = tostring(s)
  s = s:gsub("\\", "\\\\")
  s = s:gsub("\"", "\\\"")
  s = s:gsub("\n", "\\n")
  s = s:gsub("\r", "\\r")
  s = s:gsub("\t", "\\t")
  return s
end

local function encodeValue(v, depth)
  depth = depth or 0
  local t = type(v)
  if t == "string" then
    return "\"" .. jsonEscape(v) .. "\""
  elseif t == "number" then
    if v ~= v then
      return "null"
    end -- nan
    return string.format("%.14g", v)
  elseif t == "boolean" then
    return v and "true" or "false"
  elseif t == "table" then
    -- Empty {} in Lua: encode as JSON [] (export has no empty objects today)
    if next(v) == nil then
      return "[]"
    end
    -- array: consecutive integer keys from 1
    local n = #v
    local isArray = n > 0
    if isArray then
      for k, _ in pairs(v) do
        if type(k) ~= "number" or k < 1 or k > n or math.floor(k) ~= k then
          isArray = false
          break
        end
      end
    end
    if isArray then
      local parts = {}
      for i = 1, n do
        parts[i] = encodeValue(v[i], depth + 1)
      end
      return "[" .. table.concat(parts, ",") .. "]"
    end
    local parts = {}
    for k, val in pairs(v) do
      if type(k) == "string" then
        parts[#parts + 1] = "\"" .. jsonEscape(k) .. "\":" .. encodeValue(val, depth + 1)
      end
    end
    table.sort(parts)
    return "{" .. table.concat(parts, ",") .. "}"
  end
  return "null"
end

function WowLogsGuildExport.BuildPayload()
  if not IsInGuild() then
    return nil, "You are not in a guild."
  end

  GuildRoster()

  local guildName = GetGuildInfo("player")
  local realm = GetRealmName() or ""

  local ranks = {}
  local numRanks = GuildControlGetNumRanks and GuildControlGetNumRanks() or 0
  if numRanks and numRanks > 0 then
    for i = 1, numRanks do
      local rankName = GuildControlGetRankName(i)
      ranks[#ranks + 1] = {
        rankIndex = i - 1,
        name = rankName or "",
      }
    end
  end

  local roster = {}
  local numMembers = GetNumGuildMembers(true) or 0
  for i = 1, numMembers do
    local name,
      rankName,
      rankIndex,
      level,
      classLocalized,
      zone,
      publicNote,
      officerNote,
      onlineFlag,
      status = GetGuildRosterInfo(i)
    if name and name ~= "" then
      roster[#roster + 1] = {
        name = name,
        rankName = rankName or "",
        rankIndex = rankIndex,
        level = level,
        class = classLocalized or "",
        zone = zone or "",
        publicNote = publicNote or "",
        officerNote = officerNote or "",
        online = (onlineFlag == 1 or onlineFlag == true),
        status = status,
      }
    end
  end

  local payload = {
    schemaVersion = SCHEMA_VERSION,
    exportedAt = time(),
    guildName = guildName or "",
    realm = realm,
    ranks = ranks,
    roster = roster,
    memberCount = #roster,
  }

  return payload, nil
end

function WowLogsGuildExport.BuildJson()
  local payload, err = WowLogsGuildExport.BuildPayload()
  if not payload then
    return nil, err
  end
  return encodeValue(payload), nil
end

-- Modal panel with scrollable edit box for Ctrl+A / Ctrl+C
local exportFrame

local function ensureExportFrame()
  if exportFrame then
    return exportFrame
  end

  local f = CreateFrame("Frame", "WowLogsGuildExportFrame", UIParent)
  f:SetSize(560, 420)
  f:SetPoint("CENTER")
  f:SetFrameStrata("FULLSCREEN_DIALOG")
  f:Hide()
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)

  if f.SetBackdrop then
    f:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true,
      tileSize = 32,
      edgeSize = 32,
      insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    f:SetBackdropColor(0, 0, 0, 0.95)
  end

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", f, "TOP", 0, -16)
  title:SetText("Guild roster export (JSON)")

  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hint:SetPoint("TOP", f, "TOP", 0, -40)
  hint:SetWidth(520)
  hint:SetJustifyH("CENTER")
  hint:SetText("Select all (Ctrl+A), copy (Ctrl+C), paste into wow-logs. Run /wla exportguild again after opening the Guild roster tab if the list looks empty.")

  local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  closeBtn:SetSize(100, 24)
  closeBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
  closeBtn:SetText("Close")
  closeBtn:SetScript("OnClick", function()
    f:Hide()
  end)

  local scroll = CreateFrame("ScrollFrame", "WowLogsGuildExportScroll", f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -68)
  scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 48)

  local edit = CreateFrame("EditBox", "WowLogsGuildExportEdit", scroll)
  edit:SetMultiLine(true)
  edit:SetAutoFocus(false)
  edit:SetFontObject(GameFontHighlightSmall)
  edit:SetWidth(500)
  edit:SetHeight(280)
  edit:SetTextInsets(8, 8, 8, 8)
  edit:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)
  scroll:SetScrollChild(edit)

  f.editBox = edit
  exportFrame = f
  return exportFrame
end

-- EditBox:GetTextHeight() does not exist in WoW 3.3.x; approximate from newlines + wrap.
local function estimateHeightForJsonText(text)
  text = text or ""
  local lines = 1
  for _ in string.gmatch(text, "\n") do
    lines = lines + 1
  end
  local approxCharsPerLine = 72
  local wrapLines = math.max(1, math.ceil(#text / approxCharsPerLine))
  lines = math.max(lines, wrapLines)
  local lineHeight = 13
  return math.max(280, math.min(8000, lines * lineHeight + 24))
end

function WowLogsGuildExport.ShowDialog()
  local jsonStr, err = WowLogsGuildExport.BuildJson()
  local fr = ensureExportFrame()
  if err or not jsonStr then
    print("|cffff8800[WoW Logs]|r Guild export: " .. tostring(err or "unknown error"))
    return
  end
  fr.editBox:SetText(jsonStr)
  fr.editBox:SetTextInsets(8, 8, 8, 8)
  fr.editBox:SetHeight(estimateHeightForJsonText(jsonStr))
  fr:Show()
  fr.editBox:SetFocus()
  fr.editBox:HighlightText()
  print("|cffff8800[WoW Logs]|r Guild JSON ready (" .. tostring(#jsonStr) .. " chars). Copy from the window or run |cffffffff/wla exportguild|r again.")
end
