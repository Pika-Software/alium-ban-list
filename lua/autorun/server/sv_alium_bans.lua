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

/*
    Configuration
*/
AliumBanList["cfg"] = {
    ["banListURL"] = "https://raw.githubusercontent.com/Pika-Software/TheAliumBanList/main/banned_user.cfg",
    ["printDisconnect"] = true,
    ["disconnectMessage"] = [[
-------===== [ The Alium ] =====-------

Доступ к этому серверу для вас ограничен!
Дополнительная информация в группе Steam:

https://steamcommunity.com/groups/thealium
]],
    ["tag"] = "Pika Software",
    ["colors"] = {
        ["tagColor"] = Color(0, 103, 221),
        ["msgColor"] = Color(224,182,42),
        ["nickColor"] = Color(18, 184, 206),
    }
}

function AliumBanList:Log(...)
    MsgC(AliumBanList["cfg"]["colors"]["tagColor"], "["..AliumBanList["cfg"]["tag"].."] ", AliumBanList["cfg"]["colors"]["msgColor"], ..., "\n")
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

hook.Add("InitPostEntity", "AliumBanList:GetList", function()
    AliumBanList:Get()
end)

hook.Add("CheckPassword", "AliumBanList:CheckList", function(steamid64, ip, svPass, clPass, nick)
    if (AliumBanList["Bans"][steamid64] == true) then
        if (AliumBanList["cfg"]["printDisconnect"] == true) then
            MsgC(AliumBanList["cfg"]["colors"]["tagColor"], "["..AliumBanList["cfg"]["tag"].."] ", AliumBanList["cfg"]["colors"]["msgColor"], "Игрок, ", AliumBanList["cfg"]["colors"]["nickColor"], nick, " ("..toSteamID(steamid64)..")", ", был заблокирован при попытке зайти на сервер!", "\n")
        end

        return false, AliumBanList["cfg"]["disconnectMessage"]
    end
end)

concommand.Add("alium_bans_update", function(ply)
    if IsValid(ply) then
        if ply:IsSuperAdmin() or ply:IsListenServerHost() then
            AliumBanList:Get()
        else
            local col1 = AliumBanList["cfg"]["colors"]["tagColor"]
            local col2 = AliumBanList["cfg"]["colors"]["msgColor"]
            ply:SendLua('MsgC(Color('..col["r"]..', '..col["g"]..', '..col["b"]..'), "['..AliumBanList["cfg"]["tag"]..'] ", Color('..col2["r"]..', '..col2["g"]..', '..col2["b"]..'), "У вас недостаточно прав для выполнения данного действия!", "\n")')
        end
    else
        AliumBanList:Get()
    end
end)