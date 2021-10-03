// Player Notify
net.Receive("AliumBansNet", function()
    AliumBanList:Log(net.ReadString())
end)