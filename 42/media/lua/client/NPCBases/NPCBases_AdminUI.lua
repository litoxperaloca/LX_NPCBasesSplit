-- LX_NPCBasesSplit: reemplaza este archivo de NPC Bases por un cargador que lee el
-- ORIGINAL instalado, le aplica los cambios de pantalla dividida y mando en memoria,
-- y lo ejecuta. Si NPC Bases cambia y un fragmento deja de coincidir, ese parche se
-- omite con aviso en console.txt y la ventana sigue funcionando como el original.
require "LXNB_Core"

LXNB.LoadPatched("media/lua/client/NPCBases/NPCBases_AdminUI.lua", {
    {  -- la ventana de administracion se mide y se centra en la mitad de pantalla
       -- del jugador que la abrio, no contra la ventana entera. UI.open(player) ya
       -- recibe ese jugador, asi que no hay que adivinar nada.
        id = "ventana_en_su_pantalla", count = 1,
        find = [=[    local sw,sh=getCore():getScreenWidth(),getCore():getScreenHeight()
    local fh=getTextManager():getFontHeight(UIFont.Small)
    local w=math.min(sw-32,900) local h=math.min(sh-64,600)
    local window=W:new((sw-w)/2,(sh-h)/2,w,h,player)
    UI.window=window window:initialise() window:addToUIManager()]=],
        repl = [=[    local _,_,sw,sh=LXNB.viewport(player)
    local fh=getTextManager():getFontHeight(UIFont.Small)
    local w=math.min(sw-32,900) local h=math.min(sh-64,600)
    local wx,wy=LXNB.centre(player,w,h)
    local window=W:new(wx,wy,w,h,player)
    UI.window=window window:initialise() LXNB.makeJoypadReady(window,player) window:addToUIManager()]=],
    },

    {  -- al cerrar se suelta el foco del mando: una ventana que se lo queda deja
       -- al jugador sin poder moverse
        id = "soltar_mando_al_cerrar", count = 1,
        find = [=[    ISCollapsableWindow.close(self) self:removeFromUIManager()
    if UI.window==self then UI.window=nil end]=],
        repl = [=[    LXNB.releaseJoypad(self)
    ISCollapsableWindow.close(self) self:removeFromUIManager()
    if UI.window==self then UI.window=nil end]=],
    },
})
