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

/*
    Configuration
*/
AliumBanList["cfg"] = {
    ["banListURL"] = "https://raw.githubusercontent.com/PrikolMen/the-alium-bans/main/banned_user.cfg",
    ["disconnectMessage"] = [[
-------===== [ The Alium ] =====-------

Доступ к этому серверу для вас ограничен!
Дополнительная информация в группе Steam:

https://steamcommunity.com/groups/thealium
]]
}

function AliumBanList:Log(...)
    MsgC(Color(0, 103, 221), "[Pika Software] ", Color(224,182,42), ..., "\n")
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

            ["success"] = function(code, body, headers)
                if code == 200 then
                    AliumBanList["Bans"] = {}

                    for line in body:gmatch("(.-)\n") do
                        line = line:gsub("\r","")
                        local st, ed = string.find(line, "banid 0 ", 0)
                        if ed != nil then
                            AliumBanList["Bans"][util.SteamIDTo64(string.sub(line, ed+1, #line))] = true
                        end
                    end
                end
            end,
        }) != nil then
            self:Log("Списко банов 'The Alium' успешно получен!")
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

concommand.Add("alium_bans_update", function(ply)
    if IsValid(ply) then
        if ply:IsSuperAdmin() or ply:IsListenServerHost() then
            AliumBanList:Get()
        else
            ply:SendLua('MsgC(Color(0, 103, 221), "[Pika Software] ", Color(224,182,42), "У вас недостаточно прав для данного действия!", "\n")')
        end
    else
        AliumBanList:Get()
    end
end)

hook.Add("CheckPassword", "AliumBanList:CheckList", function(steamid64, ip, svPass, clPass, nick)
    if (AliumBanList["Bans"][steamid64] == true) then
        return false, AliumBanList["cfg"]["disconnectMessage"]
    end
end)