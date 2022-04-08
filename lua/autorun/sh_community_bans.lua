if game.SinglePlayer() then return end
CommunityBans = CommunityBans or {}

MsgC( HSVToColor( math.random(360) % 360, 0.8, 0.8 ), [[
     ______     ______     __    __     __    __     __  __     __   __     __     ______   __  __
    /\  ___\   /\  __ \   /\ "-./  \   /\ "-./  \   /\ \/\ \   /\ "-.\ \   /\ \   /\__  _\ /\ \_\ \
    \ \ \____  \ \ \/\ \  \ \ \-./\ \  \ \ \-./\ \  \ \ \_\ \  \ \ \-.  \  \ \ \  \/_/\ \/ \ \____ \
     \ \_____\  \ \_____\  \ \_\ \ \_\  \ \_\ \ \_\  \ \_____\  \ \_\\"\_\  \ \_\    \ \_\  \/\_____\
      \/_____/   \/_____/   \/_/  \/_/   \/_/  \/_/   \/_____/   \/_/ \/_/   \/_/     \/_/   \/_____/

     ______     ______     __   __        __         __     ______     ______
    /\  == \   /\  __ \   /\ "-.\ \      /\ \       /\ \   /\  ___\   /\__  _\
    \ \  __<   \ \  __ \  \ \ \-.  \     \ \ \____  \ \ \  \ \___  \  \/_/\ \/
     \ \_____\  \ \_\ \_\  \ \_\\"\_\     \ \_____\  \ \_\  \/\_____\    \ \_\
      \/_____/   \/_/\/_/   \/_/ \/_/      \/_____/   \/_/   \/_____/     \/_/

]])

--[[--------------------------------------------
                Configuration
--------------------------------------------]]--

CommunityBans.Title = "Community Ban List"
CommunityBans.Colors = {
    ["Title"] = Color( 0, 103, 221 ),
    ["Message"] = Color( 224, 182, 42 )
}

CommunityBans.Reason = [[
    Ваш SteamID не проходит по системе
    блокировок сателлитов или(и) вы имеете
    особое отношение к Персонам Нон Грата
    The Alium.

    Вы можете обжаловать решение блокировки
    в комментариях модератора Erick's Maid.

    https://steamcommunity.com/groups/thealium
]]

CommunityBans.SilentMode = false
CommunityBans.ConsoleLogs = false
CommunityBans.BaseURL = "https://raw.githubusercontent.com/Pika-Software/gmod_community_bans/main/banned_user.cfg"

--[[----------------------------------------
                Don't touch!
----------------------------------------]]--

CommunityBans.Title = "[" .. CommunityBans.Title .. "] "

do

    local MsgC = MsgC
    local unpack = unpack
    local table_Add = table.Add

    function CommunityBans:Log( ... )
        local args = {...}
        timer.Simple(0, function()
            MsgC( self.Colors.Title, self.Title, self.Colors.Message, unpack( table_Add( args, {"\n"} ) ) )
        end)
    end

end

if (CLIENT) then

    local unpack = unpack
    local net_ReadTable = net.ReadTable

    net.Receive("CommunityBans", function()
        CommunityBans:Log( unpack( net_ReadTable() ) )
    end)
end

if (SERVER) then

    do

        util.AddNetworkString( "CommunityBans" )

        local net_Send = net.Send
        local net_Start = net.Start
        local net_WriteTable = net.WriteTable

        function CommunityBans:Notify( ply, ... )
            net_Start( "CommunityBans" )
                net_WriteTable( {...} )
            net_Send( ply )
        end

    end

    do

        local util_SteamIDTo64 = util.SteamIDTo64

        local function failed( reason )
            CommunityBans:Log( "Parsing ERROR: \n", reason )
        end

        local function success( code, body )
            if (code ~= 200) then return failed( "BaseURL returned incorrect response code: " .. code ) end
            if (body == nil) or (body == "") then return failed( "The response body is empty! (Code: 200)" ) end

            CommunityBans.List = {}

            for str in body:gmatch( "(.-)\n" ) do
                local line = str:gsub( "\r", "" )
                local start = line:find( "STEAM_", 0 )
                if (start == nil) then continue end
                if (start == "") then continue end

                CommunityBans.List[ util_SteamIDTo64( line:sub( start, #line ) ) ] = true
            end

            CommunityBans:Log( ("Parsing has been successfully completed, after %.4f seconds. (Code: 200)"):format( SysTime() - CommunityBans.ParsingStartTime ) )
        end

        local request = {
            method = "GET",
            failed = failed,
            success = success,
            url = CommunityBans.BaseURL
        }

        local HTTP = HTTP
        local SysTime = SysTime

        function CommunityBans:Get()
            CommunityBans.ParsingStartTime = SysTime()

            if not HTTP( request ) then
                CommunityBans:Log( "Unknown error in HTTP glua function!" )
            end
        end

    end

    do

        local util_SteamIDFrom64 = util.SteamIDFrom64

        local reason = CommunityBans.Reason == true
        local silent = CommunityBans.SilentMode == true
        local console_log = CommunityBans.ConsoleLogs == true

        hook.Add("CheckPassword", "CommunityBans", function( steamid64, ip, server_password, client_password, nickname )
            if (CommunityBans.List == nil) then return end

            if (CommunityBans.List[ steamid64 ] == true) then
                if (console_log) then
                    CommunityBans:Log( ("%s (%s) was blocked!"):format( nickname, util_SteamIDFrom64( steamid64 ) ) )
                end

                return false, silent and nil or reason
            end
        end)

    end

    do

        concommand.Add("community_bans_get", function( ply )
            if IsValid( ply ) then
                if (ply:IsSuperAdmin() or ply:IsListenServerHost()) then
                    CommunityBans:Get()
                else
                    CommunityBans:Notify( ply, "You do not have rights to perform this action!" )
                end
            else
                CommunityBans:Get()
            end
        end)

        concommand.Add("community_bans_print", function( ply )
            if IsValid( ply ) then
                return
            else
                if (CommunityBans.List == nil) then return end
                PrintTable( CommunityBans.List )
            end
        end)

        do

            local function clear()
                CommunityBans:Log( "List successfully cleared!" )
                if (CommunityBans.List == nil) then return end
                CommunityBans.List = nil
            end

            concommand.Add("community_bans_clear", function( ply )
                if IsValid( ply ) then
                    if (ply:IsSuperAdmin() or ply:IsListenServerHost()) then
                        clear()
                    else
                        CommunityBans:Notify( ply, "You do not have rights to perform this action!" )
                    end
                else
                    clear()
                end
            end)

        end

        do

            local util_SteamIDFrom64 = util.SteamIDFrom64
            local function save( name )
                if (CommunityBans.List == nil) then return end

                local filename = (name or "community_bans") .. ".txt"
                if file.Exists( filename, "DATA" ) then
                    file.Delete( filename )
                end

                file.Write( filename, "" )

                for steamid64, bool in SortedPairs( CommunityBans.List ) do
                    file.Append( filename, "banid 0 " .. util_SteamIDFrom64( steamid64 ) .. "\n" )
                end

                return filename
            end

            concommand.Add("community_bans_save", function( ply, cmd, args )
                if IsValid( ply ) then
                    if (ply:IsSuperAdmin() or ply:IsListenServerHost()) then
                        CommunityBans:Notify( ply, "File with ban list saved: garrysmod/data/", save( args[1] ) )
                    else
                        CommunityBans:Notify( ply, "You do not have rights to perform this action!" )
                    end
                else
                    CommunityBans:Log( "File with ban list saved: garrysmod/data/", save( args[1] ) )
                end
            end)

        end

        do

            local util_SteamIDTo64 = util.SteamIDTo64
            local function load( name )
                local filename = (name or "community_bans") .. ".txt"
                if file.Exists( filename, "DATA" ) then
                    if (CommunityBans.List == nil) then
                        CommunityBans.List = {}
                    end

                    local body = file.Read( filename, "DATA" )
                    if (body == nil) or (body == "") then
                        CommunityBans:Log( "Parsing ERROR: \n", "The response body is empty!" )
                        return "Parsing ERROR: \n", "The response body is empty!"
                    end

                    for str in body:gmatch( "(.-)\n" ) do
                        local line = str:gsub( "\r", "" )
                        local start = line:find( "STEAM_", 0 )
                        if (start == nil) then continue end
                        if (start == "") then continue end

                        CommunityBans.List[ util_SteamIDTo64( line:sub( start, #line ) ) ] = true
                    end

                    return "Bans loaded has been successfully completed! File: " .. filename
                else
                    return "Parsing ERROR: \n", " File not exists!"
                end
            end

            concommand.Add("community_bans_load", function( ply, cmd, args )
                if IsValid( ply ) then
                    if (ply:IsSuperAdmin() or ply:IsListenServerHost()) then
                        CommunityBans:Notify( ply, load( args[1] ) )
                    else
                        CommunityBans:Notify( ply, "You do not have rights to perform this action!" )
                    end
                else
                    CommunityBans:Log( load( args[1] ) )
                end
            end)

            local function hasBan( steamid )
                if isstring( steamid ) then
                    if steamid:match( "STEAM_" ) then
                        steamid = util.SteamIDTo64( steamid )
                    end

                    return CommunityBans.List[ steamid ] == true
                end

                return false
            end

            concommand.Add("community_bans_check", function( ply, cmd, args )
                if IsValid( ply ) then
                    if (ply:IsSuperAdmin() or ply:IsListenServerHost()) then
                        for num, str in ipairs( args ) do
                            CommunityBans:Notify( ply, string.format( "%s - %s", str, hasBan( str ) and "Yes" or "No" ) )
                        end
                    else
                        CommunityBans:Notify( ply, "You do not have rights to perform this action!" )
                    end
                else
                    for num, str in ipairs( args ) do
                        CommunityBans:Log( string.format( "%s - %s", str, hasBan( str ) and "Yes" or "No" ) )
                    end
                end
            end)

        end

    end

    timer.Simple(0, function()
        CommunityBans:Get()
    end)

end