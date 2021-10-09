local toSteamID = util.SteamIDFrom64
local toSteamID64 = util.SteamIDTo64
local stGmatch = string.gmatch
local stFind = string.find
local stGsub = string.gsub
local stSub = string.sub
local pairs = pairs
local HTTP = HTTP
local MsgC = MsgC

// Net
util.AddNetworkString("AliumBansNet")

function AliumBanList:Notify(ply, msg)
    net.Start("AliumBansNet")
        net.WriteString(msg)
    net.Send(ply)
end

// Bans
function AliumBanList:Get()
    if (HTTP({
        ["url"] = self["cfg"]["banListURL"],
        ["method"] = "GET",
        ["headers"] = {
            ["accept-encoding"] = "gzip, deflate",
            ["accept-language"] = "en",
        },
        ["success"] = function(code, body)
            if code == 200 and body != "" then
                self["Bans"] = {}
                for line in stGmatch(body,"(.-)\n") do
                    line = stGsub(line, "\r","")
                    local st = stFind(line, "STEAM_0:", 0)
                    if st != nil then
                        self["Bans"][toSteamID64(stSub(line, st, #line))] = true
                    end
                end
            end
        end,
    }) != nil) then
        self:Log("Список банов от сообщества 'The Alium' успешно получен!")
    else
        self:Log("Возникла ошибка при получении списка банов!")
    end
end

timer.Simple(0, function()
    AliumBanList:Get()
end)

hook.Add("CheckPassword", "AliumBanList:CheckList", function(steamid64, ip, svPass, clPass, nick)
    if (AliumBanList["Bans"] == nil) then return end

    local cfg = AliumBanList["cfg"]
    if (AliumBanList["Bans"][steamid64] == true) then
        if (cfg["printDisconnect"] == true) then
            MsgC(cfg["colors"]["tagColor"], "["..cfg["tag"].."] ", cfg["colors"]["msgColor"], "Игрок, ", cfg["colors"]["nickColor"], nick, " ("..toSteamID(steamid64)..")", ", был заблокирован при попытке зайти на сервер!", "\n")
        end

        return false, cfg["disconnectMessage"]
    end
end)

// Commands
concommand.Add("alium_bans_update", function(ply)
    if IsValid(ply) then
        if (ply:IsSuperAdmin() or ply:IsListenServerHost()) then
            AliumBanList:Get()
        else
            AliumBanList:Notify(ply, "У вас недостаточно прав для выполнения данного действия!")
       end
    else
        AliumBanList:Get()
    end
end)