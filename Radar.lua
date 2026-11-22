local FAM = FactionAggroMonitor

local function MakeDot(parent, color, size)
    local dot = parent:CreateTexture(nil, "OVERLAY")
    dot:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    dot:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    dot:SetWidth(size); dot:SetHeight(size)
    return dot
end

local function MakeSegment(parent, color)
    local segment = parent:CreateTexture(nil, "BORDER")
    segment:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    segment:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    segment:SetHeight(1)
    return segment
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
    local centerH = area:CreateTexture(nil, "BORDER")
    centerH:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    centerH:SetVertexColor(0.6, 0.6, 0.6, 0.35)
    centerH:SetWidth(2); centerH:SetHeight(1); centerH:SetPoint("CENTER")
    local centerV = area:CreateTexture(nil, "BORDER")
    centerV:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    centerV:SetVertexColor(0.6, 0.6, 0.6, 0.35)
    centerV:SetWidth(1); centerV:SetHeight(2); centerV:SetPoint("CENTER")

    self.rings = {}
    for i = 1, 2 do
        local ring = { segments = {} }
        local color = i == 1 and {0.2, 0.9, 0.35, 0.95} or {1, 0.65, 0.1, 0.95}
        for n = 1, 32 do ring.segments[n] = MakeSegment(area, color) end
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
    local size = math.min(self.area:GetWidth(), self.area:GetHeight())
    local radii = { self.db.radius, self.db.radius + self.db.safetyRadius }
    for i, ring in ipairs(self.rings) do
        local fraction = math.min(0.95, radii[i] / 0.05)
        local radius = size * fraction
        local segmentLength = math.max(2, (2 * radius * math.sin(math.pi / 32)) + 1)
        for n, segment in ipairs(ring.segments) do
            local angle = ((n - 1) * 2 * math.pi / 32)
            local x, y = math.cos(angle) * radius, math.sin(angle) * radius
            segment:ClearAllPoints()
            segment:SetPoint("CENTER", self.area, "CENTER", x, y)
            segment:SetWidth(segmentLength)
            segment:SetRotation(angle + (math.pi / 2))
        end
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
