-- LX_NPCBasesSplit: reemplaza este archivo de NPC Bases por un cargador que lee el
-- ORIGINAL instalado, le aplica los cambios de pantalla dividida y mando en memoria,
-- y lo ejecuta. Si NPC Bases cambia y un fragmento deja de coincidir, ese parche se
-- omite con aviso en console.txt y la ventana sigue funcionando como el original.
--
-- Este archivo abre TRES ventanas sueltas (Clanes, Expansion y Armas de defensores),
-- las tres medidas y centradas contra la ventana entera. Las dos ultimas comparten
-- la misma linea de apertura, asi que cada parche se ancla con la altura que las
-- distingue (38*fh para Expansion, 24*fh para Armas).
require "LXNB_Core"

LXNB.LoadPatched("media/lua/client/NPCBases/NPCBases_ClanUI.lua", {
    {  -- ventana de clanes: medida y centrada en la mitad del jugador que la abrio
        id = "ventana_clanes_en_su_pantalla", count = 1,
        find = [=[    local w, h = math.min(getCore():getScreenWidth() - 40, 48 * fontH), math.min(getCore():getScreenHeight() - 40, 36 * fontH)
    local win = NPCBasesClanWindow:new((getCore():getScreenWidth() - w) / 2, (getCore():getScreenHeight() - h) / 2, w, h, player)
    win:initialise()
    win:addToUIManager()]=],
        repl = [=[    local _, _, vw, vh = LXNB.viewport(player)
    local w, h = math.min(vw - 40, 48 * fontH), math.min(vh - 40, 36 * fontH)
    local wx, wy = LXNB.centre(player, w, h)
    local win = NPCBasesClanWindow:new(wx, wy, w, h, player)
    win:initialise()
    LXNB.makeJoypadReady(win, player)
    win:addToUIManager()]=],
    },

    {  -- ventana de expansion
        id = "ventana_expansion_en_su_pantalla", count = 1,
        find = [=[    local w = math.min(getCore():getScreenWidth()-40, 44*fh)
    local h = math.min(getCore():getScreenHeight()-40, 35*fh)
    local win = ISCollapsableWindow.new(NPCBasesExpansionWindow, (getCore():getScreenWidth()-w)/2, (getCore():getScreenHeight()-h)/2,w,h)]=],
        repl = [=[    local _, _, vw, vh = LXNB.viewport(self.player)
    local w = math.min(vw-40, 44*fh)
    local h = math.min(vh-40, 35*fh)
    local ex, ey = LXNB.centre(self.player, w, h)
    local win = ISCollapsableWindow.new(NPCBasesExpansionWindow, ex, ey, w, h)]=],
    },

    {  -- ventana de armas de defensores (la encontre porque compartia linea con la
       -- de expansion: tenia el mismo problema y se me habria pasado)
        id = "ventana_armas_en_su_pantalla", count = 1,
        find = [=[    local w=math.min(getCore():getScreenWidth()-40,40*fh)
    local h=math.min(getCore():getScreenHeight()-40,21*fh)
    local win=ISCollapsableWindow.new(NPCBasesWeaponsWindow,(getCore():getScreenWidth()-w)/2,(getCore():getScreenHeight()-h)/2,w,h)]=],
        repl = [=[    local _, _, vw, vh = LXNB.viewport(self.player)
    local w=math.min(vw-40,40*fh)
    local h=math.min(vh-40,21*fh)
    local wx, wy = LXNB.centre(self.player, w, h)
    local win=ISCollapsableWindow.new(NPCBasesWeaponsWindow,wx,wy,w,h)]=],
    },

    {  -- expansion navegable con mando cuando se abre suelta (38*fh la distingue)
        id = "expansion_con_mando", count = 1,
        find = [=[        win:setX(0) win:setY(0) win:setWidth(math.max(self.hostOverview.width-48,36*fh)) win:setHeight(38*fh)
        self.hostOverview:embedSettings(win)
    else win:initialise() win:addToUIManager() win:setVisible(true) end]=],
        repl = [=[        win:setX(0) win:setY(0) win:setWidth(math.max(self.hostOverview.width-48,36*fh)) win:setHeight(38*fh)
        self.hostOverview:embedSettings(win)
    else win:initialise() LXNB.makeJoypadReady(win, self.player) win:addToUIManager() win:setVisible(true) end]=],
    },

    {  -- armas de defensores navegable con mando (24*fh la distingue)
        id = "armas_con_mando", count = 1,
        find = [=[        win:setX(0) win:setY(0) win:setWidth(math.max(self.hostOverview.width-48,36*fh)) win:setHeight(24*fh)
        self.hostOverview:embedSettings(win)
    else win:initialise() win:addToUIManager() win:setVisible(true) end]=],
        repl = [=[        win:setX(0) win:setY(0) win:setWidth(math.max(self.hostOverview.width-48,36*fh)) win:setHeight(24*fh)
        self.hostOverview:embedSettings(win)
    else win:initialise() LXNB.makeJoypadReady(win, self.player) win:addToUIManager() win:setVisible(true) end]=],
    },
})
