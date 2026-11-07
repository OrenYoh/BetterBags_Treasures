local addonName, root = ...;

---@class BetterBagsTreasures: AceModule
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName);

-- Detection uses the game's data (item classes, the collections' APIs, the container's own flags)
-- and, where only the tooltip says it, the game's own strings for those lines, so it works in every
-- language. Nothing is matched against English text.

local RECIPE_CLASS = Enum and Enum.ItemClass and Enum.ItemClass.Recipe or 9;

-- Tooltip lines, from the client's GlobalStrings. The two last ones exist on retail and WoW:
-- Forever only, so they are left out where the client has none.
local OPENABLE_TEXT = ITEM_OPENABLE; -- "<Right Click to Open>"
local LOCKED_TEXT = LOCKED; -- "Locked"
local KNOWN_TEXT = ITEM_SPELL_KNOWN; -- "Already known"
local APPEARANCE_KNOWN_TEXT = TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN; -- "You've collected this appearance"
local TOY_TEXT = ITEM_TOY_ONUSE; -- "Use: Adds this toy to your Toy Box."
local COSMETIC_LEARN_TEXT = ITEM_COSMETIC_LEARN; -- "Use: Add this appearance to your ... collection."
-- "Use: Create a soulbound item appropriate for your loot specialization (%s).", up to its "(%s)"
local LOOT_SPEC_TEXT = ITEM_CREATE_LOOT_SPEC_ITEM and string.match(ITEM_CREATE_LOOT_SPEC_ITEM, "^(.-)%s*%(%%s%)");

-- A hidden tooltip to read item lines from
local tooltipName = "BetterBagsTreasuresScanTooltip";
local tooltip = CreateFrame("GameTooltip", tooltipName, nil, "GameTooltipTemplate");
tooltip:SetOwner(UIParent, "ANCHOR_NONE");

-- The left lines of an item's tooltip, from its slot when it has one (that tooltip says whether a
-- lockbox is still locked), else from its link. nil when the game had nothing to show yet.
local function readTooltip(bag, slot, link)
    tooltip:SetOwner(UIParent, "ANCHOR_NONE");
    tooltip:ClearLines();
    if bag and slot then
        tooltip:SetBagItem(bag, slot);
    elseif link then
        tooltip:SetHyperlink(link);
    else
        return nil;
    end

    local count = tooltip:NumLines();
    if count < 2 then
        tooltip:Hide();
        return nil;
    end

    local lines = {};
    for i = 1, count do
        local line = _G[tooltipName .. "TextLeft" .. i];
        local text = line and line:GetText();
        if text then
            lines[#lines + 1] = text;
        end
    end
    tooltip:Hide();
    return lines;
end

local function hasLine(lines, text)
    if not lines or not text then return false end
    for _, line in ipairs(lines) do
        if line == text then return true end
    end
    return false;
end

local function hasLineStarting(lines, text)
    if not lines or not text or text == "" then return false end
    for _, line in ipairs(lines) do
        if string.sub(line, 1, #text) == text then return true end
    end
    return false;
end

-- What an item is never changes, so it is kept by item ID: its kind (false for none) and, for mounts
-- and pets, what the collection knows it by. Whether it is collected, locked or usable is read each
-- time: those change.
local kindByItem = {};
local mountByItem = {};
local speciesByItem = {};

-- The kind of an item from what never changes about it, or nil when the game hasn't loaded its data
-- yet (it is asked again next time).
local function staticKind(itemID, classID, bag, slot, link)
    if C_ToyBox and C_ToyBox.GetToyInfo and C_ToyBox.GetToyInfo(itemID) then
        return "toy";
    end

    if C_MountJournal and C_MountJournal.GetMountFromItem then
        local mountID = C_MountJournal.GetMountFromItem(itemID);
        if mountID then
            mountByItem[itemID] = mountID;
            return "mount";
        end
    end

    if C_PetJournal and C_PetJournal.GetPetInfoByItemID then
        local speciesID = select(13, C_PetJournal.GetPetInfoByItemID(itemID));
        if speciesID then
            speciesByItem[itemID] = speciesID;
            return "pet";
        end
    end

    if C_Item and C_Item.GetItemLearnTransmogSet and C_Item.GetItemLearnTransmogSet(itemID) then
        return "appearance";
    end

    if classID == RECIPE_CLASS then
        return "recipe";
    end

    local lines = readTooltip(bag, slot, link);
    if not lines then
        return nil;
    end

    if hasLine(lines, OPENABLE_TEXT) or hasLineStarting(lines, LOOT_SPEC_TEXT) then
        return "container";
    elseif hasLine(lines, LOCKED_TEXT) then
        return "lockbox";
    elseif hasLine(lines, TOY_TEXT) then
        return "toy";
    elseif hasLineStarting(lines, COSMETIC_LEARN_TEXT) then
        return "appearance";
    end

    return false;
end

-- Whether the item in a bag slot is a lockbox still locked
function addon:IsSlotLocked(bag, slot)
    return hasLine(readTooltip(bag, slot), LOCKED_TEXT);
end

-- Whether a collectible item is already collected
local function isCollected(kind, itemID, bag, slot, link)
    if kind == "toy" then
        return PlayerHasToy ~= nil and PlayerHasToy(itemID) and true or false;
    elseif kind == "mount" then
        local mountID = mountByItem[itemID];
        if mountID and C_MountJournal.GetMountInfoByID then
            return select(11, C_MountJournal.GetMountInfoByID(mountID)) and true or false;
        end
    elseif kind == "pet" then
        local speciesID = speciesByItem[itemID];
        if speciesID and C_PetJournal.GetNumCollectedInfo then
            local collected = C_PetJournal.GetNumCollectedInfo(speciesID);
            return (collected or 0) > 0;
        end
    elseif kind == "appearance" or kind == "recipe" then
        local lines = readTooltip(bag, slot, link);
        return hasLine(lines, KNOWN_TEXT) or hasLine(lines, APPEARANCE_KNOWN_TEXT);
    end
    return false;
end

---@class TreasureInfo
---@field kind string What kind of treasure it is (addon.KINDS, or "listed")
---@field usable boolean False for a lockbox still locked or a treasure above the player's level

-- Treasure returns what kind of treasure an item is, or nil when it isn't one (by the settings).
---@param itemID number
---@param classID number|nil
---@param minLevel number|nil
---@param bag number|nil
---@param slot number|nil
---@param link string|nil
---@return TreasureInfo|nil
function addon:Treasure(itemID, classID, minLevel, bag, slot, link)
    if not itemID then return nil end
    local db = self.db;

    if db.never[itemID] then
        return nil;
    end

    local usable = not (minLevel and minLevel > (UnitLevel("player") or 0));

    if db.always[itemID] then
        return { kind = "listed", usable = usable };
    end

    -- A container the game says has loot in it. A lockbox has loot too: its slot's tooltip says
    -- whether it is still locked (read each time: few items have loot, and picking one changes it).
    local containerInfo = bag and slot and C_Container.GetContainerItemInfo(bag, slot);
    local kind;
    if containerInfo and containerInfo.hasLoot then
        kind = addon:IsSlotLocked(bag, slot) and "lockbox" or "container";
    else
        kind = kindByItem[itemID];
        if kind == nil then
            kind = staticKind(itemID, classID, bag, slot, link);
            if kind ~= nil then
                kindByItem[itemID] = kind;
            end
        end
    end

    if not kind or not db.kinds[kind] then
        return nil;
    end

    if db.uncollectedOnly and isCollected(kind, itemID, bag, slot, link) then
        return nil;
    end

    if kind == "lockbox" then
        usable = false;
    end

    return { kind = kind, usable = usable };
end

-- The treasure an item of BetterBags' is (its ItemData)
---@param data table
---@return TreasureInfo|nil
function addon:TreasureOf(data)
    local info = data and data.itemInfo;
    if not info or data.isItemEmpty or not info.itemID or info.itemID == 0 then
        return nil;
    end
    return self:Treasure(info.itemID, info.classID, info.itemMinLevel, data.bagid, data.slotid, info.itemLink);
end

-- Which kinds this client can have: a client without a toy box has no toys, and so on
function addon:KindAvailable(kind)
    if kind == "toy" then
        return C_ToyBox ~= nil and C_ToyBox.GetToyInfo ~= nil;
    elseif kind == "mount" then
        return C_MountJournal ~= nil and C_MountJournal.GetMountFromItem ~= nil;
    elseif kind == "pet" then
        return C_PetJournal ~= nil and C_PetJournal.GetPetInfoByItemID ~= nil;
    elseif kind == "appearance" then
        return (C_Item ~= nil and C_Item.GetItemLearnTransmogSet ~= nil) or COSMETIC_LEARN_TEXT ~= nil;
    end
    return true;
end
