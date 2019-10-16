local name, addon = ...

function table:has(value)
    for _,v in ipairs(self) do
        if v == value then return true end;
    end
    return false;
end

function table:any(values)
    for _,v in ipairs(self) do
        if values:has(v) then return true end;
    end
    return false;
end

function T(t)
    return setmetatable(t, {__index = table})
end

function ENUM(t)
    for k,v in pairs(t) do t[v] = k end;
    return t;
end

function COLOR(t)
    for k,v in pairs(t) do
        string[k] = function(self) return "|c"..v..self.."|r" end;
    end
end

COLOR {
    RED = "FFFF0000",
    ORANGE = "FFFF8000",
    GREEN = "FF33DA33",
    YELLOW = "FFFFFF00",
    BLUE = "FF00BFFF",
    DBLUE = "FF0070DD",
    WHITE = "FFFFFFFF",
    PURPLE = "FFA335EE"
}

local EVENTS = {
    GROUP_ROSTER_UPDATE = 'GROUP_ROSTER_UPDATE',
    CHAT_MSG_CHANNEL = 'CHAT_MSG_CHANNEL'
};

function Relay(init)
    Relay = {
        listeners = T{},
        frame = CreateFrame("Frame"),
    };
    
    function Relay.On(self, event)
        self.frame:RegisterEvent(event);
        function self.Do(self, listener)            
            self.listeners[event] = listener;
        end

        return self;
    end
    
    function Relay.Of(self, event)
        self.frame:UnregisterEvent(event);
    end
    Relay.frame:SetScript("OnEvent", function(self, a, b, c, d, e, f, g, h, i, j) return Relay.listeners[a] and Relay.listeners[a](a, b, c, d, e, f, g, h, i, j) end);
    
    if init then
        Relay.listeners["ADDON_LOADED"] = function(a, b)
            if b == name then init() end;
        end;
        Relay.frame:RegisterEvent("ADDON_LOADED");
    end
    return Relay;
end

local relay = nil;

local PREFIX = ("[Chat LFG]"):YELLOW();

local localizedClass, englishClass, classIndex = UnitClass("player");

local search_type = nil;
local search_term = "";
local search_dungeon = T{};

local GROUP_SIZE = {
    ["Scarlet Monastery"] = 5,
    ["Blackrock Depths"] = 5,
    ["Stratholme"] = 5,
    ["Scholomance"] = 5,
    ["Lower Blackrock Spire"] = 10,
    ["Upper Blackrock Spire"] = 10,
    ["Zul'Farrak"] = 5,
    ["The Deadmines"] = 5,
    ["Shadowfang Keep"] = 5,
    ["Dire Maul"] = 5,
    ["Uldaman"] = 5,
    ["Blackfathom Deeps"] = 5,
    ["Maraudon"] = 5,
    ["Razorfen Downs"] = 5,
    ["Sunken Temple"] = 5,
    ["Wailing Caverns"] = 5,
    ["Gnomeregan"] = 5,
    ["Razorfen Kraul"] = 5,
    ["Ragefire Chasm"] = 5,
    ["Stockade"] = 5,
    ["Molten Core"] = 40,
    ["Onyxia"] = 40
}

local DUNGEON = {
    ["Scarlet Monastery"] = "SM",
    ["Blackrock Depths"] = "BRD",
    ["Stratholme"] = "Stratholme",
    ["Scholomance"] = "Scholomance",
    ["Lower Blackrock Spire"] = "LBRS",
    ["Upper Blackrock Spire"] = "UBRS",
    ["Zul'Farrak"] = "ZF",
    ["The Deadmines"] = "Deadmines",
    ["Shadowfang Keep"] = "SFK",
    ["Dire Maul"] = "DM",
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
    TANK = ('Tank'):BLUE(),
    DPS = ('DPS'):RED(),
    HEALER = ('Healer'):GREEN(),
    LFM = ('LFM'):BLUE(),
    LFG = ('LFG'):GREEN()
}

for k,_ in pairs(DUNGEON) do
    LABEL[k] = (k):DBLUE();
end

for k,_ in pairs(RAID) do
    LABEL[k] = (k):ORANGE();
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
    HEALER = 'HEALER',
    ANY = 'ANY'
};
local PATTERN = {
    LFM = "[lL][fF](%d?)[mM]",
    LFG = "[lL][fF][gG]",
    DPS = "[dD][pP][sS]",
    TANK = "[tT][aA][nN][kK]",
    HEALER = "[hH][eE][aA][lL][eE]?[rR]?"
}

local LF = ENUM {
    LFM = -1,
    LFG = 1
};

function intersection(string1, string2)
    if string1 == string2 then return string2:len(), 1, string2:len() end;

    for i=string1:len(),math.max(math.floor(string1:len()/2), 2),-1 do
        local s, e = string2:upper():find("%f[%a]"..string1:sub(1, i):upper());
        if s then
            return i, s, e;
        end;
    end

    return 0, 0, 0;
end

function extractDungeon(message)
    local match = "";
    local dungeon = nil;
    local rest = nil;

    for k, v in pairs(DUNGEON) do
        local l, s, e = intersection(v, message);
        if l > match:len() then
            match = message:sub(s, e);
            rest = message:sub(1, s - 1)..message:sub(e + 1, message:len());
            dungeon = k;
        end
    end
    for k, v in pairs(RAID) do
        local l, s, e = intersection(v, message);
        if l > match:len() then
            match = message:sub(s, e);
            rest = message:sub(1, s - 1)..message:sub(e + 1, message:len());
            dungeon = k;
        end
    end

    return LABEL[dungeon], rest;
end

function parseMessage(message)
    local lf = nil;
    local roles = {};
    local match = nil;
    local dungeons = T{};
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

    local dungeon, rest = extractDungeon(message);
    while (dungeon ~= nil)
    do
        table.insert(dungeons, dungeon);
        message = rest;
        dungeon, rest = extractDungeon(message);
    end
    
    if n == "" and #roles > 0 then
        n = #roles;
    elseif n then
        for i=1, (tonumber(n) or 1) - (#roles or 0) do
            table.insert(roles, ROLE.ANY);
        end
    end
    for _,v in pairs(PATTERN) do
        message = message:gsub(v, "");
    end
    message = message:gsub("%s%s+", " "):match("^%s*(.-)%s*$");

    return lf, T(roles), dungeons, message;
end

function ChatMSGChannelHandler(event, message, author, _, _, _, _, _, _, channel)
    if (channel == CHANNEL.LOOKING_FOR_GROUP or channel == CHANNEL.WORLD or channel == CHANNEL.GENERAL) then
        local lf, roles, dungeon, message = parseMessage(message);

        local lf_roles = T{};
        if search_type == LF.LFM and search_dungeon:getn() then
            local size = GROUP_SIZE[search_dungeon[1]] or 5;
            local dps, healers, tanks = size * 0.6, size * 0.2, size * 0.2;

            for _,v in pairs(ChatLFGRoles) do
                if v == ROLE.DPS then dps = dps-1 end
                if v == ROLE.HEALER then healers = healers-1 end
                if v == ROLE.TANK then tanks = tanks-1 end
            end
            for i=1,dps do
                table.insert(lf_roles, ROLE.DPS);
            end
            for i=1,healers do
                table.insert(lf_roles, ROLE.HEALER);
            end
            for i=1,tanks do
                table.insert(lf_roles, ROLE.TANK);
            end
        else
            lf_roles = T{ChatLFGRoles.SELF, ROLE.ANY};
        end
       
        if lf == -search_type and (search_dungeon:any(dungeon) and (search_term ~= "" and string.find(message:lower(), search_term:lower()))) and roles:any(lf_roles) then
            local roles_text = table.concat(roles, ",");
            for k,v in pairs(LABEL) do
                roles_text = roles_text:gsub(k, v);
            end
            print(PREFIX, ("|Hplayer:"..author.."|h["..author.."]|h"):YELLOW(), "["..LABEL[LF[lf]].."]"..((roles:getn() > 0 and not roles:has(ROLE.ANY) and " "..roles_text) or ""), dungeon:concat(','), message);
        end
    end
end

SLASH_CLFG1 = "/clfg"
SLASH_CLFG2 = "/chatlfg"

function caseInsensitivePattern(str)
    local pattern = "";
    for i=1,str:len() do
        pattern = pattern + "["..str:sub(i, 1):lower()..str:sub(i, 1):upper().."]";
    end

    return pattern;
end

SlashCmdList["CLFG"] = function(msg)
    local _, _, cmd, arg = string.find(msg, "%s?(%w+)%s?(.*)");
    if (cmd == COMMAND.LFM or cmd == COMMAND.LFG) then
        if (ChatLFGRoles.SELF == nil) then
            print(PREFIX, ("[ERROR]"):RED(), ("Role not set. Please set your role with '/clfg role Tank/DPS/Healer' then try again."):RED());
            return
        end
        search_term = arg;
        if cmd == COMMAND.LFM then
            search_type = LF.LFM;
        else
            search_type = LF.LFG;
        end
        if (search_term ~= "") then
            relay:On(EVENTS.CHAT_MSG_CHANNEL):Do(ChatMSGChannelHandler);
            JoinChannelByName(CHANNEL.LOOKING_FOR_GROUP);
            JoinChannelByName(CHANNEL.WORLD);
            search_dungeon = T{}
            
            local dungeon, rest = extractDungeon(search_term);
            while (dungeon ~=nil)
            do
                table.insert(search_dungeon, dungeon);
                search_term = rest
                dungeon, rest = extractDungeon(rest);
            end
            search_term = search_term:match("^%s*(.-)%s*$");
            print(PREFIX, LABEL[LF[search_type]]..' '..search_dungeon:concat(",")..((search_term ~="" and ' "'..search_term:WHITE()..'"') or ""));
        end
    elseif (cmd == COMMAND.ROLE) then
        if (ROLE[arg:upper()]) then
            ChatLFGRoles.SELF = LABEL[arg:upper()];
            print(PREFIX, ('Role set to '):YELLOW()..ChatLFGRoles.SELF);
        end
    elseif cmd == COMMAND.STOP then
        relay:Of(EVENTS.CHAT_MSG_CHANNEL);
        LeaveChannelByName(CHANNEL.LOOKING_FOR_GROUP);
        LeaveChannelByName(CHANNEL.WORLD);
        print(PREFIX, LABEL[LF[search_type]]..' '..(search_dungeon:concat(",") or '"'..(search_term):WHITE()..'"')..(' search stopped'):YELLOW());
        search_type = nil;
        search_dungeon = T{};
    end
end

local MENU = ENUM {
    SIGNUP = "LFG_SIGNUP",
    ROLE = "LFG_ROLE",
    ROLE_MENU = "LFG_ROLE_MENU",
    [ROLE.DPS] = "LFG_ROLE_DPS",
    [ROLE.TANK] = "LFG_ROLE_TANK",
    [ROLE.HEALER] = "LFG_ROLE_HEALER"
};

function LFG_ToggleDropDownMenu(level, value, dropDownFrame, anchorName, ofsX, ofsY, menuList, button)
    if value == MENU.ROLE_MENU and UIDROPDOWNMENU_OPEN_MENU and not UIDropDownMenu_GetSelectedValue(UIDROPDOWNMENU_OPEN_MENU) then
        UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, MENU[ChatLFGRoles[UIDROPDOWNMENU_OPEN_MENU.name]])
    end
end

function LFG_UnitPopup_OnClick(self)
    if UIDROPDOWNMENU_OPEN_MENU then
        UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, self.value)
        ChatLFGRoles[UIDROPDOWNMENU_OPEN_MENU.name] = MENU[self.value];
    end;
end

relay = Relay(
    function()
        if ChatLFGRoles == nil then
            ChatLFGRoles = {
                SELF = nil
            };
        end
    
        UnitPopupButtons[MENU.LFG_SIGNUP] = { text = "Sign up for instance group" };
        UnitPopupButtons[MENU.ROLE_MENU] = {
            text = "Set role",
            nested = 1,
        };
        UnitPopupButtons[MENU.ROLE] = {
            text = "Set role",
            isTitle = 1
        }
        UnitPopupButtons[MENU.DPS] = {
            text = LABEL[ROLE.DPS],
            checkable = 1
        }
        UnitPopupButtons[MENU.TANK] = {
            text = LABEL[ROLE.TANK],
            checkable = 1
        }
        UnitPopupButtons[MENU.HEALER] = {
            text = LABEL[ROLE.HEALER],
            checkable = 1
        }
        
        UnitPopupMenus[MENU.ROLE_MENU] = T{};

        table.insert(UnitPopupMenus[MENU.ROLE_MENU], MENU.ROLE);
        table.insert(UnitPopupMenus[MENU.ROLE_MENU], MENU.DPS);
        table.insert(UnitPopupMenus[MENU.ROLE_MENU], MENU.TANK);
        table.insert(UnitPopupMenus[MENU.ROLE_MENU], MENU.HEALER);
        
        table.insert(UnitPopupMenus["PLAYER"], #UnitPopupMenus["PLAYER"]-1, MENU.LFG_SIGNUP);
        table.insert(UnitPopupMenus["FRIEND"], #UnitPopupMenus["FRIEND"]-1, MENU.LFG_SIGNUP);
        table.insert(UnitPopupMenus["PARTY"], #UnitPopupMenus["PARTY"]-1, MENU.ROLE_MENU);
        table.insert(UnitPopupMenus["RAID"], #UnitPopupMenus["RAID"]-1, MENU.ROLE_MENU);
        hooksecurefunc("ToggleDropDownMenu", LFG_ToggleDropDownMenu);
        hooksecurefunc("UnitPopup_OnClick", LFG_UnitPopup_OnClick);

        relay:On(EVENTS.GROUP_ROSTER_UPDATE):Do(function()
            if not IsInGroup() then
                ChatLFGRoles = {
                    SELF = ChatLFGRoles.SELF;
                };
            end
        end);
        C_ChatInfo.RegisterAddonMessagePrefix(PREFIX);
    end)
