local FAM = FactionAggroMonitor
local elapsed = 0
local tracked = {}
local combatEvents = 0
local hostileEvents = 0
local HOSTILE = COMBATLOG_OBJECT_REACTION_HOSTILE or 0x40
local FRIENDLY = COMBATLOG_OBJECT_REACTION_FRIENDLY or 0x10

local function addToken(list, seen, token)
    if UnitExists(token) then
        local guid = UnitGUID and UnitGUID(token)
        local key = guid or token
        if not seen[key] then
            seen[key] = true
            local name = UnitName(token) or token
            local hostile = UnitCanAttack and UnitCanAttack("player", token)
            local friendly = UnitIsFriend and UnitIsFriend("player", token)
            local combat = UnitAffectingCombat and UnitAffectingCombat(token)
            list[#list + 1] = {
                token = token, guid = guid, name = name,
                faction = hostile and "enemy" or (friendly and "ally" or "unknown"),
                combat = combat == nil and "unknown" or (combat and "in" or "out"),
                source = "unit-token"
            }
        end
    end
end

function FAM:CollectKnownUnits()
    local list, seen = {}, {}
    addToken(list, seen, "target")
    addToken(list, seen, "mouseover")
    addToken(list, seen, "focus")
    addToken(list, seen, "targettarget")
    for i = 1, 5 do
        addToken(list, seen, "boss" .. i)
        addToken(list, seen, "arena" .. i)
    end
    for i = 1, GetNumPartyMembers() do addToken(list, seen, "party" .. i) end
    for i = 1, GetNumRaidMembers() do addToken(list, seen, "raid" .. i) end
    return list
end

function FAM:RecordCombatUnit(guid, name, flags, subevent)
    if not guid then return end
    local faction = "unknown"
    if flags and bit and bit.band then
        if bit.band(flags, HOSTILE) ~= 0 then faction = "enemy"
        elseif bit.band(flags, FRIENDLY) ~= 0 then faction = "ally" end
    end
    local item = tracked[guid] or { guid = guid, firstSeen = GetTime(), hits = 0 }
    item.name = name or item.name or "Unidad desconocida"
    item.faction = faction ~= "unknown" and faction or item.faction or "unknown"
    item.lastSeen = GetTime()
    item.lastEvent = subevent or item.lastEvent
    item.hits = item.hits + 1
    tracked[guid] = item
    if item.faction == "enemy" then hostileEvents = hostileEvents + 1 end
end

function FAM:PruneTracked()
    local now = GetTime()
    for guid, item in pairs(tracked) do
        if not item.lastSeen or now - item.lastSeen > (self.db.memorySeconds or 60) then tracked[guid] = nil end
    end
end

function FAM:MatchesFilters(unit)
    local faction = self.db.faction or "enemies"
    if faction == "enemies" and unit.faction ~= "enemy" then return false end
    if faction == "allies" and unit.faction ~= "ally" then return false end
    if faction == "both" and unit.faction == "unknown" then return false end
    local combat = self.db.combat or "any"
    if combat == "in" and unit.combat ~= "in" then return false end
    if combat == "out" and unit.combat ~= "out" then return false end
    local name = string.lower(self.db.nameFilter or "")
    if name ~= "" and not string.find(string.lower(unit.name or ""), name, 1, true) then return false end
    return true
end

function FAM:Refresh()
    if not self.frame or not self.db.enabled then return end
    self:ClearDots()
    local units = self:CollectKnownUnits()
    local matched, enemies, allies = 0, 0, 0
    for _, unit in ipairs(units) do
        if unit.faction == "enemy" then enemies = enemies + 1
        elseif unit.faction == "ally" then allies = allies + 1 end
        if self:MatchesFilters(unit) then matched = matched + 1 end
    end
    local observed = 0
    for _ in pairs(tracked) do observed = observed + 1 end
    self:PlaceDot("player-center", 0.5, 0.5, {0.2, 1, 0.4}, 9)
    self:SetStatus("Tokens: " .. #units .. " | Enemigos: " .. enemies .. " | Aliados: " .. allies .. " | Filtrados: " .. matched .. " | GUID combate: " .. observed)
    if self.subtitle then self.subtitle:SetText("Detector generico - posiciones NPC no disponibles por API") end
end

function FAM:DebugUnits()
    local units = self:CollectKnownUnits()
    self:Print("=== FAM " .. self.VERSION .. " | Unidades accesibles ===")
    for _, unit in ipairs(units) do
        self:Print(unit.token .. ": " .. unit.name .. " | " .. unit.faction .. " | combate: " .. unit.combat .. " | GUID: " .. tostring(unit.guid))
    end
    local count = 0
    for guid, item in pairs(tracked) do
        count = count + 1
        self:Print("Registro combate " .. count .. ": " .. item.name .. " | " .. item.faction .. " | eventos: " .. item.hits .. " | GUID: " .. guid)
    end
    self:Print("Eventos de combate: " .. combatEvents .. " | eventos hostiles: " .. hostileEvents)
    self:Print("Importante: el registro de combate identifica unidades, pero no aporta posicion ni distancia.")
end

function FAM:DebugMinimap()
    self:Print("=== FAM diagnostico del minimapa ===")
    if type(GetNumTrackingTypes) == "function" and type(GetTrackingInfo) == "function" then
        local count = GetNumTrackingTypes() or 0
        self:Print("Tipos de rastreo disponibles: " .. count)
        for i = 1, count do
            local name, texture, active, category, nested = GetTrackingInfo(i)
            self:Print("Rastreo " .. i .. ": " .. tostring(name) ..
                " | activo: " .. tostring(active) ..
                " | categoria: " .. tostring(category) ..
                " | textura: " .. tostring(texture) ..
                " | nivel: " .. tostring(nested))
        end
    else
        self:Print("GetNumTrackingTypes/GetTrackingInfo no disponibles.")
    end

    if not Minimap then
        self:Print("El frame global Minimap no esta disponible.")
        return
    end

    local function describe(object, label)
        if not object then return end
        local okName, objectName = pcall(function() return object:GetName() end)
        local okType, objectType = pcall(function() return object:GetObjectType() end)
        self:Print(label .. " nombre=" .. tostring(okName and objectName or "anonimo") ..
            " tipo=" .. tostring(okType and objectType or "desconocido"))
        if okType and objectType == "Texture" then
            local okTexture, texturePath = pcall(function() return object:GetTexture() end)
            if okTexture then self:Print("  textura=" .. tostring(texturePath)) end
        end
    end

    self:Print("Inspeccionando hijos directos de Minimap:")
    local okChildren, children = pcall(function() return { Minimap:GetChildren() } end)
    if okChildren and children then
        for i = 1, math.min(table.getn(children), 40) do
            describe(children[i], "Hijo " .. i)
        end
    else
        self:Print("No se pudieron enumerar los hijos del minimapa.")
    end

    self:Print("Inspeccionando regiones directas de Minimap:")
    local okRegions, regions = pcall(function() return { Minimap:GetRegions() } end)
    if okRegions and regions then
        for i = 1, math.min(table.getn(regions), 60) do
            describe(regions[i], "Region " .. i)
        end
    else
        self:Print("No se pudieron enumerar las regiones del minimapa.")
    end
    self:Print("Comparar esta salida con rastreo apagado y encendido. Esto inspecciona la UI, no garantiza acceso a los puntos dibujados por el motor.")
end

function FAM:PrintList()
    local units = self:CollectKnownUnits()
    self:Print("Unidades que el cliente expone:")
    for _, unit in ipairs(units) do
        if self:MatchesFilters(unit) then self:Print(unit.name .. " [" .. unit.faction .. ", combate " .. unit.combat .. "] - " .. unit.token) end
    end
    self:Print("Los GUID del registro de combate no son tokens seleccionables ni tienen coordenadas.")
end

SLASH_FACTIONAGGROMONITOR1 = "/fam"
SlashCmdList["FACTIONAGGROMONITOR"] = function(message)
    local command, value = string.match(message or "", "^(%S*)%s*(.-)$")
    command = string.lower(command or "")
    if command == "debug" then FAM:DebugUnits()
    elseif command == "minimap" then FAM:DebugMinimap()
    elseif command == "list" then FAM:PrintList()
    elseif command == "faction" then
        if value == "enemies" or value == "allies" or value == "both" then FAM.db.faction = value; FAM:Print("Filtro de faccion: " .. value)
        else FAM:Print("Uso: /fam faction enemies|allies|both") end
    elseif command == "combat" then
        if value == "any" or value == "in" or value == "out" then FAM.db.combat = value; FAM:Print("Filtro de combate: " .. value)
        else FAM:Print("Uso: /fam combat any|in|out") end
    elseif command == "name" then
        FAM.db.nameFilter = value or ""; FAM:Print("Filtro de nombre: " .. (FAM.db.nameFilter ~= "" and FAM.db.nameFilter or "ninguno"))
    elseif command == "range" then FAM:SetRadius(value)
    elseif command == "lock" then
        FAM.db.locked = not FAM.db.locked
        FAM:Print("Radar " .. (FAM.db.locked and "bloqueado." or "desbloqueado."))
    elseif command == "reset" then FAM:ResetPosition(); FAM:Print("Posicion restaurada.")
    else
        if FAM.frame:IsShown() then FAM.frame:Hide() else FAM.frame:Show(); FAM:Refresh() end
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
loader:RegisterEvent("PLAYER_TARGET_CHANGED")
loader:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
loader:RegisterEvent("PLAYER_FOCUS_CHANGED")
loader:RegisterEvent("UNIT_FLAGS")
loader:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subevent, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = ...
        combatEvents = combatEvents + 1
        FAM:RecordCombatUnit(sourceGUID, sourceName, sourceFlags, subevent)
        FAM:RecordCombatUnit(destGUID, destName, destFlags, subevent)
        return
    elseif event == "ADDON_LOADED" then
        local addon = ...
        if addon ~= "FactionAggroMonitor" then return end
        FAM:InitializeDB()
        FAM:CreateRadar()
        FAM:Print("v" .. FAM.VERSION .. " cargado. /fam debug para diagnostico.")
    elseif event == "PLAYER_ENTERING_WORLD" then
        if FAM.Refresh then FAM:Refresh() end
    else
        if FAM.Refresh then FAM:Refresh() end
    end
end)

local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function(self, delta)
    if not FAM.db or not FAM.db.enabled or not FAM.frame or not FAM.frame:IsShown() then return end
    elapsed = elapsed + delta
    if elapsed >= (FAM.db.updateRate or 0.5) then
        elapsed = 0
        FAM:PruneTracked()
        FAM:Refresh()
    end
end)
