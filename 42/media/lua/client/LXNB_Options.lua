--[[
    LX_NPCBasesSplit - opciones (Menu principal -> Opciones -> MODS -> "LX NPC Bases Split").
    Usa PZAPI.ModOptions (B42). Los valores se guardan solos.

    Las correcciones de pantalla dividida y mando no se configuran: estan siempre.
    Aca se ajusta solo el comportamiento de "bases que te siguen", que es lo unico
    que cambia el equilibrio del mod original.
]]

if not PZAPI or not PZAPI.ModOptions then return end
require "LXNB_Core"

local opts = PZAPI.ModOptions:create("LXNPCBasesSplit", getText("UI_LXNB_name"))
opts:addDescription(getText("UI_LXNB_desc"))
opts:addSeparator()

local tFollow = opts:addTickBox("FOLLOW", getText("UI_LXNB_follow"), true, getText("UI_LXNB_follow_tip"))
local sRadius = opts:addSlider("RADIUS", getText("UI_LXNB_radius"), 400, 3000, 100, 1200, getText("UI_LXNB_radius_tip"))
local sCeil   = opts:addSlider("CEILING", getText("UI_LXNB_ceiling"), 1, 6, 1, 3, getText("UI_LXNB_ceiling_tip"))
local tFront  = opts:addTickBox("FRONTIER", getText("UI_LXNB_frontier"), true, getText("UI_LXNB_frontier_tip"))

local dependents = { sRadius, sCeil, tFront }

-- onChange salta ANTES de que el valor quede guardado en option.value, asi que
-- getValue() todavia devuelve el anterior: hay que usar el value que llega.
local function applyEnabledState(masterOverride)
    local on
    if masterOverride ~= nil then on = (masterOverride == true) else on = (tFollow:getValue() == true) end
    for _, o in ipairs(dependents) do
        if o and o.setEnabled then pcall(o.setEnabled, o, on) end
    end
end

tFollow.onChange = function(self, value) applyEnabledState(value) end

opts.apply = function(self)
    LXNB.follow.on       = (tFollow:getValue() == true)
    LXNB.follow.radius   = tonumber(sRadius:getValue()) or 1200
    LXNB.follow.ceiling  = tonumber(sCeil:getValue()) or 3
    LXNB.follow.frontier = (tFront:getValue() == true)
    applyEnabledState()
    LXNB.log(("bases que te siguen: %s, radio %d, techo x%d, frontera %s"):format(
        LXNB.follow.on and "si" or "no", LXNB.follow.radius, LXNB.follow.ceiling,
        LXNB.follow.frontier and "si" or "no"))
end

-- apply() lo llama el menu al aceptar; al arrancar hay que llamarlo nosotros para
-- que los valores guardados lleguen a LXNB.follow antes del primer chequeo.
if Events ~= nil and Events.OnGameStart ~= nil then
    Events.OnGameStart.Add(function() pcall(opts.apply, opts) end)
end
