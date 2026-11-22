local FAM = FactionAggroMonitor
local function MakeDot(parent, color, size)
    local dot = parent:CreateTexture(nil, "OVERLAY")
    dot:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    dot:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    dot:SetWidth(size); dot:SetHeight(size)
    return dot
end
local function MakeLine(parent, color, width, height)
    local line = parent:CreateTexture(nil, "BORDER")
    line:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    line:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    line:SetWidth(width); line:SetHeight(height)
    return line
end

function FAM:CreateRadar()
    if self.frame then return end
    local frame = CreateFrame("Frame", "FactionAggroMonitorFrame", UIParent)
    frame:SetWidth(self.db.radarSize); frame:SetHeight(self.db.radarSize)
    frame:SetPoint(self.db.point, UIParent, self.db.relativePoint, self.db.x, self.db.y)
    frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    frame:SetBackdropColor(0.02, 0.02, 0.02, 0.88)
    frame:SetScript("OnDragStart", function()
        if not FAM.db.locked then frame:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, relativePoint, x, y = frame:GetPoint()
        FAM.db.point, FAM.db.relativePoint, FAM.db.x, FAM.db.y = point, relativePoint, x, y
    end)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -9); title:SetText("Faction Aggro Monitor")
    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -3)
    subtitle:SetText("Mapa relativo - calibracion pendiente")
    self.subtitle = subtitle

    local area = CreateFrame("Frame", nil, frame)
    area:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -42)
    area:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 28)
    self.area = area
    local bg = area:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(area); bg:SetTexture(0.08, 0.08, 0.08, 0.75)
    local centerH = MakeLine(area, {0.6, 0.6, 0.6, 0.35}, 2, 1); centerH:SetPoint("CENTER")
    local centerV = MakeLine(area, {0.6, 0.6, 0.6, 0.35}, 1, 2); centerV:SetPoint("CENTER")

    self.rings = {}
    for i = 1, 2 do
        local ring = { parts = {} }
        local c = i == 1 and {0.2, 0.8, 0.35, 0.8} or {1, 0.65, 0.1, 0.9}
        ring.parts.top = MakeLine(area, c, 2, 1)
        ring.parts.bottom = MakeLine(area, c, 2, 1)
        ring.parts.left = MakeLine(area, c, 1, 2)
        ring.parts.right = MakeLine(area, c, 1, 2)
        self.rings[i] = ring
    end
    self.dots = {}
    self.status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.status:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 9)
    self.status:SetText("Esperando coordenadas...")
    self.frame = frame
    self:UpdateRadarGeometry()
end

function FAM:UpdateRadarGeometry()
    if not self.area then return end
    local w, h = self.area:GetWidth(), self.area:GetHeight()
    local size = math.min(w, h)
    local radii = { self.db.radius, self.db.radius + self.db.safetyRadius }
    for i, ring in ipairs(self.rings) do
        local fraction = math.min(0.95, radii[i] / 0.05)
        local rw, rh = size * fraction * 2, size * fraction * 2
        ring.parts.top:ClearAllPoints()
        ring.parts.top:SetPoint("BOTTOM", self.area, "CENTER", 0, rh / 2)
        ring.parts.top:SetWidth(rw)
        ring.parts.bottom:ClearAllPoints()
        ring.parts.bottom:SetPoint("TOP", self.area, "CENTER", 0, -rh / 2)
        ring.parts.bottom:SetWidth(rw)
        ring.parts.left:ClearAllPoints()
        ring.parts.left:SetPoint("RIGHT", self.area, "CENTER", -rw / 2, 0)
        ring.parts.left:SetHeight(rh)
        ring.parts.right:ClearAllPoints()
        ring.parts.right:SetPoint("LEFT", self.area, "CENTER", rw / 2, 0)
        ring.parts.right:SetHeight(rh)
    end
end

function FAM:ClearDots()
    for _, dot in pairs(self.dots) do dot:Hide() end
end
function FAM:PlaceDot(key, x, y, color, size)
    local dot = self.dots[key]
    if not dot then dot = MakeDot(self.area, color, size or 7); self.dots[key] = dot end
    dot:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    dot:ClearAllPoints()
    dot:SetPoint("CENTER", self.area, "BOTTOMLEFT", x * self.area:GetWidth(), y * self.area:GetHeight())
    dot:Show()
end
function FAM:SetStatus(text)
    if self.status then self.status:SetText(text) end
end
