--[[
    LX_NPCBasesSplit - nucleo.

    NPC Bases esta bastante bien preparado para varios jugadores: sus bucles usan
    getSpecificPlayer(i) y sus handlers reciben playerNum. Lo que no contempla es
    PANTALLA DIVIDIDA, y ahi fallan dos cosas:

      1. Sus tres ventanas (Admin, Clanes y Expansion) se miden y se centran contra
         la ventana ENTERA. Con dos jugadores aparecen a caballo de las dos mitades,
         o directamente en la pantalla del otro.
      2. Son ISCollapsableWindow: con mando no hay forma de usarlas.

    Lo bueno es que UI.open(player) YA recibe el jugador que la abrio, asi que no
    hay que adivinar nada: alcanza con usar ese dato para ubicarla y para darle el
    foco del mando.

    Nada de NPC Bases se distribuye ni se pisa: sus archivos se leen de tu copia
    instalada, se parchean en memoria y se ejecutan desde ahi. Si el mod se
    actualiza y un fragmento deja de coincidir, ese parche se omite, se avisa en
    console.txt y el archivo original sigue funcionando igual.
]]

LXNB = LXNB or {}
LXNB.TARGET_MOD = "NPCBases"
LXNB.report = LXNB.report or {}

local function log(msg) print("[LX_NPCBasesSplit] " .. tostring(msg)) end
LXNB.log = log

-- =====================================================================
-- Jugadores y mitad de pantalla
-- =====================================================================

function LXNB.localPlayers()
    local list = {}
    if type(getSpecificPlayer) ~= "function" then return list end
    for i = 0, 3 do
        local ok, p = pcall(getSpecificPlayer, i)
        if ok and p ~= nil then list[#list + 1] = p end
    end
    return list
end

-- Indice 0..3 de un jugador. nil si no se puede determinar.
function LXNB.numOf(player)
    if player == nil then return nil end
    local ok, n = pcall(function() return player:getPlayerNum() end)
    if ok and type(n) == "number" and n >= 0 and n <= 3 then return n end
    return nil
end

-- El jugador que corresponde cuando no nos pasaron ninguno: el primero local vivo.
function LXNB.anyLocal()
    for _, p in ipairs(LXNB.localPlayers()) do
        local ok, dead = pcall(function() return p:isDead() end)
        if ok and dead ~= true then return p end
    end
    local ok, p = pcall(getSpecificPlayer, 0)
    return ok and p or nil
end

--[[
    Mitad de pantalla de un jugador: left, top, width, height.

    Fuera de pantalla dividida el viewport ES la ventana entera, asi que todo lo
    que use esto se comporta exactamente como el original para quien juega solo.
]]
function LXNB.viewport(player)
    local core = getCore()
    local sw, sh = core:getScreenWidth(), core:getScreenHeight()
    if type(getPlayerScreenWidth) ~= "function" then return 0, 0, sw, sh end

    local n = LXNB.numOf(player) or LXNB.numOf(LXNB.anyLocal()) or 0
    local okW, w = pcall(getPlayerScreenWidth, n)
    local okH, h = pcall(getPlayerScreenHeight, n)
    local okL, l = pcall(getPlayerScreenLeft, n)
    local okT, t = pcall(getPlayerScreenTop, n)
    if not (okW and okH and okL and okT) then return 0, 0, sw, sh end
    if type(w) ~= "number" or type(h) ~= "number" or w <= 0 or h <= 0 then
        return 0, 0, sw, sh
    end
    return l or 0, t or 0, w, h
end

local function clamp(v, lo, hi)
    if hi < lo then return lo end
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- Centra una ventana de w x h dentro de la mitad del jugador. Devuelve x, y.
function LXNB.centre(player, w, h)
    local l, t, vw, vh = LXNB.viewport(player)
    local x = l + (vw - (tonumber(w) or 0)) / 2
    local y = t + (vh - (tonumber(h) or 0)) / 2
    return math.floor(clamp(x, l, l + vw - (tonumber(w) or 0))),
           math.floor(clamp(y, t, t + vh - (tonumber(h) or 0)))
end

-- =====================================================================
-- Ventanas con mando
-- =====================================================================
-- Las ventanas de NPC Bases son ISCollapsableWindow llenas de botones y listas.
-- Con mando no se puede entrar. Aca se les agrega, en caliente, navegacion por
-- joypad: cruceta recorre, A activa, B cierra.
--
-- Solo se toma el foco si ESE jugador tiene un mando asignado. Si juega con
-- teclado y mouse, la ventana queda exactamente como estaba.

local function focusables(win)
    local list = {}
    local ok, kids = pcall(function() return win:getChildren() end)
    if not ok or type(kids) ~= "table" then return list end
    for _, c in pairs(kids) do
        if type(c) == "table" and type(c.getY) == "function"
                and (type(c.onclick) == "function" or type(c.onMouseDown) == "function") then
            local on = true
            if c.enable ~= nil then on = (c.enable == true) end
            if on then list[#list + 1] = c end
        end
    end
    table.sort(list, function(a, b)
        local ay, by = a:getY(), b:getY()
        if ay == by then return a:getX() < b:getX() end
        return ay < by
    end)
    return list
end

local function highlight(list, i)
    for k, c in ipairs(list) do
        pcall(function()
            if k == i then c:setBorderRGBA(1.0, 0.82, 0.25, 1.0)
            else c:setBorderRGBA(0.4, 0.4, 0.4, 0.5) end
        end)
    end
end

function LXNB.releaseJoypad(win)
    pcall(function()
        if win and win.lxnbJoypad ~= nil and type(setJoypadFocus) == "function" then
            setJoypadFocus(win.lxnbJoypad, nil)
        end
    end)
    if win then win.lxnbJoypad = nil end
end

function LXNB.makeJoypadReady(win, player)
    if win == nil or win.lxnbJoypadReady then return end
    win.lxnbJoypadReady = true

    local n = LXNB.numOf(player) or LXNB.numOf(LXNB.anyLocal())
    if n == nil or type(getJoypadData) ~= "function" then return end
    local okJ, jd = pcall(getJoypadData, n)
    if not okJ or jd == nil then return end  -- ese jugador no usa mando

    win.playerNum = win.playerNum or n
    win.lxnbJoypad = n
    win.lxnbIndex = 1

    function win:onJoypadDown(button, joypadData)
        local ok, err = pcall(function()
            if Joypad == nil then return end
            local list = focusables(self)
            if button == Joypad.BButton then
                LXNB.releaseJoypad(self)
                pcall(function() self:close() end)
                return
            end
            if #list == 0 then return end
            local i = clamp(self.lxnbIndex or 1, 1, #list)
            if button == Joypad.DPadUp then
                self.lxnbIndex = i > 1 and i - 1 or #list
                highlight(list, self.lxnbIndex)
            elseif button == Joypad.DPadDown then
                self.lxnbIndex = i < #list and i + 1 or 1
                highlight(list, self.lxnbIndex)
            elseif button == Joypad.AButton then
                local c = list[i]
                if c and type(c.onclick) == "function" then
                    pcall(function() c.onclick(c.target, c) end)
                end
            end
        end)
        -- ante cualquier problema soltamos el mando: una ventana que se lo queda
        -- deja al jugador sin poder moverse, que es peor que no tener navegacion
        if not ok then
            log("ventana con mando: " .. tostring(err))
            LXNB.releaseJoypad(self)
        end
    end

    pcall(function() highlight(focusables(win), 1) end)
    pcall(function()
        if type(setJoypadFocus) == "function" then setJoypadFocus(n, win) end
    end)
end

-- =====================================================================
-- Bases que te siguen por el mapa
-- =====================================================================
--[[
    Lo que pediste (que se asignen bases a medida que te movés) NPC Bases ya lo
    hace, y encima ya mira a los dos jugadores: loadedBuildings() usa la celda
    compartida y, si no, recorre allPlayers(), que en pantalla dividida enumera
    con getNumActivePlayers(). Hasta ahi todo bien.

    Lo que lo frena es otra cosa: el tope MaxBases (6 por defecto) cuenta TODAS
    las bases DEL MUNDO. Una vez que hay seis, no se funda ninguna mas, viajes
    donde viajes. En pantalla dividida eso llega antes, porque entre dos explorando
    se gasta el cupo al doble de velocidad, y de ahi en mas el mapa queda muerto.

    Aca el tope pasa a contar solo las bases que tenes CERCA. La densidad local
    queda igual que la que eligio el autor (mismo MaxBases en el mismo radio), pero
    el mundo se sigue poblando mientras te movés. El rendimiento no se resiente:
    tickBase() corta en seco cuando el chunk de la base no esta cargado, asi que
    una base lejana cuesta una consulta de casilla cada diez minutos.

    Un techo absoluto (multiplo de MaxBases) evita que crezca sin freno en una
    partida larga. Con el multiplicador en 1 el comportamiento es el de siempre.
]]

LXNB.follow = {
    on       = true,
    radius   = 1200,  -- que cuenta como "cerca"
    ceiling  = 3,     -- techo del mundo = MaxBases * esto
    frontier = true,
}

local function ruinedStage()
    if NPCBases ~= nil and NPCBases.STAGE_RUINED ~= nil then return NPCBases.STAGE_RUINED end
    return -1
end

local function maxBasesOpt()
    if NPCBases ~= nil and type(NPCBases.opt) == "function" then
        local ok, v = pcall(NPCBases.opt, "MaxBases", 6)
        if ok then
            local n = tonumber(v)
            if n then return n end
        end
    end
    return 6
end

local function anyPlayerWithin(players, bx, by, r)
    local rr = r * r
    for _, p in ipairs(players) do
        local ok, dx, dy = pcall(function() return p:getX() - bx, p:getY() - by end)
        if ok and dx ~= nil and (dx * dx + dy * dy) <= rr then return true end
    end
    return false
end

-- Bases en pie a menos de follow.radius de ALGUN jugador local.
-- Devuelve nil si no se puede saber (sin jugadores): ahi no tocamos nada.
function LXNB.nearBases(data)
    if data == nil or type(data.bases) ~= "table" then return nil end
    local players = LXNB.localPlayers()
    if #players == 0 then return nil end
    local ruined, r, n = ruinedStage(), LXNB.follow.radius or 1200, 0
    for _, b in pairs(data.bases) do
        if type(b) == "table" and b.stage ~= ruined then
            local bx, by = tonumber(b.x), tonumber(b.y)
            if bx and by and anyPlayerWithin(players, bx, by, r) then n = n + 1 end
        end
    end
    return n
end

-- Reemplaza el conteo que decide si se puede fundar otra base.
-- fallback es el activeCount() original del mod: si algo no cuadra, se usa ese.
function LXNB.countForCap(data, fallback)
    local okOrig, original = pcall(fallback, data)
    if not okOrig or type(original) ~= "number" then return 9999 end
    if not LXNB.follow.on then return original end
    -- en servidor dedicado no hay jugadores locales que mirar: no cambiamos nada
    if type(isServer) == "function" and isServer() then return original end
    local ok, near = pcall(LXNB.nearBases, data)
    if not ok or near == nil then return original end
    local techo = math.floor(maxBasesOpt() * (LXNB.follow.ceiling or 3))
    if original >= techo then return original end  -- techo del mundo alcanzado
    return near
end

-- "Frontera": estas en una zona sin ninguna base cerca.
function LXNB.onFrontier(data)
    if not (LXNB.follow.on and LXNB.follow.frontier) then return false end
    if type(isServer) == "function" and isServer() then return false end
    local ok, near = pcall(LXNB.nearBases, data)
    return ok and near ~= nil and near == 0
end

-- Al llegar a un pueblo nuevo, vanilla igual espera HoursBetweenChecks (6) y encima
-- tira ClaimChance (35%): unas 17 horas de juego de media hasta el primer intento,
-- que se siente como que el mod no hace nada. En frontera el primer asentamiento de
-- la zona se intenta enseguida. Las distancias minimas del autor siguen valiendo,
-- asi que no te puede aparecer una base encima.
function LXNB.checkHours(original, data)
    if LXNB.onFrontier(data) then return 2 end
    return original
end

function LXNB.claimChance(original, data)
    if LXNB.onFrontier(data) then return 100 end
    return original
end

-- =====================================================================
-- Cargador de parches de texto
-- =====================================================================

local function readModFile(modId, rel)
    local ok, reader = pcall(getModFileReader, modId, rel, false)
    if not ok or not reader then return nil end
    local lines = {}
    local line = reader:readLine()
    while line ~= nil do
        lines[#lines + 1] = line
        line = reader:readLine()
    end
    reader:close()
    return table.concat(lines, "\n") .. "\n"
end

local function escapePattern(s)
    return (string.gsub(s, "[%^%$%(%)%%%.%[%]%*%+%-%?]", function(c) return "%" .. c end))
end

local function plainReplace(src, find, repl)
    local pat = escapePattern(find)
    local parts, pos, count = {}, 1, 0
    while true do
        local s, e = string.find(src, pat, pos)
        if not s then break end
        parts[#parts + 1] = string.sub(src, pos, s - 1)
        parts[#parts + 1] = repl
        pos = e + 1
        count = count + 1
    end
    parts[#parts + 1] = string.sub(src, pos)
    return table.concat(parts), count
end

local function countOccurrences(src, find)
    local _, n = plainReplace(src, find, "")
    return n
end

LXNB._plainReplace = plainReplace -- expuesto para las pruebas

-- patches: lista de { id=, find=, repl=, count= }  (count = exacto, o "*" para todas)
function LXNB.LoadPatched(rel, patches)
    local src = readModFile(LXNB.TARGET_MOD, rel)
    if not src then
        log("ERROR: no pude leer " .. rel .. " de " .. LXNB.TARGET_MOD ..
            ". NPC Bases activo? (archivo NO cargado)")
        return false
    end

    local applied, skipped, total = {}, {}, 0
    local patched = src
    for _, p in ipairs(patches) do
        local n = countOccurrences(patched, p.find)
        local ok
        if p.count == "*" then ok = n > 0 else ok = (n == (p.count or 1)) end
        if ok then
            patched = plainReplace(patched, p.find, p.repl)
            applied[#applied + 1] = p.id
            total = total + n
        elseif p.count == "*" and n == 0 then
            applied[#applied + 1] = p.id .. "(0)"
        else
            skipped[#skipped + 1] = p.id .. " (encontrado " .. n .. ", esperado " .. tostring(p.count) .. ")"
        end
    end

    local chunk, err = loadstring(patched, "@NPCBases/" .. rel)
    if not chunk then
        log("ERROR compilando " .. rel .. " parcheado: " .. tostring(err) ..
            " -> uso el ORIGINAL sin parches")
        chunk, err = loadstring(src, "@NPCBases/" .. rel)
        applied, total = {}, 0
        if not chunk then
            log("ERROR compilando original " .. rel .. ": " .. tostring(err))
            return false
        end
    end

    LXNB.report[rel] = { applied = applied, skipped = skipped, changes = total }
    if #skipped > 0 then
        log(rel .. ": " .. total .. " cambios, OMITIDOS: " .. table.concat(skipped, "; "))
    end

    if LXNB.DRY_RUN then return true end
    chunk()
    return true
end

if Events ~= nil and Events.OnGameStart ~= nil then
    Events.OnGameStart.Add(function()
        local files, changes, bad = 0, 0, 0
        for _, r in pairs(LXNB.report or {}) do
            files = files + 1
            changes = changes + (r.changes or 0)
            bad = bad + #r.skipped
        end
        log("pantalla dividida: " .. changes .. " cambios en " .. files .. " archivos" ..
            (bad > 0 and (", " .. bad .. " parches omitidos") or ""))
    end)
end
