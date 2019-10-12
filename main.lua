local frame = CreateFrame("Frame")
local hooks = {}
local COMMAND = {
    FILTER = 'find',
    ROLE = 'role'
}
local CHANNEL = {
    LOOKING_FOR_GROUP = 'LookingForGroup',
    WORLD = 'World',
    GENERAL = 'General'
};
local ROLE = {
    TANK = 'Tank',
    DPS = 'DPS',
    HEALER = 'Healer'
};

local localizedClass, englishClass, classIndex = UnitClass("player");
local role = nil;

local filter = "";
SLASH_CLFG1 = "/clfg"
SlashCmdList["CLFG"] = function(msg)
    local _, _, cmd, arg = string.find(msg, "%s?(%w+)%s?(.*)");
    if (cmd == COMMAND.FILTER) then
        filter = arg;
        if (filter ~= "") then
            JoinChannelByName(CHANNEL.LOOKING_FOR_GROUP);
            JoinChannelByName(CHANNEL.WORLD);
            print('Chat LFG:', 'Group search started for "'..filter..'"');
        else
            LeaveChannelByName(CHANNEL.LOOKING_FOR_GROUP);
            LeaveChannelByName(CHANNEL.WORLD);
            print('Chat LFG:', 'Group search stopped.');
        end
    elseif (cmd == COMMAND.ROLE) then
        if (ROLE[arg:upper()]) then
            role = arg:upper();
            print('Chat LFG:', 'Role set to '..role);
        else
            role = nil;
            print('Chat LFG:', 'Role unset.');
        end
    end
end 

frame:RegisterEvent("CHAT_MSG_CHANNEL")
frame:SetScript("OnEvent", function(self, event, message, author, c, d, e, f, g, h, channel)
    if (channel == CHANNEL.LOOKING_FOR_GROUP or channel == CHANNEL.WORLD or channel == CHANNEL.GENERAL) then
        if (filter ~= "" and string.find(message:lower(), filter:lower())) then
            print("|cFF0EC4DB|Hplayer:"..author.."|h["..author.."]|h", message);
        end
    end
end)

local UNIT_POPUP_MENU_ITEM = "LFG_SIGNUP";
UnitPopupButtons[UNIT_POPUP_MENU_ITEM] = { text = "Sign up for instance group" };

function includes(value, table)
    for _,v in pairs(table) do
        if v == value then
            return true;
        end
    end
    return false;
end
if (includes(UNIT_POPUP_MENU_ITEM, UnitPopupMenus["PLAYER"]) == false) then
    -- Add it to the FRIEND and PLAYER menus as the 2nd to last option (before Cancel)
    table.insert(UnitPopupMenus["PLAYER"], #UnitPopupMenus["FRIEND"]-1, UNIT_POPUP_MENU_ITEM);
end

if (includes(UNIT_POPUP_MENU_ITEM, UnitPopupMenus["FRIEND"]) == false) then
    -- Add it to the FRIEND and PLAYER menus as the 2nd to last option (before Cancel)
    table.insert(UnitPopupMenus["FRIEND"], #UnitPopupMenus["FRIEND"]-1, UNIT_POPUP_MENU_ITEM);
end

-- Your function to setup your button
function LFG_SignUp_Setup(level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button, autoHideDelay)
    -- Make sure we have what we need to continue
    if (dropDownFrame and level) then
        -- Just so we don't have to concat strings for each interval
        local buttonPrefix = "DropDownList" .. level .. "Button";
        -- Start at 2 because 1 is always going to be the title (i.e. player name) in our case
        local i = 2;
        while (1) do
            -- Get the button at index i in the dropdown
            local button = _G[buttonPrefix..i];
            if (not button) then break end;
            -- If the button is our button...
            if (button:GetText() == UnitPopupButtons["LFG_SIGNUP"].text) then
                -- Make it invite the player that this menu popped up for (button at index 1)
                button.func = function()
                    if (role == nil) then
                        print("Role not set. Please set your role with '/clfg role Tank/DPS/Healer' then try again.");
                        return
                    end
                    local player = _G[buttonPrefix.."1"]:GetText();
                    local message = "";
                    local level = UnitLevel("player");
                    message = message..role;
                    if (level ~= 60) then
                        message = message.." ("..UnitLevel("player").." "..localizedClass..") here.";
                    else
                        message = message.." ("..localizedClass..") here."
                    end
                    message = message
                    SendChatMessage(message, "WHISPER", nil, player);
                end
                -- Break the loop; we got what we were looking for.
                break;
            end
            i = i + 1;
        end
    end
end

-- Hook ToggleDropDownMenu with your function
hooksecurefunc("ToggleDropDownMenu", LFG_SignUp_Setup);
