local frame = CreateFrame("Frame");
local hooks = {};

function c(string, color)
    return "|c"..color..string.."|r";
end

local COLOR = {
    RED = "FFFF0000",
    ORANGE = "FFFFA500",
    GREEN = "FF33DA33",
    YELLOW = "FFFFFF00",
    BLUE = "FF00BFFF",
    WHITE = "FFFFFFFF"
}

local DUNGEON = {
    ["Scarlet Monastery"] = "SM",
    ["Blackrock Depths"] = "BRD",
    ["Stratholme"] = "Stratholme",
    ["Scholomance"] = "Scholomance",
    ["Lower Blackrock Spire"] = "LBRS",
    ["Upper Blackrock Spire"] = "UBRS",
    ["Zul'Farrak"] = "ZF",
    ["The Deadmines"] = "DM",
    ["Shadowfang Keep"] = "SFK",
    ["Dire Maul"] = "Dire Maul",
    ["Uldaman"] = "Uldaman",
    ["Blackfathom Deeps"] = "BFD",
    ["Maraudon"] = "Maraudon",
    ["Razorfen Downs"] = "RFD",
    ["Sunken Temple"] = "ST",
    ["Wailing Caverns"] = "WC",
    ["Gnomeregan"] = "Gnomeregan",
    ["Razorfen Kraul"] = "RFK",
    ["Ragefire Chasm"] = "RFC",
    ["Stockade"] = "Stockade"
};

local RAID = {
    ["Molten Core"] = "MC",
    ["Onyxia"] = "Onyxia"
}

local LABEL = {
    TANK = c('Tank', COLOR.BLUE),
    DPS = c('DPS', COLOR.RED),
    HEALER = c('Healer', COLOR.GREEN),
    LFM = c('LFM', COLOR.GREEN),
    LFG = c('LFG', COLOR.BLUE)
}

for k,v in pairs(DUNGEON) do
    LABEL[k] = c(k, COLOR.BLUE);
    LABEL[v] = c(k, COLOR.BLUE);
end

for k,v in pairs(RAID) do
    LABEL[k] = c(v, COLOR.ORANGE);
    LABEL[v] = c(v, COLOR.ORANGE);
end

local COMMAND = {
    LFG = 'lfg',
    LFM = 'lfm',
    ROLE = 'role',
    STOP = 'stop'
}
local CHANNEL = {
    LOOKING_FOR_GROUP = 'LookingForGroup',
    WORLD = 'World',
    GENERAL = 'General'
};
local ROLE = {
    TANK = 'TANK',
    DPS = 'DPS',
    HEALER = 'HEALER'
};
local PATTERN = {
    LFM = "[lL][fF](%d?)[mM]",
    LFG = "[lL][fF][gG]",
    DPS = "[dD][pP][sS]",
    TANK = "[tT][aA][nN][kK]",
    HEALER = "[hH][eE][aA][lL][eE]?[rR]?"
}

function compare(string1, string2)
    if string1 == string2 then return string1:len() end;
    if string1:len() < string2:len() then string1, string2 = string2, string1 end;

    for i=string2:len(),math.max(math.floor(string2:len()/2), 1),-1 do
        if string1:upper():find("%f[%a]"..string2:sub(1, i):upper()) then
            return i;
        end;
    end

    return 0;
end

function extractDungeon(message)
    local match = "";
    local dungeon = nil;

    for _, v in pairs(DUNGEON) do
        local s = compare(v, message);
        if s > match:len() then
            match = ((v:len() > message:len() and message) or v):sub(1, s);
            dungeon = v;
        end
    end
    for _, v in pairs(RAID) do
        local s = compare(v, message);
        if s > match:len() then
            match = ((v:len() > message:len() and message) or v):sub(1, s);
            dungeon = v;
        end
    end

    return (dungeon and {name = LABEL[dungeon], match = match}) or nil;
end

local LF = {
    LFM = "LFM",
    LFG = "LFG"
};

function parseMessage(message)
    local lf = nil;
    local roles = {};
    local match = nil;
    local dungeon = nil;
    local n = nil;

    match, _, n = message:find(PATTERN.LFM);
    
    if match ~= nil then 
        lf = LF.LFM;
    elseif message:find(PATTERN.LFG) then
        lf = LF.LFG;
    elseif (message:find(PATTERN.DPS) or message:find(PATTERN.TANK) or message:find(PATTERN.HEALER)) then 
        lf = LF.LFM;
    else
        lf = LF.LFG;
    end;
    if (message:find(PATTERN.DPS)) then table.insert(roles, ROLE.DPS) end;
    if (message:find(PATTERN.TANK)) then table.insert(roles, ROLE.TANK) end;
    if (message:find(PATTERN.HEALER)) then table.insert(roles, ROLE.HEALER) end;

    dungeon = extractDungeon(message);
    
    if n == "" and #roles > 0 then
        n = #roles;
    end

    return lf, n, roles, dungeon;
end

local PREFIX = c("[Chat LFG]:", COLOR.YELLOW);

local localizedClass, englishClass, classIndex = UnitClass("player");

local search_type = nil;
local search_term = "";
local search_dungeon = nil;
SLASH_CLFG1 = "/clfg"
SlashCmdList["CLFG"] = function(msg)
    local _, _, cmd, arg = string.find(msg, "%s?(%w+)%s?(.*)");
    if (cmd == COMMAND.LFM or cmd == COMMAND.LFG) then
        if (ChatLFGRole == nil) then
            print(PREFIX, c("[ERROR]", COLOR.RED), c("Role not set. Please set your role with '/clfg role Tank/DPS/Healer' then try again.", COLOR.RED));
            return
        end
        search_term = arg;
        if cmd == COMMAND.LFM then
            search_type = LF.LFM;
        else
            search_type = LF.LFG;
        end
        if (search_term ~= "") then
            frame:RegisterEvent("CHAT_MSG_CHANNEL");
            JoinChannelByName(CHANNEL.LOOKING_FOR_GROUP);
            JoinChannelByName(CHANNEL.WORLD);
            search_dungeon = extractDungeon(search_term) and extractDungeon(search_term).name;
            print(PREFIX, c(search_type..' '..(search_dungeon or '"'..search_term..'"'), COLOR.YELLOW));
        end
    elseif (cmd == COMMAND.ROLE) then
        if (ROLE[arg:upper()]) then
            ChatLFGRole = LABEL[arg:upper()];
            print(PREFIX, c('Role set to '..ChatLFGRole, COLOR.YELLOW));
        end
    elseif cmd == COMMAND.STOP then
        frame:UnregisterEvent("CHAT_MSG_CHANNEL");
        LeaveChannelByName(CHANNEL.LOOKING_FOR_GROUP);
        LeaveChannelByName(CHANNEL.WORLD);
        print(PREFIX, c(search_type..' '..(search_dungeon or '"'..c(search_term, COLOR.WHITE)..'"')..c(' stopped', COLOR.YELLOW), COLOR.YELLOW));
        search_type = nil;
        search_dungeon = nil;
    end
end

function includes(value, table)
    for _,v in ipairs(table) do
        if v == value then
            return true;
        end
    end
    return false;
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
                    local player = _G[buttonPrefix.."1"]:GetText();
                    local message = "";
                    local level = UnitLevel("player");
                    message = message..ChatLFGRole;
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

function LFGChatOnLoad()
    local UNIT_POPUP_MENU_ITEM = "LFG_SIGNUP";
    UnitPopupButtons[UNIT_POPUP_MENU_ITEM] = { text = "Sign up for instance group" };
    table.insert(UnitPopupMenus["PLAYER"], #UnitPopupMenus["FRIEND"]-1, UNIT_POPUP_MENU_ITEM);
    table.insert(UnitPopupMenus["FRIEND"], #UnitPopupMenus["FRIEND"]-1, UNIT_POPUP_MENU_ITEM);

    hooksecurefunc("ToggleDropDownMenu", LFG_SignUp_Setup);
end

frame:SetScript("OnEvent", function(self, event, message, author, _, _, _, _, _, _, channel)
    if (event == "CHAT_MSG_CHANNEL" and (channel == CHANNEL.LOOKING_FOR_GROUP or channel == CHANNEL.WORLD or channel == CHANNEL.GENERAL)) then
        local lf, n, roles, dungeon = parseMessage(message);

        if (search_dungeon and dungeon and search_dungeon == dungeon.name) or (search_term ~= "" and string.find(message:lower(), search_term:lower())) then
            local type = (lf == LF.LFM and c("LF"..(n or "").."M", COLOR.GREEN)) or (lf == LF.LFG and c(LF.LFG, COLOR.BLUE));
            local roles_text = table.concat(roles, ",");
            
            if ((lf == LF.LFM and search_type == LF.LFG) or (lf == LF.LFG and search_type == LF.LFM)) and (includes(role, roles) == true or #roles == 0) then
                for _,v in pairs(PATTERN) do
                    message = message:gsub(v, "");
                end
                message = message:gsub(dungeon.match, ""):gsub("%s%s+", " "):match("^%s*(.-)%s*$");
                
                for k,v in pairs(LABEL) do
                    roles_text = roles_text:gsub(k, v);
                end
                
                print(PREFIX, c("|Hplayer:"..author.."|h["..author.."]|h", COLOR.YELLOW), "["..type.."]"..((#roles > 0 and " "..roles_text) or ""), dungeon.name, message);
            end
        end
    elseif event == "ADDON_LOADED" and message == "ChatLFG" then
        LFGChatOnLoad();
    end
end)

frame:RegisterEvent("ADDON_LOADED");
