local addonName, root = ...;
local L = root.L;

---@class BetterBagsTreasures: AceModule
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName);

-- Plain AceConfig options: BetterBags builds the plugin's settings page from them, and reads names,
-- choices and hidden states again after every change.

local selectedListed; -- the item chosen in the list, for Remove

local function kindValues()
    local values, order = {}, {};
    for _, kind in ipairs(addon.KINDS) do
        if addon:KindAvailable(kind) then
            values[kind] = addon.KIND_NAMES[kind];
            order[#order + 1] = kind;
        end
    end
    return values, order;
end

local kindNames, kindOrder = kindValues();

-- Adds the item in a box to a list, or says what is wrong
local function addFromInput(list)
    return {
        validate = function(_, value)
            if value == nil or value == "" or addon:ParseItem(value) then return true end
            return L["OPTIONS_INVALID_ITEM"];
        end,
        get = function() return "" end,
        set = function(_, value)
            local itemID = addon:ParseItem(value);
            if itemID then addon:ListItem(itemID, list) end
        end,
    };
end

local always = addFromInput("always");
local never = addFromInput("never");

addon.options = {
    description = {
        type = "description",
        order = 1,
        name = L["OPTIONS_DESC"],
    },

    categoriesHeader = { type = "header", order = 10, name = L["OPTIONS_CATEGORIES"] },
    categoryMode = {
        type = "select",
        order = 11,
        width = "full",
        name = L["OPTIONS_CATEGORY_MODE"],
        desc = L["OPTIONS_CATEGORY_MODE_DESC"],
        values = {
            off = L["OPTIONS_CATEGORY_OFF"],
            single = L["OPTIONS_CATEGORY_SINGLE"],
            split = L["OPTIONS_CATEGORY_SPLIT"],
        },
        sorting = { "single", "split", "off" },
        get = function() return addon.db.categoryMode end,
        set = function(_, value) addon:SetCategoryMode(value) end,
    },

    kindsHeader = { type = "header", order = 20, name = L["OPTIONS_KINDS"] },
    kindsDesc = { type = "description", order = 21, name = L["OPTIONS_KINDS_DESC"] },
    kinds = {
        type = "multiselect",
        order = 22,
        name = L["OPTIONS_KIND"],
        values = kindNames,
        sorting = kindOrder,
        get = function(_, kind) return addon.db.kinds[kind] end,
        set = function(_, kind, value)
            addon.db.kinds[kind] = value and true or false;
            addon:Refresh(true);
        end,
    },
    uncollectedOnly = {
        type = "toggle",
        order = 23,
        width = "full",
        name = L["OPTIONS_UNCOLLECTED"],
        desc = L["OPTIONS_UNCOLLECTED_DESC"],
        get = function() return addon.db.uncollectedOnly end,
        set = function(_, value)
            addon.db.uncollectedOnly = value;
            addon:Refresh(true);
        end,
    },

    highlightHeader = { type = "header", order = 30, name = L["OPTIONS_HIGHLIGHT"] },
    style = {
        type = "select",
        order = 31,
        name = L["OPTIONS_STYLE"],
        desc = L["OPTIONS_STYLE_DESC"],
        values = {
            none = L["OPTIONS_STYLE_NONE"],
            glow = L["OPTIONS_STYLE_GLOW"],
            badge = L["OPTIONS_STYLE_BADGE"],
            both = L["OPTIONS_STYLE_BOTH"],
        },
        sorting = { "glow", "badge", "both", "none" },
        get = function() return addon.db.style end,
        set = function(_, value)
            addon.db.style = value;
            -- Buttons without a highlight get theirs on a redraw
            addon:Refresh(true);
        end,
    },
    color = {
        type = "color",
        order = 32,
        name = L["OPTIONS_COLOR"],
        hidden = function() return addon.db.style == "none" or addon.db.style == "badge" end,
        get = function()
            local c = addon.db.color;
            return c.r, c.g, c.b;
        end,
        set = function(_, r, g, b)
            addon.db.color = { r = r, g = g, b = b };
            addon:RefreshHighlights();
        end,
    },
    corner = {
        type = "select",
        order = 33,
        name = L["OPTIONS_CORNER"],
        hidden = function() return addon.db.style ~= "badge" and addon.db.style ~= "both" end,
        values = {
            TOPLEFT = L["OPTIONS_CORNER_TOPLEFT"],
            TOPRIGHT = L["OPTIONS_CORNER_TOPRIGHT"],
            BOTTOMLEFT = L["OPTIONS_CORNER_BOTTOMLEFT"],
        },
        sorting = { "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT" },
        get = function() return addon.db.corner end,
        set = function(_, value)
            addon.db.corner = value;
            addon:RefreshHighlights();
        end,
    },
    pulse = {
        type = "toggle",
        order = 34,
        name = L["OPTIONS_PULSE"],
        desc = L["OPTIONS_PULSE_DESC"],
        hidden = function() return addon.db.style == "none" end,
        get = function() return addon.db.pulse end,
        set = function(_, value)
            addon.db.pulse = value;
            addon:RefreshHighlights();
        end,
    },
    greyOut = {
        type = "toggle",
        order = 35,
        width = "full",
        name = L["OPTIONS_GREY"],
        desc = L["OPTIONS_GREY_DESC"],
        hidden = function() return addon.db.style == "none" end,
        get = function() return addon.db.greyOut end,
        set = function(_, value)
            addon.db.greyOut = value;
            addon:RefreshHighlights();
        end,
    },

    listsHeader = { type = "header", order = 50, name = L["OPTIONS_LISTS"] },
    listsDesc = { type = "description", order = 51, name = L["OPTIONS_LISTS_DESC"] },
    alwaysAdd = {
        type = "input",
        order = 52,
        name = L["OPTIONS_ALWAYS_ADD"],
        validate = always.validate,
        get = always.get,
        set = always.set,
    },
    neverAdd = {
        type = "input",
        order = 53,
        name = L["OPTIONS_NEVER_ADD"],
        validate = never.validate,
        get = never.get,
        set = never.set,
    },
    listed = {
        type = "select",
        order = 54,
        width = "full",
        name = L["OPTIONS_LISTED"],
        hidden = function() return next(addon.db.always) == nil and next(addon.db.never) == nil end,
        values = function() return addon:ListedItems() end,
        get = function()
            if selectedListed and not (addon.db.always[selectedListed] or addon.db.never[selectedListed]) then
                selectedListed = nil;
            end
            return selectedListed;
        end,
        set = function(_, value) selectedListed = value end,
    },
    remove = {
        type = "execute",
        order = 55,
        name = L["OPTIONS_REMOVE"],
        hidden = function() return next(addon.db.always) == nil and next(addon.db.never) == nil end,
        disabled = function() return selectedListed == nil end,
        func = function()
            if selectedListed then
                addon:UnlistItem(selectedListed);
                selectedListed = nil;
            end
        end,
    },
};

addon:OnLoaded(function()
    addon.config:AddPluginConfig("BetterBags - " .. L["TITLE"], addon.options);
end);

-- A collection grew: what was a treasure may not be one any more
local function collectionChanged()
    if addon.db.uncollectedOnly then
        addon:Debounce("collection", 1, function() addon:Refresh(true) end);
    end
end

for _, event in ipairs({ "NEW_TOY_ADDED", "NEW_MOUNT_ADDED", "NEW_PET_ADDED", "TRANSMOG_COLLECTION_UPDATED", "NEW_RECIPE_LEARNED" }) do
    addon:OnGameEvent(event, collectionChanged);
end
