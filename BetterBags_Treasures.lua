local addonName, root = ...;
local L = root.L;

---@class BetterBagsTreasures: AceModule
local addon = LibStub("AceAddon-3.0"):NewAddon(root, addonName);

--- BetterBags dependencies
-----------------------------
---@class BetterBags: AceAddon
local BetterBags = LibStub("AceAddon-3.0"):GetAddon("BetterBags");
assert(BetterBags, addonName .. " requires BetterBags");

addon.BetterBags = BetterBags;
addon.categories = BetterBags:GetModule("Categories");
addon.config = BetterBags:GetModule("Config");
addon.context = BetterBags:GetModule("Context");
addon.events = BetterBags:GetModule("Events");
addon.items = BetterBags:GetModule("Items");
-----------------------------

--- Game versions
-----------------------------
-- WoW: Forever defines WOW_PROJECT_CAMELOT (and sets WOW_PROJECT_ID to it) only on its own client,
-- so the "~= nil" check keeps two missing constants from matching.
addon.isForever = _G.WOW_PROJECT_CAMELOT ~= nil and _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CAMELOT;
-----------------------------

--- Kinds of treasure, in the order the options list them
-----------------------------
addon.KINDS = { "container", "lockbox", "toy", "mount", "pet", "appearance", "recipe" };
addon.KIND_NAMES = {
    container = L["KIND_CONTAINER"],
    lockbox = L["KIND_LOCKBOX"],
    toy = L["KIND_TOY"],
    mount = L["KIND_MOUNT"],
    pet = L["KIND_PET"],
    appearance = L["KIND_APPEARANCE"],
    recipe = L["KIND_RECIPE"],
    listed = L["KIND_LISTED"],
};
-----------------------------

--- Saved settings
-----------------------------
local DEFAULTS = {
    categoryMode = "single", -- "off", "single" or "split"
    kinds = {
        container = true,
        lockbox = true,
        toy = true,
        mount = true,
        pet = true,
        appearance = true,
        recipe = false,
    },
    uncollectedOnly = false,
    style = "glow", -- "none", "glow", "badge" or "both"
    color = { r = 1, g = 0.82, b = 0 },
    corner = "TOPLEFT",
    pulse = false,
    greyOut = true,
    always = {}, -- [itemID] = true
    never = {}, -- [itemID] = true
};

-- Fills in what a saved table is missing from its defaults, one level of tables deep
local function merge(saved, defaults)
    for key, value in pairs(defaults) do
        if saved[key] == nil then
            if type(value) == "table" then
                local copy = {};
                for k, v in pairs(value) do copy[k] = v end
                saved[key] = copy;
            else
                saved[key] = value;
            end
        elseif type(value) == "table" and type(saved[key]) == "table" then
            for k, v in pairs(value) do
                if saved[key][k] == nil then saved[key][k] = v end
            end
        end
    end
end

-- The defaults until the saved settings are loaded, which happens after every file of the addon
-- has run, right before ADDON_LOADED (addon:OnLoaded).
addon.db = {};
merge(addon.db, DEFAULTS);

local loadedHandlers = {};

-- Runs func once the saved settings are loaded
function addon:OnLoaded(func)
    table.insert(loadedHandlers, func);
end
-----------------------------

--- Helpers
-----------------------------
function addon:NewContext(name)
    return self.context:New("BetterBagsTreasures_" .. name);
end

function addon:Print(message)
    print("|cffffd100" .. L["TITLE"] .. "|r " .. message);
end

-- Game events, on a frame of our own. An event a client doesn't have is skipped: registering one
-- raises an error on the newer clients.
local eventFrame = CreateFrame("Frame");
local eventHandlers = {};

local function isEventValid(event)
    if C_EventUtils and C_EventUtils.IsEventValid then
        return C_EventUtils.IsEventValid(event);
    end
    return pcall(eventFrame.RegisterEvent, eventFrame, event) and true or false;
end

function addon:OnGameEvent(event, handler)
    if not eventHandlers[event] then
        if not isEventValid(event) then
            return false;
        end
        eventHandlers[event] = {};
        eventFrame:RegisterEvent(event);
    end
    table.insert(eventHandlers[event], handler);
    return true;
end

eventFrame:RegisterEvent("ADDON_LOADED");

local function loaded()
    if type(BetterBagsTreasuresDB) ~= "table" then BetterBagsTreasuresDB = {} end
    merge(BetterBagsTreasuresDB, DEFAULTS);
    addon.db = BetterBagsTreasuresDB;
    for _, func in ipairs(loadedHandlers) do
        func();
    end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... == addonName then
            eventFrame:UnregisterEvent("ADDON_LOADED");
            loaded();
        end
        if not eventHandlers[event] then return end
    end
    for _, handler in ipairs(eventHandlers[event]) do
        handler(event, ...);
    end
end);

-- Runs func once, delay seconds after the last call
function addon:Debounce(key, delay, func)
    self.timers = self.timers or {};
    if self.timers[key] then
        self.timers[key]:Cancel();
    end
    self.timers[key] = C_Timer.NewTimer(delay, function()
        self.timers[key] = nil;
        func();
    end);
end

-- Something treasures depend on changed (a setting, the collections, the lists): categories are
-- worked out again and every highlight drawn again.
function addon:Refresh(categoriesToo)
    if categoriesToo then
        self:Debounce("categories", 0.2, function()
            self.categories:ReprocessAllItems(self:NewContext("Refresh"));
        end);
    end
    if self.RefreshHighlights then
        self:RefreshHighlights();
    end
end
-----------------------------
