--[[
  _____  _              ___   _  _                    ______                 _      _       _   
 |_   _|| |            / _ \ | |(_)                   | ___ \               | |    (_)     | |  
   | |  | |__    ___  / /_\ \| | _  _   _  _ __ ___   | |_/ /  __ _  _ __   | |     _  ___ | |_ 
   | |  | '_ \  / _ \ |  _  || || || | | || '_ ` _ \  | ___ \ / _` || '_ \  | |    | |/ __|| __|
   | |  | | | ||  __/ | | | || || || |_| || | | | | | | |_/ /| (_| || | | | | |____| |\__ \| |_ 
   \_/  |_| |_| \___| \_| |_/|_||_| \__,_||_| |_| |_| \____/  \__,_||_| |_| \_____/|_||___/ \__|                                                                                                                                                                                                                                                                                                                   
--]]

if game.SinglePlayer() then return end -- В сингл плеере оно нам и нахуй не нужно)

if not EasyLoader then
    if SERVER then
        AddCSLuaFile("easyloader/easyloader_compact.lua")
    end

    include("easyloader/easyloader_compact.lua")
end

AliumBanList = AliumBanList or {}

--[[
    Дружок сталкерок конфигурация этажом ниже \/
--]]
AliumBanList["cfg"] = {
    ["tag"] = "Pika Software",  -- Тег для логов в консоли
    ["printDisconnect"] = true, -- Выводить информацию о блокировке игрока в консоль сервера
    ["banListURL"] = "https://cdn.jsdelivr.net/gh/Pika-Software/TheAliumBanList/banned_user.cfg",
    ["colors"] = {
        ["tagColor"] = Color(0, 103, 221),  -- Цвет тега
        ["msgColor"] = Color(224,182,42),   -- Цвет сообщения
        ["nickColor"] = Color(18, 184, 206),    -- Цвет ника
    },

    -- Сообщение которое увидит отключённый игрок
    ["disconnectMessage"] = [[
        Ваш STEAMID не проходит по системе 
        блокировок сателлитов или(и) вы имеете 
        особое отношение к Персонам Нон Грата 
        The Alium.

        Вы можете обжаловать решение блокировки
        в комментариях модератора Erick's Maid.

        https://steamcommunity.com/groups/thealium
    ]],
}

function AliumBanList:Log(...)
    MsgC(self["cfg"]["colors"]["tagColor"], "["..self["cfg"]["tag"].."] ", self["cfg"]["colors"]["msgColor"], ..., "\n")
end

EasyLoader:Load("alium_community_bans", "AliumCommunityBans")
AliumBanList["Loaded"] = true