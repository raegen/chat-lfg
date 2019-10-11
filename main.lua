local frame = CreateFrame("Frame")
local hooks = {}
local CHANNELS = {
    LOOKING_FOR_GROUP = 'LookingForGroup',
    WORLD = 'World',
    GENERAL = 'General'
}

local filter = "";
SLASH_CLFG1 = "/clfg"
SlashCmdList["CLFG"] = function(msg)
    filter = msg;
    if (filter ~= "") then
        JoinChannelByName(CHANNELS.LOOKING_FOR_GROUP);
        JoinChannelByName(CHANNELS.WORLD);
        JoinChannelByName(CHANNELS.GENERAL);
    else
        LeaveChannelByName(CHANNELS.LOOKING_FOR_GROUP);
        LeaveChannelByName(CHANNELS.WORLD);
        LeaveChannelByName(CHANNELS.GENERAL);
    end
end 

frame:RegisterEvent("CHAT_MSG_CHANNEL")
frame:SetScript("OnEvent", function(self, event, message, author, c, d, e, f, g, h, channel)
    if (channel == CHANNELS.LOOKING_FOR_GROUP or channel == CHANNELS.WORLD or channel == CHANNELS.GENERAL) then
        if (filter ~= "" and string.find(message, filter)) then
            print("|cFF0EC4DB|Hplayer:"..author.."|h["..author.."]|h", message);
        end
    end
end)
