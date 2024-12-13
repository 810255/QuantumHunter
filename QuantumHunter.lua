local addonName, NS = ...

-- Create the main frame
local QuantumHunterFrame = CreateFrame("Frame", "QuantumHunterFrame", UIParent, "BackdropTemplate")
QuantumHunterFrame:SetSize(500, 420)
QuantumHunterFrame:SetPoint("CENTER")
QuantumHunterFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
QuantumHunterFrame:SetBackdropColor(0, 0, 0, 1)
QuantumHunterFrame:EnableMouse(true)
QuantumHunterFrame:SetMovable(true)
QuantumHunterFrame:RegisterForDrag("LeftButton")
QuantumHunterFrame:SetScript("OnDragStart", QuantumHunterFrame.StartMoving)
QuantumHunterFrame:SetScript("OnDragStop", QuantumHunterFrame.StopMovingOrSizing)
QuantumHunterFrame:Hide()

-- Create close button
local closeButton = CreateFrame("Button", nil, QuantumHunterFrame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)

-- Create tabs
local tabs = {}
local tabData = {
    "Axe",
    "Bow",
    "Crossbow",
    "Firearm",
    "Focus",
    "Greataxe",
    "Greathammer",
    "Greatsword",
    "Knife",
    "Knuckles",
    "Mace",
    "Polearm",
    "Shield",
    "Staff",
    "Sword",
    "Wand",
    "Warglaives",
    "Headpiece",
    "Shoulders",
    "Chestpiece",
    "Gloves",
    "Legs",
 }

local activeTab = nil

-- Show the selected tab content
local function ShowTab(index)
    -- Hide all tab contents
    for i, tabContent in ipairs(tabs) do
        tabContent:Hide()
    end
    -- Show the selected tab content
    tabs[index]:Show()
end


-- Create dropdown menu
local dropdown = CreateFrame("Frame", "QuantumHunterDropdown", QuantumHunterFrame, "UIDropDownMenuTemplate")
dropdown:SetPoint("TOPLEFT", QuantumHunterFrame, "TOPLEFT", 5, -15)

-- Function to fetch item details
local function GetItemDetails(itemID)
    local itemName, itemLink, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemID)
    return itemName, itemLink, itemIcon
end

local hideCollected = false;
local hideUncollected = false;
local currArmorType = "Cloth"
local showBOEOnly = false;

local collectedLabel = QuantumHunterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
collectedLabel:SetPoint("TOPLEFT", 125, -15)
collectedLabel:SetText("0/0")

local collectedBOELabel = QuantumHunterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
collectedBOELabel:SetPoint("TOPLEFT", 125, -30)
collectedBOELabel:SetText("0/0")

local function CreateDynamicItemRowsFor(tabName, itemsTab)
    for i, child in ipairs({itemsTab:GetChildren()}) do
        child:Hide()  -- Hide the child frames
        child:SetParent(nil)  -- Optionally, remove them from the hierarchy
    end

    local isArmor = tabName == "Headpiece" or tabName == "Shoulders" or tabName == "Chestpiece" or tabName == "Gloves" or tabName == "Legs";
    local tabNameCopie = tabName;

    if isArmor then
        tabNameCopie = tabName .. currArmorType;
    end

    local tableData = NS[tabNameCopie .. "Table"] -- Fetch the table data for the selected tab;
    local arrayData = NS[tabNameCopie .. "SortArray"] -- Fetch the array data for the selected tab;

    -- Create a scrollable frame for items
    local scrollFrame = CreateFrame("ScrollFrame", "QuantumHunterItemsScrollFrame", itemsTab, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(460, 300)
    scrollFrame:SetPoint("TOP", itemsTab, "TOP", 0, -10)

    -- Create a container for the scrollable content
    local content = CreateFrame("Frame", "QuantumHunterItemsScrollContent", scrollFrame)
    scrollFrame:SetScrollChild(content)

    local i = 0;
    local collectedTotal = 0;
    local collectedBOETotal = 0;
    local totalBOE = 0;

    -- Create item rows
    for _, itemId in ipairs(arrayData) do
        local itemData = tableData[itemId];
        if itemData == nil then
            print("Item not found: " .. itemId);
            return;
        end

        local itemName = itemData.ItemName;
        local itemLink = itemData.ItemLink;
        local isBOE = itemData.IsBOE;

        local isCollected = C_TransmogCollection.PlayerHasTransmog(itemId);

        if isCollected then
            collectedTotal = collectedTotal + 1;

            if isBOE then
                collectedBOETotal = collectedBOETotal + 1;
            end
        end

        if isBOE then
            totalBOE = totalBOE + 1;
        end

        local skip = false;

        if hideCollected and isCollected == true then
            -- Skip this item if it's collected and we're not showing collected items
            skip = true
        end

        if hideUncollected and isCollected == false then
            -- Skip this item if it's not collected and we're not showing uncollected items
            skip = true
        end

        if showBOEOnly and isBOE == false then
            skip = true;
        end

        if (skip == false) then
            i = i + 1;

            local itemIcon = GetItemIcon(itemId);

            -- Create a row frame
            local row = CreateFrame("Frame", nil, content)
            row:SetSize(440, 20) -- Smaller row size
            row:SetPoint("TOP", content, "TOP", 0, -20 * (i - 1))

            -- Add a background highlight effect for hover
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints(row)
            bg:SetColorTexture(0, 0, 0, 0) -- Transparent by default

            row:SetScript("OnEnter", function()
                bg:SetColorTexture(0.2, 0.2, 0.2, 0.5) -- Light gray highlight
                GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(itemLink)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function()
                bg:SetColorTexture(0, 0, 0, 0) -- Remove highlight
                GameTooltip:Hide()
            end)

            -- Enable Shift-click functionality
            row:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" and IsShiftKeyDown() then
                    ChatEdit_InsertLink(itemLink)
                end
            end)

            -- Item icon
            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(16, 16) -- Smaller icon size
            icon:SetPoint("LEFT", row, "LEFT", 5, 0)
            icon:SetTexture(itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark") -- Placeholder if itemIcon is nil

            -- Item name
            local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("LEFT", icon, "RIGHT", 10, 0)
            nameText:SetText(itemName or "Unknown Item")

            -- Collected status (Check or X)
            local status = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            status:SetPoint("RIGHT", row, "RIGHT", -10, 0)
            if isCollected then
                status:SetText("|cff00ff00Y|r") -- Green 'Y' for collected, red 'X' otherwise
            else
                status:SetText("|cffff0000X|r") -- Green 'Y' for collected, red 'X' otherwise
            end
        end
    end

    collectedLabel:SetText(collectedTotal .. "/" .. #arrayData)
    collectedBOELabel:SetText("BOE: " .. collectedBOETotal .. "/" .. totalBOE)
    content:SetSize(460, i * 20) -- Adjust height based on number of items
end

-- Create tab content frames
tabs = {}
for i, tabName in ipairs(tabData) do
    local tabContent = CreateFrame("Frame", nil, QuantumHunterFrame)
    tabContent:SetSize(460, 340)
    tabContent:SetPoint("TOP", QuantumHunterFrame, "TOP", 0, -90)

    tabContent:Hide() -- Hide all tabs initially
    tabs[i] = tabContent
end

-- Dropdown initialization
local function InitializeDropdown(self, level)
    local info = UIDropDownMenu_CreateInfo()
    for index, tabName in ipairs(tabData) do
        info.text = tabName
        info.checked = (activeTab == index) -- Check only the active tab
        info.func = function()
            activeTab = index -- Update the active tab
            UIDropDownMenu_SetSelectedID(self, index) -- Update dropdown to reflect selected tab
            ShowTab(index) -- Show the appropriate tab content
            CreateDynamicItemRowsFor(tabName, tabs[index])
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

UIDropDownMenu_SetWidth(dropdown, 75)
UIDropDownMenu_Initialize(dropdown, InitializeDropdown)
UIDropDownMenu_SetSelectedID(dropdown, 1) -- Default to the first tab

activeTab = 1;
ShowTab(1);

-- add some options to QuantumHunterFrame
-- button to refresh
local refreshButton = CreateFrame("Button", nil, QuantumHunterFrame, "UIPanelButtonTemplate")
refreshButton:SetSize(100, 25)
refreshButton:SetPoint("TOPRIGHT", -20, -30)
refreshButton:SetText("Refresh")
refreshButton:SetScript("OnClick", function()
    CreateDynamicItemRowsFor(tabData[activeTab], tabs[activeTab])
end)

-- add checkbox to show collected items
local hideCollectedCheckbox = CreateFrame("CheckButton", nil, QuantumHunterFrame, "UICheckButtonTemplate")
hideCollectedCheckbox:SetPoint("TOP", 10, -10)
hideCollectedCheckbox.text:SetText("Hide Collected")
hideCollectedCheckbox:SetChecked(false)
hideCollectedCheckbox:SetScript("OnClick", function()
    local isChecked = hideCollectedCheckbox:GetChecked()
    hideCollected = isChecked
    CreateDynamicItemRowsFor(tabData[activeTab], tabs[activeTab])
end)

-- add checkbox to show uncollected items
local hideUncollectedCheckbox = CreateFrame("CheckButton", nil, QuantumHunterFrame, "UICheckButtonTemplate")
hideUncollectedCheckbox:SetPoint("TOP", 10, -30)
hideUncollectedCheckbox.text:SetText("Hide Uncollected")
hideUncollectedCheckbox:SetChecked(false)
hideUncollectedCheckbox:SetScript("OnClick", function()
    local isChecked = hideUncollectedCheckbox:GetChecked()
    hideUncollected = isChecked
    CreateDynamicItemRowsFor(tabData[activeTab], tabs[activeTab])
end)

-- add checkbox to show BOE items only
local showBOEOnlyCheckbox = CreateFrame("CheckButton", nil, QuantumHunterFrame, "UICheckButtonTemplate")
showBOEOnlyCheckbox:SetPoint("TOP", 10, -50)
showBOEOnlyCheckbox.text:SetText("Show BOE Only")
showBOEOnlyCheckbox:SetChecked(false)
showBOEOnlyCheckbox:SetScript("OnClick", function()
    local isChecked = showBOEOnlyCheckbox:GetChecked()
    showBOEOnly = isChecked
    CreateDynamicItemRowsFor(tabData[activeTab], tabs[activeTab])
end)

-- add a dropdown to set armor type lookup, cloth, leather, mail or plate
local armorTypeDropdown = CreateFrame("Frame", "QuantumHunterArmorTypeDropdown", QuantumHunterFrame, "UIDropDownMenuTemplate")
armorTypeDropdown:SetPoint("TOPLEFT", QuantumHunterFrame, "TOPLEFT", 5, -45)

local armorTypes = {
    "Cloth",
    "Leather",
    "Mail",
    "Plate"
}

-- Dropdown InitializeDropdownArmor
local function InitializeDropdownArmor(self, level)
    local info = UIDropDownMenu_CreateInfo()
    for index, tabName in ipairs(armorTypes) do
        info.text = tabName
        info.checked = false;
        info.func = function()
            UIDropDownMenu_SetSelectedID(self, index) -- Update dropdown to reflect selected tab
            currArmorType = tabName
            CreateDynamicItemRowsFor(tabData[activeTab], tabs[activeTab])
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

UIDropDownMenu_SetWidth(armorTypeDropdown, 75)
UIDropDownMenu_Initialize(armorTypeDropdown, InitializeDropdownArmor)

-- check class so we can set proper armor type default
local _, class = UnitClass("player")
if class == "MAGE" or class == "WARLOCK" or class == "PRIEST" then
    UIDropDownMenu_SetSelectedID(armorTypeDropdown, 1)
    currArmorType = "Cloth"
elseif class == "DRUID" or class == "ROGUE" or class == "MONK" or class == "DEMONHUNTER" then
    UIDropDownMenu_SetSelectedID(armorTypeDropdown, 2)
    currArmorType = "Leather"
elseif class == "HUNTER" or class == "SHAMAN" then
    UIDropDownMenu_SetSelectedID(armorTypeDropdown, 3)
    currArmorType = "Mail"
elseif class == "WARRIOR" or class == "PALADIN" or class == "DEATHKNIGHT" then
    UIDropDownMenu_SetSelectedID(armorTypeDropdown, 4)
    currArmorType = "Plate"
end

-- Slash command to open the frame
SLASH_QUANTUMHUNTER1 = "/quantumhunter"
SlashCmdList["QUANTUMHUNTER"] = function()
    if QuantumHunterFrame:IsShown() then
        QuantumHunterFrame:Hide()
    else
        QuantumHunterFrame:Show()
    end
end
