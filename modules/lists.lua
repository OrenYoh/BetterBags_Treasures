local addonName, root = ...;
local L = root.L;

---@class BetterBagsTreasures: AceModule
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName);

-- The player's lists: items always a treasure, and items never one. Items are given as an ID or a
-- link (Shift-click an item into a box or the chat line).

-- The item ID in a text: a number, or the ID in an item link
function addon:ParseItem(text)
    if type(text) ~= "string" then return nil end
    text = strtrim and strtrim(text) or text;
    local id = tonumber(text) or tonumber(string.match(text, "item:(%d+)"));
    if id and id > 0 then
        return math.floor(id);
    end
    return nil;
end

-- An item's name for messages and the list (its link once the game has it)
function addon:ItemLabel(itemID)
    local _, link = C_Item.GetItemInfo(itemID);
    if not link and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID);
    end
    return link or ("item:" .. itemID);
end

-- Puts an item on a list ("always" or "never"), taking it off the other one
function addon:ListItem(itemID, list)
    local other = list == "always" and "never" or "always";
    self.db[other][itemID] = nil;
    self.db[list][itemID] = true;
    self:Print(string.format(list == "always" and L["LIST_ADDED_ALWAYS"] or L["LIST_ADDED_NEVER"], self:ItemLabel(itemID)));
    self:Refresh(true);
end

function addon:UnlistItem(itemID)
    if not (self.db.always[itemID] or self.db.never[itemID]) then
        self:Print(string.format(L["LIST_NOT_LISTED"], self:ItemLabel(itemID)));
        return;
    end
    self.db.always[itemID] = nil;
    self.db.never[itemID] = nil;
    self:Print(string.format(L["LIST_REMOVED"], self:ItemLabel(itemID)));
    self:Refresh(true);
end

-- The listed items, for the options' menu: [itemID] = "Always: [Name]"
function addon:ListedItems()
    local values = {};
    for itemID in pairs(self.db.always) do
        values[itemID] = L["LIST_ALWAYS"] .. ": " .. self:ItemLabel(itemID);
    end
    for itemID in pairs(self.db.never) do
        values[itemID] = L["LIST_NEVER"] .. ": " .. self:ItemLabel(itemID);
    end
    return values;
end

-- /treasures always|never|remove <item>, /treasures list
SLASH_BETTERBAGSTREASURES1 = "/treasures";
SlashCmdList.BETTERBAGSTREASURES = function(message)
    local command, rest = string.match(message or "", "^%s*(%S*)%s*(.-)%s*$");
    command = string.lower(command or "");

    if command == "list" then
        local any = false;
        for _, label in pairs(addon:ListedItems()) do
            addon:Print(label);
            any = true;
        end
        if not any then addon:Print(L["LIST_EMPTY"]) end
        return;
    end

    local itemID = addon:ParseItem(rest);
    if itemID and (command == "always" or command == "never") then
        addon:ListItem(itemID, command);
    elseif itemID and command == "remove" then
        addon:UnlistItem(itemID);
    else
        addon:Print(L["SLASH_HELP"]);
    end
end
