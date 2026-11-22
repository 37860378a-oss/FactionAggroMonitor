FactionAggroMonitor = FactionAggroMonitor or {}
local FAM = FactionAggroMonitor
FAM.VERSION = "0.3.1"

local defaults = {
    enabled = true, radius = 0.025, safetyRadius = 0.00625,
    updateRate = 0.20, radarSize = 240, rangeSpell = "Exorcismo",
    showPlayers = true, showTargets = true, showMouseover = true,
    showFocus = true, showBossUnits = true, locked = false,
    point = "CENTER", relativePoint = "CENTER", x = 0, y = 0,
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
        self:Print("Radio invalido. Usa un valor entre 0.001 y 0.5 (unidades normalizadas del mapa).")
        return
    end
    self.db.radius = value
    self:Print("Radio visual actualizado: " .. tostring(value))
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
