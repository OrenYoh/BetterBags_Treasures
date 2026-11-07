-- BetterBags_Treasures on the whole of BetterBags (its spec/helpers/whole_addon.lua). Run from a BetterBags checkout
-- with its Lua 5.1 busted, TREASURES_DIR pointing at this addon (TREASURES_FOREVER=1 for the WoW: Forever client):
--   TREASURES_DIR=../BetterBags_Treasures ~/.local/lua51/bin/busted ../BetterBags_Treasures/spec/treasures_spec.lua
local WholeAddon = dofile("spec/helpers/whole_addon.lua")
-- This checkout's LibWindow has its $Revision$ unexpanded, which LibStub can't read: a nil minor is 1.
local newLibrary = LibStub.NewLibrary
LibStub.NewLibrary = function(self, major, minor)
  if minor == nil or not tostring(minor):match("%d") then minor = 1 end
  return newLibrary(self, major, minor)
end
local ADDON_DIR = os.getenv("TREASURES_DIR")
local TOC_FILES = {
  "i18n/enUS.lua", "i18n/frFR.lua", "BetterBags_Treasures.lua", "modules/detect.lua", "modules/categories.lua",
  "modules/highlight.lua", "modules/lists.lua", "modules/options.lua",
}

describe("BetterBags_Treasures", function()
  local handle, bb, ns, c, frames, tooltipLines, printed

  -- The client: bag slots, item info, collections and tooltips
  local function client()
    c = {
      slots = {},     -- ["bag_slot"] = { itemID =, hasLoot =, locked = (lockbox), lines = {...} }
      toys = { [1001] = true }, toysOwned = {},
      mounts = { [1002] = 55 }, mountsOwned = {},
      pets = { [1003] = 77 }, petsOwned = {},
      minLevel = {},
    }
    _G.C_ToyBox = { GetToyInfo = function(id) if c.toys[id] then return id, "Toy" end end }
    _G.PlayerHasToy = function(id) return c.toysOwned[id] == true end
    _G.C_MountJournal = {
      GetMountFromItem = function(id) return c.mounts[id] end,
      GetMountInfoByID = function(mountID)
        return "Mount", 1, 1, false, true, 0, false, false, nil, false, c.mountsOwned[mountID] == true, mountID
      end,
    }
    _G.C_PetJournal = {
      GetPetInfoByItemID = function(id)
        if c.pets[id] then return "Pet", 1, 1, 1, "", "", false, true, true, false, true, 1, c.pets[id] end
      end,
      GetNumCollectedInfo = function(species) return c.petsOwned[species] and 1 or 0, 3 end,
    }
    _G.C_Container.GetContainerItemInfo = function(bag, slot)
      local s = c.slots[bag .. "_" .. slot]
      if not s then return nil end
      return { itemID = s.itemID, hasLoot = s.hasLoot == true, isLocked = false, iconFileID = 1, stackCount = 1 }
    end
    _G.C_Container.GetContainerNumSlots = function(bag) return bag == 0 and 4 or 0 end
    _G.C_Item.GetItemInfo = function(id)
      return "Item " .. id, "|cffffffff|Hitem:" .. id .. "|h[Item " .. id .. "]|h|r", 1, 10, c.minLevel[id] or 1
    end
    _G.UnitLevel = function() return 20 end
    _G.ITEM_OPENABLE, _G.LOCKED, _G.ITEM_SPELL_KNOWN = "<Right Click to Open>", "Locked", "Already known"
    _G.TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN = "You've collected this appearance"
    _G.ITEM_TOY_ONUSE = "Use: Adds this toy to your Toy Box."
  end

  local function slot(bag, s, item) c.slots[bag .. "_" .. s] = item end

  -- Our frames, as they are made: the event frame and the scanning tooltip
  local function captureFrames()
    frames = {}
    local create = _G.CreateFrame
    _G.CreateFrame = function(kind, name, parent, template, ...)
      local f = create(kind, name, parent, template, ...)
      table.insert(frames, f)
      if kind == "GameTooltip" and name == "BetterBagsTreasuresScanTooltip" then
        local lines = {}
        function f:ClearLines() for i = #lines, 1, -1 do lines[i] = nil end end
        function f:SetBagItem(bag, s)
          local item = c.slots[bag .. "_" .. s]
          lines[1] = "Item"
          if item then for _, l in ipairs(item.lines or {}) do lines[#lines + 1] = l end end
          if item and item.locked then lines[#lines + 1] = "Locked" end
          if not item or (#lines < 2) then lines[2] = "Some text" end
        end
        function f:SetHyperlink() lines[1], lines[2] = "Item", "Some text" end
        function f:NumLines() return #lines end
        tooltipLines = lines
        for i = 1, 30 do
          _G[name .. "TextLeft" .. i] = { GetText = function() return lines[i] end }
        end
      end
      return f
    end
  end

  local function fire(event, ...)
    for _, f in ipairs(frames) do
      if f.IsEventRegistered and f:IsEventRegistered(event) or event == "ADDON_LOADED" then
        local script = f.GetScript and f:GetScript("OnEvent")
        if script then script(f, event, ...) end
      end
    end
  end

  local function data(bag, s, itemID, classID)
    return { bagid = bag, slotid = s, slotkey = bag .. "_" .. s,
      itemInfo = { itemID = itemID, classID = classID or 15, itemMinLevel = c.minLevel[itemID] or 1,
        itemLink = "item:" .. itemID } }
  end

  local function category(d)
    return bb:GetModule("Categories").categoryFunctions["BetterBagsTreasures"](d)
  end

  before_each(function()
    handle = WholeAddon.Load({ next = true, client = os.getenv("TREASURES_FOREVER") and "forever" or "retail" })
    handle:Start()
    assert.are.same({}, handle.errors, "starting BetterBags")
    bb = handle.addon
    client()
    captureFrames()
    printed = {}
    _G.print = function(...) table.insert(printed, table.concat({ ... }, " ")) end
    _G.BetterBagsTreasuresDB = nil
    ns = {}
    for _, file in ipairs(TOC_FILES) do
      local chunk = assert(loadfile(ADDON_DIR .. "/" .. file))
      chunk("BetterBags_Treasures", ns)
    end
    fire("ADDON_LOADED", "BetterBags_Treasures")
    assert.are.same({}, handle.errors, "loading BetterBags_Treasures")
  end)

  after_each(function()
    if handle then handle:Restore() end
    handle = nil
  end)

  it("saves its settings in the saved variable once it is loaded", function()
    assert.is_table(_G.BetterBagsTreasuresDB)
    assert.are.equal(_G.BetterBagsTreasuresDB, ns.db)
    assert.are.equal("single", ns.db.categoryMode)
  end)

  it("creates its category in BetterBags", function()
    assert.is_not_nil(bb:GetModule("Categories"):GetCategoryByName("Treasures"))
  end)

  it("puts a container with loot in Treasures, and leaves an ordinary item alone", function()
    slot(0, 1, { itemID = 2001, hasLoot = true })
    slot(0, 2, { itemID = 2002 })
    assert.are.equal("Treasures", category(data(0, 1, 2001)))
    assert.is_nil(category(data(0, 2, 2002)))
  end)

  it("finds a container from the game's <Right Click to Open> line", function()
    slot(0, 1, { itemID = 2003, lines = { "<Right Click to Open>" } })
    assert.are.equal("Treasures", category(data(0, 1, 2003)))
  end)

  it("gives each kind its own category, and deletes the single one", function()
    ns:SetCategoryMode("split")
    local cats = bb:GetModule("Categories")
    assert.is_nil(cats:GetCategoryByName("Treasures"))
    assert.is_not_nil(cats:GetCategoryByName("Treasures: Toys"))
    slot(0, 1, { itemID = 2004, hasLoot = true, locked = true })
    slot(0, 2, { itemID = 1001 })
    slot(0, 3, { itemID = 1002 })
    slot(0, 4, { itemID = 1003 })
    assert.are.equal("Treasures: Lockboxes", category(data(0, 1, 2004)))
    assert.are.equal("Treasures: Toys", category(data(0, 2, 1001)))
    assert.are.equal("Treasures: Mounts", category(data(0, 3, 1002)))
    assert.are.equal("Treasures: Pets", category(data(0, 4, 1003)))
    assert.are.same({}, handle.errors)
  end)

  it("puts nothing in a category when grouping is off", function()
    ns:SetCategoryMode("off")
    slot(0, 1, { itemID = 2001, hasLoot = true })
    assert.is_nil(category(data(0, 1, 2001)))
    assert.is_nil(bb:GetModule("Categories"):GetCategoryByName("Treasures"))
  end)

  it("leaves out what is already collected, unless asked not to", function()
    slot(0, 1, { itemID = 1001 })
    slot(0, 2, { itemID = 1002 })
    slot(0, 3, { itemID = 1003 })
    c.toysOwned[1001], c.mountsOwned[55], c.petsOwned[77] = true, true, true
    assert.is_nil(category(data(0, 1, 1001)))
    assert.is_nil(category(data(0, 2, 1002)))
    assert.is_nil(category(data(0, 3, 1003)))
    ns.db.uncollectedOnly = false
    assert.are.equal("Treasures", category(data(0, 1, 1001)))
    assert.are.equal("Treasures", category(data(0, 2, 1002)))
    assert.are.equal("Treasures", category(data(0, 3, 1003)))
  end)

  it("reads a recipe as known from the game's Already known line", function()
    ns.db.kinds.recipe = true
    slot(0, 1, { itemID = 3001 })
    slot(0, 2, { itemID = 3002, lines = { "Already known" } })
    assert.are.equal("Treasures", category(data(0, 1, 3001, 9)))
    assert.is_nil(category(data(0, 2, 3002, 9)))
  end)

  it("follows the kinds the player chose", function()
    ns.db.kinds.container = false
    slot(0, 1, { itemID = 2001, hasLoot = true })
    assert.is_nil(category(data(0, 1, 2001)))
  end)

  it("follows the player's lists", function()
    slot(0, 1, { itemID = 2001, hasLoot = true })
    slot(0, 2, { itemID = 2002 })
    _G.SlashCmdList.BETTERBAGSTREASURES("never 2001")
    _G.SlashCmdList.BETTERBAGSTREASURES("always |cffffffff|Hitem:2002::::|h[Item]|h|r")
    assert.is_nil(category(data(0, 1, 2001)))
    assert.are.equal("Treasures", category(data(0, 2, 2002)))
    ns:SetCategoryMode("split")
    assert.are.equal("Treasures: Your Items", category(data(0, 2, 2002)))
    _G.SlashCmdList.BETTERBAGSTREASURES("remove 2001")
    assert.are.equal("Treasures: Containers", category(data(0, 1, 2001)))
    _G.SlashCmdList.BETTERBAGSTREASURES("always 2001")
    assert.is_nil(ns.db.never[2001])
  end)

  describe("the highlight", function()
    local decoration, item, d

    before_each(function()
      decoration = CreateFrame("Button")
      decoration:SetSize(37, 37)
      d = data(0, 1, 2001)
      item = { slotkey = "0_1" }
      bb:GetModule("Items").GetItemDataFromSlotKey = function(_, key) if key == "0_1" then return d end end
    end)

    local function overlayOf()
      for _, f in ipairs(frames) do
        if f.glow and f:GetParent() == decoration then return f end
      end
    end

    local function draw()
      bb:GetModule("Events"):SendMessage(bb:GetModule("Context"):New("spec"), "item/Updated", item, decoration)
    end

    it("glows on a treasure, in the chosen color", function()
      slot(0, 1, { itemID = 2001, hasLoot = true })
      draw()
      local o = overlayOf()
      assert.is_not_nil(o)
      assert.is_true(o:IsShown())
      assert.is_true(o.glow:IsShown())
      assert.is_false(o.badge:IsShown())
      assert.are.same({}, handle.errors)
    end)

    it("follows the button's size", function()
      slot(0, 1, { itemID = 2001, hasLoot = true })
      draw()
      local o = overlayOf()
      assert.are.near(37 * 64 / 37, o.glow:GetWidth(), 0.01)
      o:GetScript("OnSizeChanged")(o, 50, 50)
      assert.are.near(50 * 64 / 37, o.glow:GetWidth(), 0.01)
    end)

    it("is hidden on an ordinary item, a free slot and a button let go of", function()
      slot(0, 1, { itemID = 2001, hasLoot = true })
      draw()
      local o = overlayOf()
      slot(0, 1, { itemID = 2002 }); d = data(0, 1, 2002)
      draw()
      assert.is_false(o:IsShown())
      slot(0, 1, { itemID = 2001, hasLoot = true }); d = data(0, 1, 2001)
      draw()
      assert.is_true(o:IsShown())
      item.isFreeSlot = true
      draw()
      assert.is_false(o:IsShown())
      item.isFreeSlot = nil
      draw()
      bb:GetModule("Events"):SendMessage(bb:GetModule("Context"):New("spec"), "item/Clearing", item, decoration)
      assert.is_false(o:IsShown())
    end)

    it("draws the badge, greys out a locked lockbox, and hides with style None", function()
      ns.db.style = "badge"
      slot(0, 1, { itemID = 2004, hasLoot = true, locked = true }); d = data(0, 1, 2004)
      draw()
      local o = overlayOf()
      assert.is_true(o.badge:IsShown())
      assert.is_false(o.glow:IsShown())
      ns.db.style = "none"
      ns:RefreshHighlights()
      assert.is_false(o:IsShown())
    end)
  end)

  it("has a settings page that builds", function()
    local settings = bb:GetModule("NextSettings")
    settings:Open("plugin:BetterBags - Treasures")
    assert.are.same({}, handle.errors)
  end)
end)
