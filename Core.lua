local FAM = FactionAggroMonitor
local elapsed = 0
local seenEnemies = {}
local combatEventCount = 0
local hostileEventCount = 0
local HOSTILE_FLAG = COMBATLOG_OBJECT_REACTION_HOSTILE or 0x00000040

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
    -- Additional unit tokens that may be exposed by the client/server.
    AddUnit(units, "targettarget", "TargetTarget", {1, 0.45, 0.2})
    for i = 1, 5 do AddUnit(units, "arena" .. i, "Arena " .. i, {1, 0.2, 0.2}) end
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
    -- Rotate map-relative coordinates so the player's facing always points to the top.
    -- WoW facing is in radians; map X grows east and map Y grows north.
    local facing = GetPlayerFacing and GetPlayerFacing() or nil
    local cosFacing, sinFacing = 1, 0
    if facing then
        cosFacing, sinFacing = math.cos(facing), math.sin(facing)
    end
    for i, unit in ipairs(units) do
        if unit.token ~= "player" then
            local dx, dy = unit.x - px, unit.y - py
            local rx = dx * cosFacing - dy * sinFacing
            local ry = dx * sinFacing + dy * cosFacing
            local nx, ny = 0.5 + (rx * scale / areaW), 0.5 + (ry * scale / areaH)
            if nx >= 0 and nx <= 1 and ny >= 0 and ny <= 1 then
                self:PlaceDot("unit" .. i, nx, ny, unit.color, 7)
                shown = shown + 1
            end
        end
    end
    local enemyCount = 0
    for _ in pairs(seenEnemies) do enemyCount = enemyCount + 1 end
    local headingText = facing and (" | Frente: " .. math.floor((facing * 180 / math.pi) % 360) .. " grados") or " | Sin orientacion"
    self:SetStatus(rangeText .. " | Puntos: " .. shown .. " | Enemigos vistos: " .. enemyCount .. headingText)
end


function FAM:DebugUnits()
    SetMapToCurrentZone()
    local function Report(unit)
        if UnitExists(unit) then
            local name = UnitName(unit) or "?"
            local guid = UnitGUID and UnitGUID(unit) or nil
            local x, y = GetPlayerMapPosition(unit)
            local coords = "sin coordenadas"
            if x and y then coords = string.format("mapa %.4f, %.4f", x, y) end
            self:Print(unit .. ": " .. name .. " | " .. coords .. " | GUID: " .. tostring(guid or "no disponible"))
        else
            self:Print(unit .. ": no disponible")
        end
    end

    self:Print("=== Diagnostico FAM v" .. self.VERSION .. " ===")
    Report("player")
    Report("target")
    Report("mouseover")
    Report("focus")
    for i = 1, 5 do Report("boss" .. i) end
    self:Print("UnitPosition: " .. tostring(type(UnitPosition) == "function"))
    self:Print("GetPlayerMapPosition: " .. tostring(type(GetPlayerMapPosition) == "function"))
    self:Print("GetPlayerFacing: " .. tostring(type(GetPlayerFacing) == "function") .. " | facing: " .. tostring(GetPlayerFacing and GetPlayerFacing() or "no disponible"))
    for i = 1, 5 do Report("arena" .. i) end
    Report("targettarget")
    local count = 0
    for guid, info in pairs(seenEnemies) do
        count = count + 1
        self:Print("Enemigo visto " .. count .. ": " .. tostring(info.name) .. " | eventos: " .. tostring(info.hits or 0) .. " | GUID: " .. tostring(guid))
    end
    self:Print("GUID hostiles registrados en combate: " .. count)
    self:Print("Eventos de combate recibidos: " .. combatEventCount .. " | nuevos GUID hostiles: " .. hostileEventCount)
    self:Print("Nota: los nombres/GUID se obtienen cuando participan en combate; esto no proporciona posicion ni distancia.")
end

function FAM:RecordCombatUnit(guid, name, flags)
    if not guid then return end
    if not flags or not bit or not bit.band then return end
    if bit.band(flags, HOSTILE_FLAG) == 0 then return end
    local entry = seenEnemies[guid]
    if not entry then entry = { name = name or "Enemigo", hits = 0 }; seenEnemies[guid] = entry end
    entry.name = name or entry.name or "Enemigo"
    entry.hits = (entry.hits or 0) + 1
    entry.time = GetTime()
end

function FAM:PruneCombatUnits()
    local now = GetTime()
    for guid, info in pairs(seenEnemies) do
        if not info.time or (now - info.time) > 45 then seenEnemies[guid] = nil end
    end
end

SLASH_FACTIONAGGROMONITOR1 = "/fam"
SlashCmdList["FACTIONAGGROMONITOR"] = function(message)
    local command, value = string.match(message or "", "^(%S*)%s*(.-)$")
    command = string.lower(command or "")
    if command == "debug" then
        FAM:DebugUnits()
    elseif command == "enemies" then
        FAM:DebugUnits()
    elseif command == "reset" then
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
loader:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
loader:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subevent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...
        combatEventCount = combatEventCount + 1
        local before = 0
        for _ in pairs(seenEnemies) do before = before + 1 end
        FAM:RecordCombatUnit(sourceGUID, sourceName, sourceFlags)
        FAM:RecordCombatUnit(destGUID, destName, destFlags)
        local after = 0
        for _ in pairs(seenEnemies) do after = after + 1 end
        if after > before then hostileEventCount = hostileEventCount + 1 end
        return
    elseif event == "ADDON_LOADED" then
        local addon = ...
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
    if elapsed >= FAM.db.updateRate then elapsed = 0; FAM:PruneCombatUnits(); FAM:Refresh() end
end)
