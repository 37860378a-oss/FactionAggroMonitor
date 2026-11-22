local FAM = FactionAggroMonitor
local elapsed = 0

local function GetMapPosition(unit)
    if not UnitExists(unit) then return nil end
    local x, y = GetPlayerMapPosition(unit)
    if not x or not y or (x == 0 and y == 0) then return nil end
    return x, y
end

local function AddUnit(units, unit, label, color)
    if UnitExists(unit) then
        local x, y = GetMapPosition(unit)
        if x and y then
            table.insert(units, { token = unit, label = label or UnitName(unit), x = x, y = y, color = color })
        end
    end
end

function FAM:GetTargetRangeText()
    if not UnitExists("target") then return "|cffaaaaaaSin objetivo|r" end
    local spellName = self.db.rangeSpell or "Exorcismo"
    local inRange = IsSpellInRange(spellName, "target")
    local targetName = UnitName("target") or "Objetivo"
    if inRange == 1 or inRange == true then
        return "|cff33ff66" .. targetName .. " - " .. spellName .. ": EN RANGO|r"
    elseif inRange == 0 or inRange == false then
        return "|cffff5555" .. targetName .. " - " .. spellName .. ": FUERA DE RANGO|r"
    end
    return "|cffffcc55" .. targetName .. " - " .. spellName .. ": SIN DATO|r"
end

function FAM:CollectUnits()
    local units = {}
    SetMapToCurrentZone()
    local px, py = GetMapPosition("player")

    -- Collect available unit coordinates even if the player's map position is missing.
    if self.db.showPlayers then
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                AddUnit(units, "raid" .. i, UnitName("raid" .. i), {0.25, 0.65, 1})
            end
        elseif GetNumPartyMembers() > 0 then
            AddUnit(units, "player", UnitName("player"), {0.25, 0.65, 1})
            for i = 1, GetNumPartyMembers() do
                AddUnit(units, "party" .. i, UnitName("party" .. i), {0.25, 0.65, 1})
            end
        else
            AddUnit(units, "player", UnitName("player"), {0.25, 0.65, 1})
        end
    end
    if self.db.showTargets then AddUnit(units, "target", "Target", {1, 0.2, 0.2}) end
    if self.db.showMouseover then AddUnit(units, "mouseover", "Mouseover", {1, 0.75, 0.15}) end
    if self.db.showFocus then AddUnit(units, "focus", "Focus", {0.8, 0.3, 1}) end
    if self.db.showBossUnits then
        for i = 1, 5 do AddUnit(units, "boss" .. i, "Boss " .. i, {1, 0.2, 0.2}) end
    end
    return units, px, py
end

function FAM:Refresh()
    if not self.frame or not self.db.enabled then return end
    self:ClearDots()
    local rangeText = self:GetTargetRangeText()
    local units, px, py = self:CollectUnits()
    local areaW, areaH = self.area:GetWidth(), self.area:GetHeight()
    local shown = 0

    -- Always keep the player's center marker visible; map coordinates are optional.
    self:PlaceDot("player-center", 0.5, 0.5, {0.2, 1, 0.4}, 9)

    if not px or not py then
        self:SetStatus(rangeText .. " | Sin coordenadas del jugador")
        return
    end

    local scale = math.min(areaW, areaH) / 0.10
    for i, unit in ipairs(units) do
        if unit.token ~= "player" then
            local dx, dy = unit.x - px, unit.y - py
            local nx, ny = 0.5 + (dx * scale / areaW), 0.5 + (dy * scale / areaH)
            if nx >= 0 and nx <= 1 and ny >= 0 and ny <= 1 then
                self:PlaceDot("unit" .. i, nx, ny, unit.color, 7)
                shown = shown + 1
            end
        end
    end
    self:SetStatus(rangeText .. " | Unidades visibles: " .. shown)
end

SLASH_FACTIONAGGROMONITOR1 = "/fam"
SlashCmdList["FACTIONAGGROMONITOR"] = function(message)
    local command, value = string.match(message or "", "^(%S*)%s*(.-)$")
    command = string.lower(command or "")
    if command == "reset" then
        FAM:ResetPosition(); FAM:Print("Posicion del radar restaurada.")
    elseif command == "range" then
        FAM:SetRadius(value)
    elseif command == "spell" then
        if value and value ~= "" then
            FAM.db.rangeSpell = value
            FAM:Print("Habilidad de referencia: " .. value)
            FAM:Refresh()
        else
            FAM:Print("Uso: /fam spell Exorcismo")
        end
    elseif command == "lock" then
        FAM.db.locked = not FAM.db.locked
        FAM:Print("Radar " .. (FAM.db.locked and "bloqueado." or "desbloqueado."))
    else
        if FAM.frame:IsShown() then FAM.frame:Hide() else FAM.frame:Show() end
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:SetScript("OnEvent", function(self, event, addon)
    if event == "ADDON_LOADED" then
        if addon ~= "FactionAggroMonitor" then return end
        FAM:InitializeDB(); FAM:CreateRadar()
        FAM:Print("v" .. FAM.VERSION .. " cargado. /fam para mostrar u ocultar.")
    elseif event == "PLAYER_ENTERING_WORLD" then
        if FAM.Refresh then FAM:Refresh() end
    end
end)
local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function(self, delta)
    if not FAM.db or not FAM.db.enabled or not FAM.frame or not FAM.frame:IsShown() then return end
    elapsed = elapsed + delta
    if elapsed >= FAM.db.updateRate then elapsed = 0; FAM:Refresh() end
end)
