WowLogsMinimap = {}

local btn
local iconPath = "Interface\\Icons\\INV_Misc_EngGizmos_03"

local function ensureMeta()
  WowLogsAddonDB = WowLogsAddonDB or {}
  WowLogsAddonDB.meta = WowLogsAddonDB.meta or {}
  WowLogsAddonDB.meta.minimap = WowLogsAddonDB.meta.minimap or {
    angle = 210,
    hidden = false,
  }
  return WowLogsAddonDB.meta.minimap
end

local function updatePosition()
  if not btn then return end
  local meta = ensureMeta()
  local angle = math.rad(meta.angle or 210)
  local radius = 78
  local x = math.cos(angle) * radius
  local y = math.sin(angle) * radius
  btn:ClearAllPoints()
  btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function showTooltip(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:SetText("WoW Logs", 1, 1, 1)
  GameTooltip:AddLine("Left Click: Open Rankings", 0.85, 0.85, 0.85)
  GameTooltip:AddLine("Right Click: Refresh Hint", 0.85, 0.85, 0.85)
  GameTooltip:Show()
end

function WowLogsMinimap.Init()
  local meta = ensureMeta()
  if meta.hidden == nil then
    meta.hidden = false
  end

  if btn then
    updatePosition()
    if meta.hidden then btn:Hide() else btn:Show() end
    return
  end

  btn = CreateFrame("Button", "WowLogsMinimapButton", Minimap)
  btn:SetFrameStrata("HIGH")
  btn:SetFrameLevel(8)
  btn:SetSize(32, 32)
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  btn:RegisterForDrag("LeftButton")
  btn:SetMovable(true)

  local border = btn:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(54, 54)
  border:SetPoint("TOPLEFT")

  local bg = btn:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  bg:SetSize(20, 20)
  bg:SetPoint("CENTER", 0, 0)

  local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  text:SetPoint("CENTER", 0, 0)
  text:SetText("WL")
  text:SetTextColor(0.95, 0.95, 0.98, 1)
  text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")

  btn:SetScript("OnEnter", showTooltip)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

  btn:SetScript("OnClick", function(_, mouseButton)
    if mouseButton == "RightButton" then
      WowLogsBridge.RequestRefresh()
      return
    end
    WowLogsUI.Toggle()
  end)

  btn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function(s)
      local mx, my = Minimap:GetCenter()
      local px, py = GetCursorPosition()
      local scale = Minimap:GetEffectiveScale()
      px = px / scale
      py = py / scale
      local angle = math.deg(math.atan2(py - my, px - mx))
      meta.angle = angle
      updatePosition()
    end)
  end)

  btn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
  end)

  updatePosition()
  if meta.hidden then
    btn:Hide()
  else
    btn:Show()
  end
end
