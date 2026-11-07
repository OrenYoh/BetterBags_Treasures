local L, _, ns = {}, ...;

ns.L = setmetatable(L, {__index = function(t, k)
    local v = tostring(k);
    rawset(t, k, v);
    return v;
end});

L["TITLE"] = "Treasures";

-- Kinds of treasure (also the category names when each kind has its own)
L["KIND_CONTAINER"] = "Containers";
L["KIND_LOCKBOX"] = "Lockboxes";
L["KIND_TOY"] = "Toys";
L["KIND_MOUNT"] = "Mounts";
L["KIND_PET"] = "Pets";
L["KIND_APPEARANCE"] = "Appearances";
L["KIND_RECIPE"] = "Recipes";
L["KIND_LISTED"] = "Your Items";

L["CATEGORY_SINGLE"] = "Treasures";
L["CATEGORY_KIND"] = "Treasures: %s";

-- Options
L["OPTIONS_DESC"] = "Finds the treasures in your bags: items to open, and things to learn or collect. Detection uses the game's own data, so it works in every language.";
L["OPTIONS_CATEGORIES"] = "Categories";
L["OPTIONS_CATEGORY_MODE"] = "Group treasures";
L["OPTIONS_CATEGORY_MODE_DESC"] = "Put every treasure in one Treasures category, give each kind its own category, or leave them in their usual categories (they are still highlighted).";
L["OPTIONS_CATEGORY_OFF"] = "Don't group them";
L["OPTIONS_CATEGORY_SINGLE"] = "One Treasures category";
L["OPTIONS_CATEGORY_SPLIT"] = "A category for each kind";
L["OPTIONS_KINDS"] = "Treasures to find";
L["OPTIONS_KINDS_DESC"] = "Which kinds of items count as treasures, for the categories, the highlight and the Open Next key.";
L["OPTIONS_KIND"] = "Find";
L["OPTIONS_UNCOLLECTED"] = "Only what I haven't collected yet";
L["OPTIONS_UNCOLLECTED_DESC"] = "Toys, mounts, pets, appearances and recipes you already know are not treasures, so duplicates show up where you can sell or trade them.";
L["OPTIONS_HIGHLIGHT"] = "Highlight";
L["OPTIONS_STYLE"] = "Highlight style";
L["OPTIONS_STYLE_DESC"] = "How treasures are marked on their item buttons.";
L["OPTIONS_STYLE_NONE"] = "None";
L["OPTIONS_STYLE_GLOW"] = "Glow";
L["OPTIONS_STYLE_BADGE"] = "Corner badge";
L["OPTIONS_STYLE_BOTH"] = "Glow and badge";
L["OPTIONS_COLOR"] = "Glow color";
L["OPTIONS_CORNER"] = "Badge corner";
L["OPTIONS_CORNER_TOPLEFT"] = "Top left";
L["OPTIONS_CORNER_TOPRIGHT"] = "Top right";
L["OPTIONS_CORNER_BOTTOMLEFT"] = "Bottom left";
L["OPTIONS_PULSE"] = "Pulse";
L["OPTIONS_PULSE_DESC"] = "The highlight fades in and out slowly. Off, it stays still.";
L["OPTIONS_GREY"] = "Grey out what I can't open or use yet";
L["OPTIONS_GREY_DESC"] = "Lockboxes that are still locked, and treasures above your level, are highlighted in grey.";
L["OPTIONS_OPEN"] = "Open Next";
L["OPTIONS_OPEN_DESC"] = "Opens the next container in your bags, one per press. Bind a key to it in Key Bindings, under AddOns > BetterBags - Treasures, or put this line in a macro:\n\n|cffffd100/click BetterBagsTreasuresOpenButton|r\n\nThe game only lets an addon use an item from a key or a click, never by itself. In combat, it opens the container it had picked before the fight.";
L["OPTIONS_LISTS"] = "Your Items";
L["OPTIONS_LISTS_DESC"] = "Items you always want as treasures, or never. Type an item ID in a box, or in chat (Shift-click an item to put its link in): |cffffd100/treasures always <item>|r, |cffffd100/treasures never <item>|r, |cffffd100/treasures remove <item>|r.";
L["OPTIONS_ALWAYS_ADD"] = "Always a treasure";
L["OPTIONS_NEVER_ADD"] = "Never a treasure";
L["OPTIONS_LISTED"] = "Listed items";
L["OPTIONS_REMOVE"] = "Remove from the list";
L["OPTIONS_INVALID_ITEM"] = "That isn't an item ID or an item link.";

L["LIST_ALWAYS"] = "Always";
L["LIST_NEVER"] = "Never";
L["LIST_ADDED_ALWAYS"] = "%s is now always a treasure.";
L["LIST_ADDED_NEVER"] = "%s is now never a treasure.";
L["LIST_REMOVED"] = "%s was removed from your list.";
L["LIST_NOT_LISTED"] = "%s isn't on your list.";
L["SLASH_HELP"] = "Commands: |cffffd100/treasures always <item>|r, |cffffd100/treasures never <item>|r, |cffffd100/treasures remove <item>|r, |cffffd100/treasures list|r.";
L["LIST_EMPTY"] = "Your list is empty.";

L["OPEN_NOTHING"] = "No container to open.";

L["BINDING_OPEN_NEXT"] = "Open Next Container";
