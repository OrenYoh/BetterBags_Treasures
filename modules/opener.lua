local addonName, root = ...;
local L = root.L;

---@class BetterBagsTreasures: AceModule
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName);

-- Open Next: a secure action button using the next container in the bags. Addons can only use an
-- item through a secure button the player presses (a key bound to it, a /click macro), and its
-- attributes can't change in combat, so the target is picked out of combat, after every bag change.
--
-- It fires once per press whatever the client: only key and button releases are registered, and
-- "useOnKeyDown" is off, so Blizzard's SecureActionButton_OnClick (which acts on the press or the
-- release, by that attribute) acts on the release.

local button = CreateFrame("Button", "BetterBagsTreasuresOpenButton", UIParent, "SecureActionButtonTemplate");
button:RegisterForClicks("AnyUp");
button:SetAttribute("useOnKeyDown", false);
button:SetAttribute("type", "item");
button:SetSize(1, 1);
button:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10, 10);
button:SetAlpha(0);
button:EnableMouse(false);
button:Show();

local pending = false;

-- The bags carried (the backpack, its bags and the reagent bag where there is one)
local function bagIDs()
    local last = NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4;
    local ids = {};
    for bag = 0, last do
        ids[#ids + 1] = bag;
    end
    return ids;
end

-- The first container that can be opened now: one with loot in it (a lockbox only once it is
-- picked), at the player's level, of a kind the player looks for, not on the Never list.
local function nextContainer()
    if not addon.db.kinds.container then return nil end
    for _, bag in ipairs(bagIDs()) do
        local slots = C_Container.GetContainerNumSlots(bag) or 0;
        for slot = 1, slots do
            local info = C_Container.GetContainerItemInfo(bag, slot);
            -- isLocked is a slot being moved; a lockbox still locked says so in its tooltip
            if info and info.hasLoot and not info.isLocked and not addon.db.never[info.itemID]
                and not addon:IsSlotLocked(bag, slot) then
                local minLevel = select(5, C_Item.GetItemInfo(info.itemID));
                if not (minLevel and minLevel > (UnitLevel("player") or 0)) then
                    return bag, slot;
                end
            end
        end
    end
    return nil;
end

-- Points the button at the next container, or at nothing
function addon:UpdateOpener()
    if InCombatLockdown() then
        pending = true;
        return;
    end
    pending = false;
    local bag, slot = nextContainer();
    button:SetAttribute("item", bag and (bag .. " " .. slot) or nil);
end

-- Says so when there is nothing to open (this runs before the secure action, and changes nothing)
button:SetScript("PreClick", function(self)
    if not self:GetAttribute("item") then
        addon:Print(L["OPEN_NOTHING"]);
    end
end);

addon:OnGameEvent("BAG_UPDATE_DELAYED", function()
    addon:Debounce("opener", 0.1, function() addon:UpdateOpener() end);
end);

addon:OnGameEvent("PLAYER_REGEN_ENABLED", function()
    if pending then addon:UpdateOpener() end
end);

addon:OnGameEvent("PLAYER_LEVEL_UP", function()
    addon:Refresh(false);
end);

addon:OnGameEvent("PLAYER_ENTERING_WORLD", function()
    addon:UpdateOpener();
end);
