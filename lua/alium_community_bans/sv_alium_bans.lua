local steamworks_RequestPlayerInfo = steamworks.RequestPlayerInfo
local util_AddNetworkString = util.AddNetworkString
local net_WriteString = net.WriteString
local concommand_Add = concommand.Add
local toSteamID = util.SteamIDFrom64
local toSteamID64 = util.SteamIDTo64
local timer_Simple = timer.Simple
local stGmatch = string.gmatch
local net_Start = net.Start
local stFind = string.find
local stGsub = string.gsub
local hook_Add = hook.Add
local net_Send = net.Send
local stSub = string.sub
local IsValid = IsValid
local pairs = pairs
local HTTP = HTTP
local MsgC = MsgC

// Net
util_AddNetworkString("AliumBansNet")

function AliumBanList:Notify(ply, msg)
    net_Start("AliumBansNet")
        net_WriteString(msg)
    net_Send(ply)
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
        self:Log("Списко банов от сообщества 'The Alium' успешно получен!")
    else
        self:Log("Возникла ошибка при получении списка банов!")
    end
end

timer_Simple(0, function()
    AliumBanList:Get()
end)

hook_Add("CheckPassword", "AliumBanList:CheckList", function(steamid64, ip, svPass, clPass, nick)
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
concommand_Add("alium_bans_update", function(ply)
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

function AliumBanList:GetNames()
    if (AliumBanList["Bans"] == nil) then return end

    local num = 1
    for steamid64, bool in pairs(self["Bans"]) do
        timer_Simple(0.25*num, function()
            steamworks_RequestPlayerInfo(steamid64, function(name)
                self:Log(steamid64.." ("..steamid64..")")
            end)
        end)

        num = num + 1
    end
end

concommand_Add("alium_bans_get", function(ply)
    if IsValid(ply) then
        if ply:IsListenServerHost() then
            AliumBanList:GetNames()
        else
            AliumBanList:Notify(ply, "У вас недостаточно прав для выполнения данного действия!")
        end
    else
        AliumBanList:GetNames()
    end
end)