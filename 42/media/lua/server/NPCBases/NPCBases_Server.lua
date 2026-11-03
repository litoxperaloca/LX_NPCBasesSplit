-- LX_NPCBasesSplit: reemplaza este archivo de NPC Bases por un cargador que lee el
-- ORIGINAL instalado, le aplica dos cambios en memoria y lo ejecuta. Si NPC Bases
-- cambia y un fragmento deja de coincidir, ese parche se omite con aviso en
-- console.txt y el archivo original sigue funcionando entero.
--
-- Son dos cambios y los dos tocan SOLO la decision de fundar una base nueva. Toda
-- la simulacion del autor (crecimiento, defensores, saqueo, perimetro, ruinas)
-- queda intacta. Con "bases que te siguen" apagado en las opciones, o en un
-- servidor dedicado, el comportamiento es identico al original.
require "LXNB_Core"

LXNB.LoadPatched("media/lua/server/NPCBases/NPCBases_Server.lua", {
    {  -- El tope MaxBases contaba todas las bases del mundo: pasadas 6 no se fundaba
       -- ninguna mas por lejos que viajaras, y en pantalla dividida ese cupo se gasta
       -- al doble de velocidad. Ahora cuenta las que tenes cerca, con techo absoluto.
       -- ClaimChance pasa por el mismo filtro para el caso "pueblo nuevo, cero bases".
        id = "tope_de_bases_segun_cercania", count = 1,
        find = [=[        if activeCount(data) < NPCBases.opt("MaxBases", 6) and (retryFounding or ZombRand(100) < NPCBases.opt("ClaimChance", 35)) then]=],
        repl = [=[        if LXNB.countForCap(data, activeCount) < NPCBases.opt("MaxBases", 6) and (retryFounding or ZombRand(100) < LXNB.claimChance(NPCBases.opt("ClaimChance", 35), data)) then]=],
    },

    {  -- Al entrar a una zona sin bases, esperar 6 horas de juego para siquiera tirar
       -- el dado hace que el mod parezca apagado. En frontera la comprobacion baja a
       -- 2 horas. Las distancias minimas del autor no se tocan.
        id = "cadencia_en_zona_sin_bases", count = 1,
        find = [=[    if retryFounding or (now - data.lastCheckHour) >= NPCBases.opt("HoursBetweenChecks", 6) then]=],
        repl = [=[    if retryFounding or (now - data.lastCheckHour) >= LXNB.checkHours(NPCBases.opt("HoursBetweenChecks", 6), data) then]=],
    },
})
