-- Raid/party roster JSON export for Native Uploader (manual copy/paste).

WowLogsRaidPartyExport = {}

local SCHEMA_VERSION = 1

local function encodeValue(v, depth)
  if WowLogsJson and WowLogsJson.encode then
    return WowLogsJson.encode(v, depth)
  end
  return "null"
end

local function splitNameRealm(fullName)
  if not fullName or fullName == "" then
    return nil, nil
  end
  local name, realm = fullName:match("^([^%-]+)%-(.+)$")
  if name then
    return name, realm
  end
  return fullName, GetRealmName() or ""
end

local function addMember(list, seen, name, realm, className)
  if not name or name == "" then return end
  local key = (name .. "@" .. (realm or "")):lower()
  if seen[key] then return end
  seen[key] = true
  table.insert(list, {
    name = name,
    realm = realm or (GetRealmName() or ""),
    class = className or "",
  })
end

function WowLogsRaidPartyExport.BuildPayload()
  local realm = GetRealmName() or ""
  local members = {}
  local seen = {}
  local groupType = "solo"

  local numRaid = GetNumRaidMembers() or 0
  if numRaid > 0 then
    groupType = "raid"
    for i = 1, numRaid do
      local name, _, _, _, _, className = GetRaidRosterInfo(i)
      if name then
        local n, r = splitNameRealm(name)
        addMember(members, seen, n, r or realm, className)
      end
    end
  else
    local numParty = GetNumPartyMembers() or 0
    if numParty > 0 then
      groupType = "party"
      for i = 1, numParty do
        local unit = "party" .. i
        local name, r = UnitName(unit)
        if name then
          local n, re = splitNameRealm(name)
          local _, classFile = UnitClass(unit)
          addMember(members, seen, n, re or realm, classFile or "")
        end
      end
    end
  end

  local playerName = UnitName("player")
  if playerName then
    local n, r = splitNameRealm(playerName)
    local _, classFile = UnitClass("player")
    addMember(members, seen, n, r or realm, classFile or "")
  end

  if #members == 0 then
    return nil, "You are not in a raid or party."
  end

  return {
    schemaVersion = SCHEMA_VERSION,
    exportedAt = time(),
    groupType = groupType,
    realm = realm,
    members = members,
    memberCount = #members,
  }, nil
end

function WowLogsRaidPartyExport.BuildJson()
  local payload, err = WowLogsRaidPartyExport.BuildPayload()
  if not payload then
    return nil, err
  end
  return encodeValue(payload), nil
end

local exportFrame

local function ensureExportFrame()
  if exportFrame then
    return exportFrame
  end

  local f = CreateFrame("Frame", "WowLogsRaidPartyExportFrame", UIParent)
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
  title:SetText("Raid / Party export (JSON)")

  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hint:SetPoint("TOP", f, "TOP", 0, -40)
  hint:SetWidth(520)
  hint:SetJustifyH("CENTER")
  hint:SetText("Copy (Ctrl+C) and paste into Native Uploader → Raid/Party Rankings. Re-export after roster changes.")

  local closeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  closeBtn:SetSize(100, 24)
  closeBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
  closeBtn:SetText("Close")
  closeBtn:SetScript("OnClick", function()
    f:Hide()
  end)

  local scroll = CreateFrame("ScrollFrame", "WowLogsRaidPartyExportScroll", f, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -68)
  scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -28, 48)

  local edit = CreateFrame("EditBox", "WowLogsRaidPartyExportEdit", scroll)
  edit:SetMultiLine(true)
  edit:SetAutoFocus(false)
  edit:SetFontObject("GameFontHighlightSmall")
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

local function estimateHeightForJsonText(text)
  text = text or ""
  local lines = 1
  for _ in string.gmatch(text, "\n") do
    lines = lines + 1
  end
  local approxCharsPerLine = 72
  local wrapLines = math.max(1, math.ceil(#text / approxCharsPerLine))
  lines = math.max(lines, wrapLines)
  return math.max(280, math.min(8000, lines * 13 + 24))
end

function WowLogsRaidPartyExport.ShowDialog()
  local jsonStr, err = WowLogsRaidPartyExport.BuildJson()
  local fr = ensureExportFrame()
  if err or not jsonStr then
    print("|cffff8800[WoW Logs]|r Raid/Party export: " .. tostring(err or "unknown error"))
    return
  end
  fr.editBox:SetText(jsonStr)
  fr.editBox:SetHeight(estimateHeightForJsonText(jsonStr))
  fr:Show()
  fr.editBox:SetFocus()
  fr.editBox:HighlightText()
  print("|cffff8800[WoW Logs]|r Raid/Party JSON ready (" .. tostring(#jsonStr) .. " chars). Paste into Native Uploader.")
end
