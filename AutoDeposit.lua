--[[
    AutoDeposit v1.2.0
    WoW 3.3.5 (WotLK) Addon
    Scans bags, filters to depositable items only, and deposits
    selected items into a chosen Guild Bank tab.
    Usage: /ad  or  /autodeposit
--]]

------------------------------------------------------------------------
-- Saved variables
------------------------------------------------------------------------
AutoDepositDB = AutoDepositDB or {}

local AD = {}
AD.version       = "1.2.0"
AD.selectedItems = {}    -- [selKey] = true
AD.bagItems      = {}    -- filtered, depositable items only
AD.guildTab      = 1     -- selected guild bank tab (1-based)
AD.guildBankOpen = false -- set by GUILDBANKFRAME_OPENED / CLOSED
AD.rows          = {}    -- reusable row frames

local FRAME_W  = 440
local FRAME_H  = 590
local NUM_ROWS = 12
local ROW_H    = 32
local SCROLL_H = NUM_ROWS * ROW_H   -- 384

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------
local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[AutoDeposit]|r " .. tostring(msg))
end

local function SaveState()
    AutoDepositDB.selectedItems = AD.selectedItems
    AutoDepositDB.guildTab      = AD.guildTab
end

local function LoadState()
    if type(AutoDepositDB.selectedItems) == "table" then
        AD.selectedItems = AutoDepositDB.selectedItems
    end
    if type(AutoDepositDB.guildTab) == "number" then
        AD.guildTab = AutoDepositDB.guildTab
    end
end

local function SelKey(itemID, link)
    return itemID and tostring(itemID) or link
end

------------------------------------------------------------------------
-- Hidden tooltip scanner (checks if an item is depositable)
-- An item cannot be deposited if it is:
--   • Soulbound to the player
--   • A quest item
------------------------------------------------------------------------
local scanTip = CreateFrame("GameTooltip", "AutoDepositScanTip", nil, "GameTooltipTemplate")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

local SOULBOUND_TEXT  = ITEM_SOULBOUND   -- "Soulbound"   (Blizzard global)
local QUEST_ITEM_TEXT = ITEM_BIND_QUEST  -- "Quest Item"  (Blizzard global)

local function IsDepositable(bag, slot, link)
    -- Quick check via GetItemInfo: reject quest item type
    local _, _, _, _, _, itemType = GetItemInfo(link)
    if itemType == "Quest" then return false end

    -- Tooltip scan: reject if "Soulbound" or "Quest Item" line is present
    scanTip:ClearLines()
    scanTip:SetBagItem(bag, slot)
    for i = 2, scanTip:NumLines() do   -- line 1 is always the item name
        local txt = _G["AutoDepositScanTipTextLeft" .. i]
        if txt then
            local t = txt:GetText()
            if t then
                if t == SOULBOUND_TEXT or t == QUEST_ITEM_TEXT then
                    return false
                end
            end
        end
    end
    return true
end

------------------------------------------------------------------------
-- Quality colour codes
------------------------------------------------------------------------
local QCOLOR = {
    [0] = "|cff9d9d9d",
    [1] = "|cffffffff",
    [2] = "|cff1eff00",
    [3] = "|cff0070dd",
    [4] = "|cffa335ee",
    [5] = "|cffff8000",
    [6] = "|cffe6cc80",
}
local function QColor(q) return QCOLOR[q] or QCOLOR[1] end

------------------------------------------------------------------------
-- Bag scanner  (only keeps depositable items)
------------------------------------------------------------------------
local function ScanBags()
    AD.bagItems = {}
    local skipped = 0

    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            -- WotLK 3.3.5: texture, count, locked, quality, readable, lootable, link
            local texture, count, _, quality, _, _, link = GetContainerItemInfo(bag, slot)
            if link then
                if IsDepositable(bag, slot, link) then
                    local itemID = tonumber(link:match("item:(%d+)"))
                    local name   = GetItemInfo(link) or link
                    table.insert(AD.bagItems, {
                        bag     = bag,
                        slot    = slot,
                        itemID  = itemID,
                        selKey  = SelKey(itemID, link),
                        name    = name,
                        count   = count or 1,
                        texture = texture,
                        link    = link,
                        quality = quality or 1,
                    })
                else
                    skipped = skipped + 1
                end
            end
        end
    end

    table.sort(AD.bagItems, function(a, b)
        return (a.name or "") < (b.name or "")
    end)

    return skipped
end

------------------------------------------------------------------------
-- Guild Bank tab dropdown
------------------------------------------------------------------------
local function BuildTabDropdown()
    if not AD.tabDropdown then return end
    local dd = AD.tabDropdown

    UIDropDownMenu_Initialize(dd, function(self, level)
        local numTabs = (GetNumGuildBankTabs and GetNumGuildBankTabs()) or 0
        if numTabs == 0 then
            local info    = UIDropDownMenu_CreateInfo()
            info.text     = "Open Guild Bank first"
            info.disabled = true
            UIDropDownMenu_AddButton(info, level)
            return
        end
        for i = 1, numTabs do
            local tabName, _, isViewable, canDeposit = GetGuildBankTabInfo(i)
            local info   = UIDropDownMenu_CreateInfo()
            info.text    = (canDeposit and "" or "|cff888888") ..
                           "Tab " .. i .. ": " .. (tabName or "?") ..
                           (canDeposit and "" or " (no access)|r")
            info.value   = i
            info.checked = (AD.guildTab == i)
            info.disabled = not (isViewable and canDeposit)
            local ci = i
            local cn = tabName or "?"
            info.func = function()
                AD.guildTab = ci
                UIDropDownMenu_SetText(dd, "Tab " .. ci .. ": " .. cn)
                SaveState()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    local numTabs = (GetNumGuildBankTabs and GetNumGuildBankTabs()) or 0
    if numTabs > 0 then
        local idx = math.min(AD.guildTab, numTabs)
        local tn  = GetGuildBankTabInfo(idx) or "?"
        UIDropDownMenu_SetText(dd, "Tab " .. idx .. ": " .. tn)
    else
        UIDropDownMenu_SetText(dd, "Open Guild Bank first")
    end
end

------------------------------------------------------------------------
-- Scroll list
------------------------------------------------------------------------
local function UpdateScrollFrame()
    if not AD.scrollChild then return end

    local total    = #AD.bagItems
    local contentH = math.max(total * ROW_H, SCROLL_H)
    AD.scrollChild:SetHeight(contentH)

    for i = 1, math.max(total, #AD.rows) do
        local item = AD.bagItems[i]

        -- Create row on demand
        if not AD.rows[i] then
            local row = CreateFrame("Button", "AutoDepositRow" .. i, AD.scrollChild)
            row:SetHeight(ROW_H)
            row:SetWidth(FRAME_W - 44)
            row:SetPoint("TOPLEFT", AD.scrollChild, "TOPLEFT", 2, -((i - 1) * ROW_H))

            local hl = row:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            hl:SetBlendMode("ADD")

            local cb = CreateFrame("CheckButton", "AutoDepositCB" .. i, row, "UICheckButtonTemplate")
            cb:SetSize(22, 22)
            cb:SetPoint("LEFT", row, "LEFT", 4, 0)
            row.checkbox = cb

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(22, 22)
            icon:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            row.icon = icon

            local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            lbl:SetPoint("LEFT",  icon, "RIGHT",  6, 0)
            lbl:SetPoint("RIGHT", row,  "RIGHT", -52, 0)
            lbl:SetJustifyH("LEFT")
            row.lbl = lbl

            local cnt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            cnt:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            cnt:SetWidth(46)
            cnt:SetJustifyH("RIGHT")
            row.cnt = cnt

            local sep = row:CreateTexture(nil, "BACKGROUND")
            sep:SetHeight(1)
            sep:SetPoint("BOTTOMLEFT",  row, "BOTTOMLEFT",  0, 0)
            sep:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
            sep:SetTexture(0.2, 0.2, 0.2, 0.9)

            AD.rows[i] = row
        end

        local row = AD.rows[i]
        if item then
            row:Show()
            row.icon:SetTexture(item.texture)
            row.lbl:SetText(QColor(item.quality) .. item.name .. "|r")
            row.cnt:SetText(item.count > 1 and ("x" .. item.count) or "")
            row.checkbox:SetChecked(AD.selectedItems[item.selKey] == true)

            local sk  = item.selKey
            local lnk = item.link
            row.checkbox:SetScript("OnClick", function(self)
                AD.selectedItems[sk] = self:GetChecked() and true or nil
                SaveState()
            end)
            row:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(lnk)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        else
            row:Hide()
        end
    end

    if AD.statusLabel then
        local sel = 0
        for _ in pairs(AD.selectedItems) do sel = sel + 1 end
        AD.statusLabel:SetText(
            total .. " depositable item" .. (total ~= 1 and "s" or "") ..
            " in bags" .. (sel > 0 and ("  |cff00ff00(" .. sel .. " selected)|r") or "")
        )
    end
end

------------------------------------------------------------------------
-- Deposit
-- We call SetCurrentGuildBankTab then loop through selected items.
-- No extra permission guards here — the game will reject bad calls on
-- its own; guards were the main reason deposits silently failed before.
------------------------------------------------------------------------
local function DoDeposit()
    if not AD.guildBankOpen then
        Print("Open the Guild Bank window first, then click Deposit.")
        return
    end

    -- Switch to the chosen tab
    SetCurrentGuildBankTab(AD.guildTab)

    local deposited = 0
    for _, item in ipairs(AD.bagItems) do
        if AD.selectedItems[item.selKey] then
            DepositGuildBankItem(item.bag, item.slot)
            deposited = deposited + 1
        end
    end

    if deposited > 0 then
        Print("Depositing " .. deposited .. " stack(s) to Guild Bank Tab " .. AD.guildTab .. ".")
        -- Clear selections for items we just sent
        for _, item in ipairs(AD.bagItems) do
            if AD.selectedItems[item.selKey] then
                AD.selectedItems[item.selKey] = nil
            end
        end
        SaveState()
        -- Re-scan after the server has processed the deposits
        local elapsed = 0
        local waitFrame = CreateFrame("Frame")
        waitFrame:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= 0.8 then
                self:SetScript("OnUpdate", nil)
                ScanBags()
                UpdateScrollFrame()
            end
        end)
    else
        Print("Nothing selected — tick checkboxes in the list, then click Deposit.")
    end
end

------------------------------------------------------------------------
-- Select / Deselect All
------------------------------------------------------------------------
local function SelectAll()
    for _, item in ipairs(AD.bagItems) do
        AD.selectedItems[item.selKey] = true
    end
    SaveState()
    UpdateScrollFrame()
end

local function DeselectAll()
    AD.selectedItems = {}
    SaveState()
    UpdateScrollFrame()
end

------------------------------------------------------------------------
-- Frame layout
--
--  Top → Bottom
--  ─────────────────────────────────
--   34 px   title bar
--  384 px   scroll area (12 × 32)
--   18 px   status text
--    1 px   separator
--   42 px   guild tab row  (label + dropdown)
--    1 px   separator
--   36 px   button row
--   14 px   bottom padding
--  ──────────────────────────────────
--  530 px   → FRAME_H = 590 gives headroom
------------------------------------------------------------------------
local function CreateMainFrame()
    if AD.frame then return end

    local f = CreateFrame("Frame", "AutoDepositFrame", UIParent)
    f:SetSize(FRAME_W, FRAME_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:Hide()

    -- ── Title bar ────────────────────────────────────────────────────
    local titleBg = f:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBg:SetWidth(256)
    titleBg:SetHeight(64)
    titleBg:SetPoint("TOP", f, "TOP", 0, 12)

    local titleTxt = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleTxt:SetPoint("TOP", f, "TOP", 0, -6)
    titleTxt:SetText("|cff00ccffAutoDeposit|r  v" .. AD.version)

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local divTop = f:CreateTexture(nil, "ARTWORK")
    divTop:SetHeight(1)
    divTop:SetPoint("TOPLEFT",  f, "TOPLEFT",  14, -30)
    divTop:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -30)
    divTop:SetTexture(0.4, 0.4, 0.4, 1)

    -- ── Scroll area ───────────────────────────────────────────────────
    local scrollFrame = CreateFrame("ScrollFrame", "AutoDepositScrollFrame", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(FRAME_W - 44, SCROLL_H)
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -34)

    local scrollChild = CreateFrame("Frame", "AutoDepositScrollChild", scrollFrame)
    scrollChild:SetSize(FRAME_W - 44, SCROLL_H)
    scrollFrame:SetScrollChild(scrollChild)
    AD.scrollChild = scrollChild

    -- ── Status text ───────────────────────────────────────────────────
    -- Anchored absolutely so nothing floats unexpectedly
    local statusLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -(34 + SCROLL_H + 6))
    statusLabel:SetText("|cffaaaaaa Click 'Bag Scan' to load items|r")
    AD.statusLabel = statusLabel

    -- ── Separator 1 (above tab row) ───────────────────────────────────
    local divMid = f:CreateTexture(nil, "ARTWORK")
    divMid:SetHeight(1)
    divMid:SetPoint("TOPLEFT",  f, "TOPLEFT",  14, -(34 + SCROLL_H + 24))
    divMid:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -(34 + SCROLL_H + 24))
    divMid:SetTexture(0.4, 0.4, 0.4, 1)

    -- ── Guild Bank tab row ────────────────────────────────────────────
    -- 28 px below divMid (from frame top: 34 + 384 + 24 + 8 = 450... wait)
    -- Let's anchor from the bottom up for the bottom sections

    local tabLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tabLbl:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 56)
    tabLbl:SetText("Guild Bank Tab:")

    -- UIDropDownMenuTemplate has built-in 16 px left padding — compensate
    local tabDD = CreateFrame("Frame", "AutoDepositTabDropdown", f, "UIDropDownMenuTemplate")
    tabDD:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 120, 46)
    UIDropDownMenu_SetWidth(tabDD, 220)
    AD.tabDropdown = tabDD

    -- ── Separator 2 (above button row) ───────────────────────────────
    local divBot = f:CreateTexture(nil, "ARTWORK")
    divBot:SetHeight(1)
    divBot:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  14, 46)
    divBot:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, 46)
    divBot:SetTexture(0.4, 0.4, 0.4, 1)

    -- ── Button row (14 px from bottom) ───────────────────────────────
    local BTN_Y = 16   -- y from BOTTOMLEFT

    local scanBtn = CreateFrame("Button", "AutoDepositScanBtn", f, "UIPanelButtonTemplate")
    scanBtn:SetSize(100, 24)
    scanBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, BTN_Y)
    scanBtn:SetText("Bag Scan")
    scanBtn:SetScript("OnClick", function()
        local skipped = ScanBags()
        UpdateScrollFrame()
        BuildTabDropdown()
        local msg = "Scan complete — " .. #AD.bagItems .. " depositable item(s) found."
        if skipped > 0 then
            msg = msg .. " |cff888888(" .. skipped .. " bound/quest item(s) hidden)|r"
        end
        Print(msg)
    end)

    local selAllBtn = CreateFrame("Button", "AutoDepositSelAllBtn", f, "UIPanelButtonTemplate")
    selAllBtn:SetSize(82, 24)
    selAllBtn:SetPoint("LEFT", scanBtn, "RIGHT", 4, 0)
    selAllBtn:SetText("Select All")
    selAllBtn:SetScript("OnClick", SelectAll)

    local deselAllBtn = CreateFrame("Button", "AutoDepositDeselAllBtn", f, "UIPanelButtonTemplate")
    deselAllBtn:SetSize(90, 24)
    deselAllBtn:SetPoint("LEFT", selAllBtn, "RIGHT", 4, 0)
    deselAllBtn:SetText("Deselect All")
    deselAllBtn:SetScript("OnClick", DeselectAll)

    local depositBtn = CreateFrame("Button", "AutoDepositDepositBtn", f, "UIPanelButtonTemplate")
    depositBtn:SetSize(104, 24)
    depositBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -14, BTN_Y)
    depositBtn:SetText("Deposit")
    depositBtn:SetScript("OnClick", DoDeposit)

    -- Frame fully constructed — safe to expose
    AD.frame = f
end

------------------------------------------------------------------------
-- Toggle
------------------------------------------------------------------------
local function ToggleFrame()
    if not AD.frame then
        CreateMainFrame()
    end
    if not AD.frame then
        Print("Could not build frame. Enable Lua errors: |cffff4444/console scriptErrors 1|r")
        return
    end
    if AD.frame:IsShown() then
        AD.frame:Hide()
    else
        ScanBags()
        UpdateScrollFrame()
        BuildTabDropdown()
        AD.frame:Show()
    end
end

------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------
local ev = CreateFrame("Frame", "AutoDepositEventFrame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("GUILDBANKFRAME_OPENED")
ev:RegisterEvent("GUILDBANKFRAME_CLOSED")
ev:RegisterEvent("BAG_UPDATE")

ev:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "AutoDeposit" then
        LoadState()
        Print("v" .. AD.version .. " loaded — type |cff00ccff/ad|r to open.")

    elseif event == "GUILDBANKFRAME_OPENED" then
        AD.guildBankOpen = true
        if AD.frame and AD.frame:IsShown() then
            BuildTabDropdown()
        end

    elseif event == "GUILDBANKFRAME_CLOSED" then
        AD.guildBankOpen = false

    elseif event == "BAG_UPDATE" then
        if AD.frame and AD.frame:IsShown() then
            ScanBags()
            UpdateScrollFrame()
        end
    end
end)

------------------------------------------------------------------------
-- Slash commands
------------------------------------------------------------------------
SLASH_AUTODEPOSIT1 = "/ad"
SLASH_AUTODEPOSIT2 = "/autodeposit"

SlashCmdList["AUTODEPOSIT"] = function(msg)
    local cmd = strtrim(msg):lower()
    if cmd == "help" or cmd == "?" then
        Print("/ad             — toggle window")
        Print("/ad scan        — scan bags, print depositable item count")
        Print("/ad version     — show version")
        Print("/ad help        — this help")
    elseif cmd == "scan" then
        ScanBags()
        Print("Found " .. #AD.bagItems .. " depositable item(s) in bags.")
    elseif cmd == "version" then
        Print("Version " .. AD.version)
    else
        ToggleFrame()
    end
end
