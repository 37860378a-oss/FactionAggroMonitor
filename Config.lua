FactionAggroMonitor = FactionAggroMonitor or {}
local FAM = FactionAggroMonitor
FAM.VERSION = "1.0.1"

local defaults = {
    enabled = true, radius = 0.025, safetyRadius = 0.00625,
    updateRate = 0.50, radarSize = 240, memorySeconds = 60,
    faction = "enemies", combat = "any", nameFilter = "",
    locked = false, point = "CENTER", relativePoint = "CENTER", x = 0, y = 0,
}

function FAM:InitializeDB()
    if type(FactionAggroMonitorDB) ~= "table" then FactionAggroMonitorDB = {} end
    for key, value in pairs(defaults) do
        if FactionAggroMonitorDB[key] == nil then FactionAggroMonitorDB[key] = value end
    end
    self.db = FactionAggroMonitorDB
end

function FAM:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffd98b35[FAM]|r " .. tostring(message))
end

function FAM:SetRadius(value)
    value = tonumber(value)
    if not value or value <= 0 or value > 0.5 then
        self:Print("Radio invalido. Usa un valor entre 0.001 y 0.5.")
        return
    end
    self.db.radius = value
    self:Print("Radio visual actualizado: " .. tostring(value) .. " (no representa yardas).")
    if self.UpdateRadarGeometry then self:UpdateRadarGeometry() end
    if self.Refresh then self:Refresh() end
end

function FAM:ResetPosition()
    self.db.point, self.db.relativePoint = "CENTER", "CENTER"
    self.db.x, self.db.y = 0, 0
    if self.frame then
        self.frame:ClearAllPoints()
        self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end
