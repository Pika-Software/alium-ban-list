/*
  _____  _              ___   _  _                    ______                 _      _       _   
 |_   _|| |            / _ \ | |(_)                   | ___ \               | |    (_)     | |  
   | |  | |__    ___  / /_\ \| | _  _   _  _ __ ___   | |_/ /  __ _  _ __   | |     _  ___ | |_ 
   | |  | '_ \  / _ \ |  _  || || || | | || '_ ` _ \  | ___ \ / _` || '_ \  | |    | |/ __|| __|
   | |  | | | ||  __/ | | | || || || |_| || | | | | | | |_/ /| (_| || | | | | |____| |\__ \| |_ 
   \_/  |_| |_| \___| \_| |_/|_||_| \__,_||_| |_| |_| \____/  \__,_||_| |_| \_____/|_||___/ \__|                                                                                                                                                                                                                                                                                                                   
*/                                                                                 

if game.SinglePlayer() then return end -- В сингл плеере оно нам и нахуй не нужно)

AliumBanList = AliumBanList or {}
AliumBanList["Bans"] = AliumBanList["Bans"] or {}

local HTTP = HTTP
local MsgC = MsgC
local toSteamID = util.SteamIDFrom64
local toSteamID64 = util.SteamIDTo64
local stSub = string.sub
local stFind = string.find
local stGsub = string.gsub
local stGmatch = string.gmatch
local concommand_Add = concommand.Add
local hook_Add = hook.Add

/*
    Дружок сталкерок конфигурация этажом ниже \/
*/
AliumBanList["cfg"] = {
    ["tag"] = "Pika Software",  // Тег для логов в консоли
    ["printDisconnect"] = true, // Выводить информацию о блокировке игрока в консоль сервера
    ["banListURL"] = "https://raw.githubusercontent.com/Pika-Software/TheAliumBanList/main/banned_user.cfg",    // Базовая ссылка на raw с банами
    ["colors"] = {
        ["tagColor"] = Color(0, 103, 221),  // Цвет тега
        ["msgColor"] = Color(224,182,42),   // Цвет сообщения
        ["nickColor"] = Color(18, 184, 206),    // Цвет ника
    },

    // Сообщение которое увидит отключённый игрок
    ["disconnectMessage"] = [[
        -------===== [ The Alium ] =====-------
        
        Доступ к этому серверу для вас ограничен!
        Дополнительная информация в группе Steam:
        
        https://steamcommunity.com/groups/thealium
    ]],
}

function AliumBanList:Log(...)
    local cfg = AliumBanList["cfg"]
    MsgC(cfg["colors"]["tagColor"], "["..cfg["tag"].."] ", cfg["colors"]["msgColor"], ..., "\n")
end

function AliumBanList:Get()
    local url = AliumBanList["cfg"]["banListURL"]
    if isstring(url) and url != "" then
        if HTTP({
            ["url"] = url,
            ["method"] = "GET",
            ["headers"] = {
                ["accept-encoding"] = "gzip, deflate",
                ["accept-language"] = "en",
            },
            ["success"] = function(code, body)
                if code == 200 and body != "" then
                    AliumBanList["Bans"] = {}
                    for line in stGmatch(body,"(.-)\n") do
                        line = stGsub(line, "\r","")
                        local st = stFind(line, "STEAM_0:", 0)
                        if st != nil then
                            AliumBanList["Bans"][toSteamID64(stSub(line, st, #line))] = true
                        end
                    end
                end
            end,
        }) != nil then
            self:Log("Списко банов от сообщества 'The Alium' успешно получен!")
        else
            self:Log("Возникла ошибка при получении списка банов!")
        end
    else
        self:Log("Некорректный URL для получаения бан-листа!")
    end
end

hook_Add("InitPostEntity", "AliumBanList:GetList", function()
    AliumBanList:Log("Ожидаем загрузки HTTP...")
    timer.Simple(0, function()
        AliumBanList:Get()
    end)
end)

hook_Add("CheckPassword", "AliumBanList:CheckList", function(steamid64, ip, svPass, clPass, nick)
    local cfg = AliumBanList["cfg"]
    if (AliumBanList["Bans"][steamid64] == true) then
        if (cfg["printDisconnect"] == true) then
            MsgC(cfg["colors"]["tagColor"], "["..cfg["tag"].."] ", cfg["colors"]["msgColor"], "Игрок, ", cfg["colors"]["nickColor"], nick, " ("..toSteamID(steamid64)..")", ", был заблокирован при попытке зайти на сервер!", "\n")
        end

        return false, cfg["disconnectMessage"]
    end
end)

concommand_Add("alium_bans_update", function(ply)
    if IsValid(ply) then
        if ply:IsSuperAdmin() or ply:IsListenServerHost() then
            AliumBanList:Get()
        else
            local cfg = AliumBanList["cfg"]
            local col1 = cfg["colors"]["tagColor"]
            local col2 = cfg["colors"]["msgColor"]
            ply:SendLua('MsgC(Color('..col1["r"]..', '..col1["g"]..', '..col1["b"]..'), "['..cfg["tag"]..'] ", Color('..col2["r"]..', '..col2["g"]..', '..col2["b"]..'), "У вас недостаточно прав для выполнения данного действия!", "\n")')
        end
    else
        AliumBanList:Get()
    end
end)