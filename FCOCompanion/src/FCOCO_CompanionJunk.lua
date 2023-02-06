FCOCO = FCOCO or  {}
local FCOCompanion = FCOCO
if not FCOCompanion.isCompanionUnlocked then return end
------------------------------------------------------------------------------------------------------------------------


local function enableJunkCheck()
    if not LibCustomMenu then return end
    local LCM = LibCustomMenu

    local settingsPerToon = FCOCompanion.settingsVars.settingsPerToon
    local isCompanionJunkEnabled = settingsPerToon.enableCompanionItemJunk
    --Is companion junk enabled?
    if not isCompanionJunkEnabled then return end

    --Add the context menu entry to normal inventory row "Companion items" -> SlotAction mark_as_junk and unmark_as_junk at:
    --https://github.com/esoui/esoui/blob/148bf16c4c457ca9d75e41e7045e59de624b1ae7/esoui/ingame/inventory/inventoryslot.lua#L1809
    -->Either prehook ZO_InventorySlot_DiscoverSlotActionsFromActionList and return another entry of actionHandlers instead of normal mark_as_junk and unmark_as_junk or maybe use
    -->LibCustomMenu if this works to replace those handlers: actionSlots:AddCustomSlotAction(actionStringId, actionCallback, actionType, visibilityFunction, options)

    --Texts:
    --Mark as junk:     SI_ITEM_ACTION_MARK_AS_JUNK
    --Unmark from Junk: SI_ITEM_ACTION_UNMARK_AS_JUNK

    --[[

        local function AddItem(inventorySlot, slotActions)
          local valid = ZO_Inventory_GetBagAndIndex(inventorySlot)
          if not valid then return end
          --Check if is companion item and is junkable and not already junked at the moment
            local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
            --local itemLink = GetItemLink(bagId, slotIndex)
            if bagId ~= nil and slotIndex ~= nil then
                local itemId = GetItemId(bagId, slotIndex)
                if itemId ~= nil then
                  local actorCategory = GetItemActorCategory(bag, index)
                  local isCompanionItem = (actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION) or false
                  local isJunkable = CanItemBeMarkedAsJunk(bagId, slotIndex)
                  local isCurrentlyJunked = junkedCompanionItems[itemId] or false
                  if isCompanionItem and isJunkable then
                    if not isCurrentlyJunked then
                      slotActions:AddCustomSlotAction(SI_ITEM_ACTION_MARK_AS_JUNK, function()
                        junkedCompanionItems[itemId] = true
                      end , "")
                    else
                      slotActions:AddCustomSlotAction(SI_ITEM_ACTION_UNMARK_AS_JUNK, function()
                        junkedCompanionItems[itemId] = nil
                      end , "")
                    end
                end
            end

        end

        LCM:RegisterContextMenu(AddItem, LibCustomMenu.CATEGORY_PRIMARY)
    ]]

    ---Prehook functions needed like SetItemIsJunk and CanItemBeMarkedAsJunk and IsItemJunk to check table settingsPerToon.companionItemsJunked too

    --[[
    local function MarkAsJunkHelper(bag, index, isJunk)
        SetItemIsJunk(bag, index, isJunk)
        PlaySound(isJunk and SOUNDS.INVENTORY_ITEM_JUNKED or SOUNDS.INVENTORY_ITEM_UNJUNKED)
    end

    ...
    local actionHandlers = {
    ...

    ["mark_as_junk"] = function(inventorySlot, slotActions)
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        local actorCategory = GetItemActorCategory(bag, index)
        if not IsInGamepadPreferredMode() and actorCategory ~= GAMEPLAY_ACTOR_CATEGORY_COMPANION and not IsSlotLocked(inventorySlot) and CanItemBeMarkedAsJunk(bag, index) and not IsItemJunk(bag, index) and not QUICKSLOT_KEYBOARD:AreQuickSlotsShowing() then
            slotActions:AddSlotAction(SI_ITEM_ACTION_MARK_AS_JUNK, function() MarkAsJunkHelper(bag, index, true) end, "secondary")
        end
    end,

    ["unmark_as_junk"] = function(inventorySlot, slotActions)
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if not IsInGamepadPreferredMode() and not IsSlotLocked(inventorySlot) and CanItemBeMarkedAsJunk(bag, index) and IsItemJunk(bag, index) and not QUICKSLOT_KEYBOARD:AreQuickSlotsShowing() then
            slotActions:AddSlotAction(SI_ITEM_ACTION_UNMARK_AS_JUNK, function() MarkAsJunkHelper(bag, index, false) end, "secondary")
        end
    end,

    ...

    } --actionHandlers


    function ZO_InventorySlot_DiscoverSlotActionsFromActionList(inventorySlot, slotActions)
        local slotType = ZO_InventorySlot_GetType(inventorySlot)
        local potentialActions = potentialActionsForSlotType[slotType]
        if potentialActions then
            if not blanketDisableActionsForSlotType[slotType] or not blanketDisableActionsForSlotType[slotType]() then
                for _, action in ipairs(potentialActions) do
                    local actionHandler = actionHandlers[action]
                    actionHandler(inventorySlot, slotActions)
                end
            end
        end
    end


    --To show the items at the junk tab we need to change the itemTypeDisplayCategory passed in to ZO_ItemFilterUtils.IsSlotFilterDataInItemTypeDisplayCategory
    function ZO_ItemFilterUtils.IsSlotFilterDataInItemTypeDisplayCategory(slot, itemTypeDisplayCategory)
        if slot.isJunk then
            return itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_JUNK
        end
    end


    ]]

    --The table with the junkes companion items
    local junkedCompanionItems = FCOCompanion.settingsVars.settingsPerToon.companionItemsJunked
    local preventNextSameBagIdAndSlotIndexUnjunkContextMenu = {}

    local function companionItemChecks(bagId, slotIndex, isCompanionItem)
        if isCompanionItem == nil then
            local actorCategory = GetItemActorCategory(bagId, slotIndex)
            isCompanionItem = (actorCategory ~= nil and actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION) or false
        end
        local itemId
        if isCompanionItem == true then
            itemId = GetItemId(bagId, slotIndex)
        end
        if itemId == nil then return false, nil end
        return isCompanionItem, itemId
    end


    local origCanItemBeMarkedAsJunk = CanItemBeMarkedAsJunk
    function CanItemBeMarkedAsJunk(bagId, slotIndex, isCompanionItem)
        local origReturnVar = origCanItemBeMarkedAsJunk(bagId, slotIndex)
        if origReturnVar == false then
            local itemId
            isCompanionItem, itemId = companionItemChecks(bagId, slotIndex, isCompanionItem)
            --d("[CanItemBeMarkedAsJunk]" ..GetItemLink(bagId, slotIndex).." - isCompanionItem: " ..tostring(isCompanionItem) .. ", itemId: " ..tostring(itemId))
            if isCompanionItem and itemId ~= nil then
                --d("<true")
                return true
            end
        end
        --d("<[CanItemBeMarkedAsJunk]origFuncCall return var: " ..tostring(origReturnVar))
        return origReturnVar
    end

    local origIsItemJunk = IsItemJunk
    function IsItemJunk(bagId, slotIndex, isCompanionItem)
        local origReturnVar = origIsItemJunk(bagId, slotIndex)
        if origReturnVar == false then
            --Was called from ESO vanilla code?
            if isCompanionItem == nil then
                --Check if the origFunction must return false in order to suppress the context menu entry
                -->Checking preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId][slotIndex] == true and resetting
                if preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId] ~= nil and
                        preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId][slotIndex] == true then
                    --d("<[IsItemJunk]ABORT as bagId and slotIndex already got the \'Remove from junk\' custom slotAction entry!")
                    preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId][slotIndex] = nil
                    return origReturnVar
                end
            end

            local itemId
            isCompanionItem, itemId = companionItemChecks(bagId, slotIndex, isCompanionItem)
            --d("[IsItemJunk]" ..GetItemLink(bagId, slotIndex).." - isCompanionItem: " ..tostring(isCompanionItem) .. ", itemId: " ..tostring(itemId))
            if isCompanionItem and itemId ~= nil then
                --d(">itemIsJunked: " ..tostring(junkedCompanionItems[itemId]))
                if junkedCompanionItems[itemId] == true then
                    --d("<true")
                    return true
                else
                    --d("<false")
                    return false
                end
            end
        end
        --d("<[IsItemJunk]origFuncCall return var: " ..tostring(origReturnVar))
        return origReturnVar
    end


    local function setCompanionItemJunk(bagId, slotIndex, isJunk)
        local isCompanionItem, itemId = companionItemChecks(bagId, slotIndex)
        --d("[FCOCompanion.SetCompanionItemJunk]" ..GetItemLink(bagId, slotIndex).." - isCompanionItem: " ..tostring(isCompanionItem) .. ", itemId: " ..tostring(itemId) .. ", isJunk: " ..tostring(isJunk))
        if isCompanionItem and itemId ~= nil then
            if isJunk == false then isJunk = nil end
            junkedCompanionItems[itemId] = isJunk
            PlaySound(isJunk and SOUNDS.INVENTORY_ITEM_JUNKED or SOUNDS.INVENTORY_ITEM_UNJUNKED)
            --d("<true")
            return true
        end
        --d("<false")
        return false
    end
    FCOCompanion.SetCompanionItemIsJunk = setCompanionItemJunk


    local playerInv = PLAYER_INVENTORY
    --local playerInvListView = playerInv.inventories[BAG_BACKPACK].listView
    local function refreshInventoryToUpdateFilteredSlotData()
        playerInv:UpdateList(INVENTORY_BACKPACK)
        --ZO_ScrollList_RefreshVisible(playerInvListView, nil, nil)
    end

    local function updateInvSlotDataEntryDataForFiltering(slotActions, isJunk)
        --Update the slot so it's isJunk is set!
        local invSlotOfAction = slotActions.m_inventorySlot
        --FCOCompanion._invSlotOfActions = invSlotOfAction
        if invSlotOfAction ~= nil then
            local invSlotParent = invSlotOfAction:GetParent()
            if invSlotParent ~= nil then
                --d(">found inv slot: " ..tostring(invSlotParent.dataEntry.data.rawName))
                invSlotOfAction.isJunk = isJunk
                invSlotParent.dataEntry.data.isJunk = isJunk
            end
        end
    end

    local function AddItem(inventorySlot, slotActions)
        --d("[LCM:AddItem]")
        if IsInGamepadPreferredMode() or QUICKSLOT_KEYBOARD:AreQuickSlotsShowing() then return end
        local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if bagId == nil or slotIndex == nil then return end

        --Raises an error!!!
        --if inventorySlot ~= nil and IsSlotLocked(inventorySlot) then return end

        local isCompanionItem, itemId = companionItemChecks(bagId, slotIndex)
        if not isCompanionItem or itemId == nil then return end

        --local itemLink = GetItemLink(bagId, slotIndex)
        --d(">" ..itemLink .. ", itemId: " ..tostring(itemId))
        local isJunkable = CanItemBeMarkedAsJunk(bagId, slotIndex, isCompanionItem)

        --d(">>isCompanionItem: " ..tostring(isCompanionItem) .. ", isJunkable: " ..tostring(isJunkable))
        if isCompanionItem == true and isJunkable == true then
            local isCurrentlyJunked = IsItemJunk(bagId, slotIndex, isCompanionItem)

            if isCurrentlyJunked == false then
                --:AddSlotAction(actionStringId, actionCallback, actionType, visibilityFunction, options)
                slotActions:AddCustomSlotAction(SI_ITEM_ACTION_MARK_AS_JUNK, function()
                    if setCompanionItemJunk(bagId, slotIndex, true) == true then
                        updateInvSlotDataEntryDataForFiltering(slotActions, true)
                        refreshInventoryToUpdateFilteredSlotData()
                    end
                end , "", nil, nil)
                preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId] = preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId] or {}
                preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId][slotIndex] = nil
            else
                slotActions:AddCustomSlotAction(SI_ITEM_ACTION_UNMARK_AS_JUNK, function()
                    if setCompanionItemJunk(bagId, slotIndex, false) == true then
                        --Update the slot so it's isJunk is set!
                        updateInvSlotDataEntryDataForFiltering(slotActions, false)
                        --Refresh the visible scrolllist and the slotsData properly -> Inventory refresh?
                        refreshInventoryToUpdateFilteredSlotData()
                    end
                end , "", nil, nil)
                --Prevent showing the "Unjunk item" entry at teh context menu slotActions -> Vanilla ESO -> Checked at function IsItemJunk!
                preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId] = preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId] or {}
                preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId][slotIndex] = true
            end
        end
    end
    LCM:RegisterContextMenu(AddItem, LibCustomMenu.CATEGORY_PRIMARY)



    --Filter functions
    local origZO_ItemFilterUtils_IsSlotInItemTypeDisplayCategoryAndSubcategory = ZO_ItemFilterUtils.IsSlotInItemTypeDisplayCategoryAndSubcategory
    SecurePostHook(ZO_ItemFilterUtils, "IsSlotInItemTypeDisplayCategoryAndSubcategory", function(slot, itemTypeDisplayCategory, itemTypeSubCategory)
        local origFuncRetVar = origZO_ItemFilterUtils_IsSlotInItemTypeDisplayCategoryAndSubcategory(slot, itemTypeDisplayCategory, itemTypeSubCategory)
        --Inventory Junk tab, companion item, which is marked as "custom junk"
        local isActorCategoryCompanionAndJunkTabAndMarkedAsJunk = (itemTypeDisplayCategory == ITEM_TYPE_DISPLAY_CATEGORY_JUNK and slot.actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION and slot.isJunk) or false
        if not isActorCategoryCompanionAndJunkTabAndMarkedAsJunk then return origFuncRetVar end

        --local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(slot)
        --d("[IsSlotIn...]" ..GetItemLink(bagId, slotIndex))
        --d(">itemTypeDisplayCategory: " ..tostring(itemTypeDisplayCategory) .. ", itemTypeSubCategory: " ..tostring(itemTypeSubCategory))
        --return ZO_ItemFilterUtils.IsSlotFilterDataInItemTypeDisplayCategory(slot, itemTypeSubCategory)
        return true
    end)

    --[[
    ZO_PreHook(ZO_ItemFilterUtils, "IsSlotFilterDataInItemTypeDisplayCategory", function(slot, itemTypeDisplayCategory)
        --Companion item which is marked as "custom junk"
        local isActorCategoryCompanionAndMarkedAsJunk = (slot.actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION and slot.isJunk) or false
        if not isActorCategoryCompanionAndMarkedAsJunk then return false end --call orig func

    local bagId, slotIndex = ZO_Inventory_GetBagAndIndex(slot)
    d("[IsSlotFilterDataIn...]" ..GetItemLink(bagId, slotIndex))
    d(">itemTypeDisplayCategory: " ..tostring(itemTypeDisplayCategory))
        return true
    end)
    ]]


    --Companion equipment
    local wasCompanionEquipmentJunkTabMainMenuAdded = false
    local compEquip         = COMPANION_EQUIPMENT_KEYBOARD

    local FILTER_KEYS =
    {
        ITEM_TYPE_DISPLAY_CATEGORY_JUNK, ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY, ITEM_TYPE_DISPLAY_CATEGORY_ARMOR, ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS, ITEM_TYPE_DISPLAY_CATEGORY_ALL,
    }
    local SEARCH_FILTER_KEYS =
    {
        [ITEM_TYPE_DISPLAY_CATEGORY_ALL] =
        {
            ITEM_TYPE_DISPLAY_CATEGORY_ALL,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_WEAPONS] =
        {
            EQUIPMENT_FILTER_TYPE_RESTO_STAFF, EQUIPMENT_FILTER_TYPE_DESTRO_STAFF, EQUIPMENT_FILTER_TYPE_BOW,
            EQUIPMENT_FILTER_TYPE_TWO_HANDED, EQUIPMENT_FILTER_TYPE_ONE_HANDED, EQUIPMENT_FILTER_TYPE_NONE,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_ARMOR] =
        {
            EQUIPMENT_FILTER_TYPE_SHIELD, EQUIPMENT_FILTER_TYPE_HEAVY, EQUIPMENT_FILTER_TYPE_MEDIUM,
            EQUIPMENT_FILTER_TYPE_LIGHT, EQUIPMENT_FILTER_TYPE_NONE,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_JEWELRY] =
        {
            EQUIPMENT_FILTER_TYPE_RING, EQUIPMENT_FILTER_TYPE_NECK, EQUIPMENT_FILTER_TYPE_NONE,
        },
        [ITEM_TYPE_DISPLAY_CATEGORY_JUNK] =
        {
            EQUIPMENT_FILTER_TYPE_NONE,
        },
    }

    local IS_SUB_FILTER = true
    local function GetSearchFilters(searchFilterKeys)
        local searchFilters = {}
        for filterId, subFilters in pairs(searchFilterKeys) do
            searchFilters[filterId] = {}

            local searchFilterAtId = searchFilters[filterId]
            for _, subfilterKey in ipairs(subFilters) do
                local filterData = ZO_ItemFilterUtils.GetSearchFilterData(filterId, subfilterKey)
                local filter = compEquip:CreateNewTabFilterData(filterData.filterType, filterData.filterString, filterData.icons.up, filterData.icons.down, filterData.icons.over, IS_SUB_FILTER)
                table.insert(searchFilterAtId, filter)
            end
        end

        return searchFilters
    end

    local function addJunkFilterTab(control)
        --Clear the menu tabs
        local tabs = control:GetNamedChild("Tabs")
        if tabs ~= nil then
            tabs.m_object:ClearButtons()

            --Reset the filters & subFilters
            compEquip.filters = {}
            compEquip.subFilters = {}

            --Rebuild the filetrs and add the tab buttons
            for _, key in ipairs(FILTER_KEYS) do
                local filterData = ZO_ItemFilterUtils.GetItemTypeDisplayCategoryFilterDisplayInfo(key)
                local filter = compEquip:CreateNewTabFilterData(filterData.filterType, filterData.filterString, filterData.icons.up, filterData.icons.down, filterData.icons.over)
                filter.control = ZO_MenuBar_AddButton(compEquip.tabs, filter)
                table.insert(compEquip.filters, filter)
            end
            --Rebuild the subfilters
            compEquip.subFilters = GetSearchFilters(SEARCH_FILTER_KEYS, INVENTORY_BACKPACK)

            wasCompanionEquipmentJunkTabMainMenuAdded = true
        end
    end


    COMPANION_EQUIPMENT_KEYBOARD_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        --d("[COMPANION_EQUIPMENT_KEYBOARD_FRAGMENT]State: " ..tostring(newState))
        if newState == SCENE_FRAGMENT_SHOWN then
            if wasCompanionEquipmentJunkTabMainMenuAdded == false then
                --d(">adding main menu bar \'Junk\' tab")
                addJunkFilterTab(ZO_CompanionEquipment_Panel_Keyboard)
            end
        end
    end)

    --Change the filter function for companion items to filter custom junk marked items (from the "All" tab, all others seem to work fine so far)
    local origZO_ItemFilterUtilsIsCompanionSlotInItemTypeDisplayCategoryAndSubcategory = ZO_ItemFilterUtils.IsCompanionSlotInItemTypeDisplayCategoryAndSubcategory
    SecurePostHook(ZO_ItemFilterUtils, "IsCompanionSlotInItemTypeDisplayCategoryAndSubcategory", function(slot, itemTypeDisplayCategory, itemTypeSubCategory)
        local origFuncRetVar = origZO_ItemFilterUtilsIsCompanionSlotInItemTypeDisplayCategoryAndSubcategory(slot, itemTypeDisplayCategory, itemTypeSubCategory)
        if itemTypeDisplayCategory ~= ITEM_TYPE_DISPLAY_CATEGORY_ALL then return origFuncRetVar end

        --Inventory Junk tab, companion item, which is marked as "custom junk"
        local isMarkedAsJunk = slot.isJunk or false
        if not isMarkedAsJunk then return origFuncRetVar end

        --Filetr/hide as it's a junked item
        return false
    end)
end
FCOCompanion.EnableJunkCheck = enableJunkCheck