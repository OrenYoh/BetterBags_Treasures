local addonName, root = ...;
local L = root.L;

---@class BetterBagsTreasures: AceModule
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName);

local categories = addon.categories;

-- The category an item goes in, for a kind of treasure and a mode
local function categoryName(mode, kind)
    if mode == "single" then
        return L["CATEGORY_SINGLE"];
    elseif mode == "split" then
        return string.format(L["CATEGORY_KIND"], addon.KIND_NAMES[kind]);
    end
    return nil;
end

-- The categories a mode uses
local function categoriesOf(mode)
    local names = {};
    if mode == "single" then
        names[1] = categoryName(mode);
    elseif mode == "split" then
        for _, kind in ipairs(addon.KINDS) do
            names[#names + 1] = categoryName(mode, kind);
        end
        names[#names + 1] = categoryName(mode, "listed");
    end
    return names;
end

-- Makes the categories a mode uses, so the player can find them in BetterBags' settings (which
-- bags show them, their order). One already made keeps what the player chose for it.
local function createCategories(mode)
    for _, name in ipairs(categoriesOf(mode)) do
        if not categories:GetCategoryByName(name) then
            categories:CreateCategory(addon:NewContext("CreateCategory"), {
                name = name,
                save = true,
                itemList = {},
            });
        end
    end
end

-- Deletes the categories of a mode no longer used
local function deleteCategories(mode)
    for _, name in ipairs(categoriesOf(mode)) do
        if categories:GetCategoryByName(name) then
            categories:DeleteCategory(addon:NewContext("DeleteCategory"), name);
        end
    end
end

-- BetterBags asks once per item and keeps the answer, until addon:Refresh(true) has it ask again.
categories:RegisterCategoryFunction("BetterBagsTreasures", function(data)
    local mode = addon.db.categoryMode;
    if mode ~= "single" and mode ~= "split" then
        return nil;
    end

    local treasure = addon:TreasureOf(data);
    return treasure and categoryName(mode, treasure.kind) or nil;
end);

-- Switches how treasures are grouped
function addon:SetCategoryMode(mode)
    local old = self.db.categoryMode;
    if old == mode then return end
    self.db.categoryMode = mode;
    deleteCategories(old);
    createCategories(mode);
    self:Refresh(true);
end

addon:OnLoaded(function()
    createCategories(addon.db.categoryMode);
end);
