-- LX_NPCBasesSplit: reemplaza este archivo de NPC Bases por un cargador que lee el
-- ORIGINAL instalado, le aplica los cambios de pantalla dividida en memoria, y lo
-- ejecuta. Si NPC Bases cambia y un fragmento deja de coincidir, ese parche se omite
-- con aviso en console.txt y el archivo original sigue funcionando.
require "LXNB_Core"

LXNB.LoadPatched("media/lua/client/NPCBases/NPCBases_Client.lua", {
    {  -- los avisos del servidor (base atacada, operacion terminada) iban siempre a
       -- getPlayer(), que en pantalla dividida no es determinista y puede ser un
       -- jugador muerto. Ahora van al primer jugador local vivo.
        id = "aviso_a_jugador_vivo", count = 1,
        find = [=[        if not args.silent then C.notice(getPlayer(), args.text) end]=],
        repl = [=[        if not args.silent then C.notice(LXNB.anyLocal(), args.text) end]=],
    },

    {  -- el respaldo para saber "es mi personaje" cuando isLocalPlayer no esta
       -- disponible comparaba contra getPlayer(), que en pantalla dividida deja
       -- fuera al jugador 2. Ahora acepta a cualquier jugador local.
        id = "respaldo_jugador_local", count = 1,
        find = [=[    elseif character ~= getPlayer() then
        return
    end]=],
        repl = [=[    elseif not LXNB.numOf(character) then
        return
    end]=],
    },

    {  -- mismo caso que el aviso de arriba, en la rama de error de los clanes
        id = "aviso_de_error_a_jugador_vivo", count = 1,
        find = [=[C.notice(getPlayer(),"Clan settings could not refresh. See console for the error.")]=],
        repl = [=[C.notice(LXNB.anyLocal(),"Clan settings could not refresh. See console for the error.")]=],
    },

    {  -- el barrido de colchones corre solo con isClient(), o sea en pantalla dividida
       -- CONECTADA A UN SERVIDOR. Ahi barria unicamente alrededor del jugador 1: lo que
       -- dejaba el jugador 2 al explotar una base no se limpiaba nunca. Ahora barre
       -- alrededor de cada jugador local (con uno solo queda igual que el original).
        id = "barrido_de_cada_jugador_local", count = 1,
        find = [=[    local p = getPlayer()
    if p then pcall(C.sweepMattresses, math.floor(p:getX()), math.floor(p:getY())) end]=],
        repl = [=[    for _, p in ipairs(LXNB.localPlayers()) do
        pcall(C.sweepMattresses, math.floor(p:getX()), math.floor(p:getY()))
    end]=],
    },
})
