local addonName, root = ...;

---@class BetterBagsTreasures: AceModule
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName);

local events = addon.events;
local items = addon.items;

-- The highlight drawn over an item button: a glow around it and a badge in a corner, still or
-- pulsing. It is a frame of ours on BetterBags' button (its "decoration", the button themes and
-- Masque draw), above the button's own art, and is never part of the button's secure click.

-- Blizzard art present on every client
local GLOW_TEXTURE = [[Interface\Buttons\UI-ActionButton-Border]];
local BADGE_TEXTURE = [[Interface\Icons\INV_Box_01]];
-- UI-ActionButton-Border's square takes 37 of its 64 pixels
local GLOW_SCALE = 64 / 37;
local BADGE_SCALE = 0.42;
local GREY = { r = 0.6, g = 0.6, b = 0.6 };

local overlays = setmetatable({}, { __mode = "k" }); -- [decoration] = overlay
local shownOn = setmetatable({}, { __mode = "k" }); -- [decoration] = BetterBags' item

-- Sizes the glow and badge to the button, now and whenever it changes size (BetterBags Next's icon
-- scale, a layout made before the button had a size)
local function fit(overlay, width)
    if not width or width <= 0 then return end
    overlay.glow:SetSize(width * GLOW_SCALE, width * GLOW_SCALE);
    local size = math.floor(width * BADGE_SCALE + 0.5);
    overlay.badge:SetSize(size, size);
end

local function createOverlay(decoration)
    local overlay = CreateFrame("Frame", nil, decoration);
    overlay:SetAllPoints(decoration);
    overlay:SetFrameLevel(decoration:GetFrameLevel() + 5);
    overlay:EnableMouse(false);

    overlay.glow = overlay:CreateTexture(nil, "OVERLAY");
    overlay.glow:SetTexture(GLOW_TEXTURE);
    overlay.glow:SetBlendMode("ADD");
    overlay.glow:SetPoint("CENTER");

    overlay.badge = overlay:CreateTexture(nil, "OVERLAY", nil, 1);
    overlay.badge:SetTexture(BADGE_TEXTURE);
    overlay.badge:SetTexCoord(0.08, 0.92, 0.08, 0.92);

    local pulse = overlay:CreateAnimationGroup();
    pulse:SetLooping("BOUNCE");
    local fade = pulse:CreateAnimation("Alpha");
    fade:SetFromAlpha(1);
    fade:SetToAlpha(0.35);
    fade:SetDuration(0.9);
    if fade.SetSmoothing then fade:SetSmoothing("IN_OUT") end
    overlay.pulse = pulse;

    overlay:SetScript("OnSizeChanged", function(self, width) fit(self, width) end);

    overlay:Hide();
    overlays[decoration] = overlay;
    return overlay;
end

local function hide(decoration)
    local overlay = overlays[decoration];
    if overlay then
        overlay.pulse:Stop();
        overlay:Hide();
    end
    shownOn[decoration] = nil;
end

-- Draws an overlay for a treasure, by the settings
local function draw(overlay, decoration, treasure)
    local db = addon.db;

    local grey = db.greyOut and not treasure.usable;
    local color = grey and GREY or db.color;
    local showGlow = db.style == "glow" or db.style == "both";
    local showBadge = db.style == "badge" or db.style == "both";

    fit(overlay, decoration:GetWidth());
    overlay.glow:SetVertexColor(color.r, color.g, color.b, 1);
    overlay.glow:SetShown(showGlow);

    overlay.badge:ClearAllPoints();
    overlay.badge:SetPoint(db.corner, overlay, db.corner, 0, 0);
    overlay.badge:SetDesaturated(grey);
    overlay.badge:SetShown(showBadge);

    overlay:Show();
    if db.pulse then
        if not overlay.pulse:IsPlaying() then overlay.pulse:Play() end
    else
        overlay.pulse:Stop();
        overlay:SetAlpha(1);
    end
end

-- Draws or hides the highlight of one of BetterBags' item buttons
local function update(item, decoration)
    if not decoration then return end
    local data = not item.isFreeSlot and item.slotkey and items:GetItemDataFromSlotKey(item.slotkey);
    local treasure = data and addon.db.style ~= "none" and addon:TreasureOf(data);
    if not treasure then
        hide(decoration);
        return;
    end

    draw(overlays[decoration] or createOverlay(decoration), decoration, treasure);
    shownOn[decoration] = item;
end

-- Every draw of an item button (and of a free slot) ends with item/Updated; a button let go of
-- sends item/Clearing first.
events:RegisterMessage("item/Updated", function(_, item, decoration)
    update(item, decoration);
end);

events:RegisterMessage("item/Clearing", function(_, _, decoration)
    if decoration then hide(decoration) end
end);

-- A level gained can make a treasure usable (greyed out until then)
addon:OnGameEvent("PLAYER_LEVEL_UP", function()
    addon:RefreshHighlights();
end);

-- Draws every highlight shown again, after a setting or a collection changed. Buttons with no
-- highlight yet get theirs on their next draw (and addon:Refresh(true) redraws every bag).
function addon:RefreshHighlights()
    for decoration, item in pairs(shownOn) do
        update(item, decoration);
    end
end
