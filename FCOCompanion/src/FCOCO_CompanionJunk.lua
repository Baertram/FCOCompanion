FCOCO = FCOCO or  {}
local FCOCompanion = FCOCO
if not FCOCompanion.isCompanionUnlocked then return end
------------------------------------------------------------------------------------------------------------------------

local wasCompanionEquipmentJunkTabMainMenuAdded = false

local playerInv                     = PLAYER_INVENTORY
local compEquip                     = COMPANION_EQUIPMENT_KEYBOARD
local companionEquipmentFragment    = COMPANION_EQUIPMENT_KEYBOARD_FRAGMENT

local invTypeToInvUpdateVar = {
    ["playerInv"] =       INVENTORY_BACKPACK,
    ["bankInv"] =         INVENTORY_BANK,
    ["guildBankInv"] =    INVENTORY_GUILD_BANK,
    ["houseBankInv"] =    INVENTORY_HOUSE_BANK,
}


local preventNextSameBagIdAndSlotIndexUnjunkContextMenu = {}
FCOCompanion.preventNextSameBagIdAndSlotIndexUnjunkContextMenu = preventNextSameBagIdAndSlotIndexUnjunkContextMenu

------------------------------------------------------------------------------------------------------------------------

local function enableJunkCheck()
    if not LibCustomMenu then return end
    local LCM = LibCustomMenu

    local settingsPerToon = FCOCompanion.settingsVars.settingsPerToon
    local isCompanionJunkEnabled = settingsPerToon.enableCompanionItemJunk
    --Is companion junk enabled?
    if not isCompanionJunkEnabled then return end


    playerInv = playerInv or PLAYER_INVENTORY
    compEquip = compEquip or COMPANION_EQUIPMENT_KEYBOARD
    companionEquipmentFragment = companionEquipmentFragment or COMPANION_EQUIPMENT_KEYBOARD_FRAGMENT

    --The table with the junkes companion items
    local junkedCompanionItems = FCOCompanion.settingsVars.settingsPerToon.companionItemsJunked

    local function companionItemChecks(bagId, slotIndex, isCompanionItem)
        if isCompanionItem == nil then
            local actorCategory = GetItemActorCategory(bagId, slotIndex)
            isCompanionItem = (actorCategory ~= nil and actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION) or false
        end
        local itemInstanceId
        if isCompanionItem == true then
            itemInstanceId = zo_getSafeId64Key(GetItemInstanceId(bagId, slotIndex))
        end
        if itemInstanceId == nil then return false, nil end
        return isCompanionItem, itemInstanceId
    end


    local origCanItemBeMarkedAsJunk = CanItemBeMarkedAsJunk
    function CanItemBeMarkedAsJunk(bagId, slotIndex, isCompanionItem)
        local origReturnVar = origCanItemBeMarkedAsJunk(bagId, slotIndex)
        if origReturnVar == false then
            local itemInstanceId
            isCompanionItem, itemInstanceId = companionItemChecks(bagId, slotIndex, isCompanionItem)
            --d("[CanItemBeMarkedAsJunk]" ..GetItemLink(bagId, slotIndex).." - isCompanionItem: " ..tostring(isCompanionItem) .. ", itemInstanceId: " ..tostring(itemInstanceId))
            if isCompanionItem and itemInstanceId ~= nil then
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

            local itemInstanceId
            isCompanionItem, itemInstanceId = companionItemChecks(bagId, slotIndex, isCompanionItem)
            --d("[IsItemJunk]" ..GetItemLink(bagId, slotIndex).." - isCompanionItem: " ..tostring(isCompanionItem) .. ", itemInstanceId: " ..tostring(itemInstanceId))
            if isCompanionItem and itemInstanceId ~= nil then
                --d(">itemIsJunked: " ..tostring(junkedCompanionItems[itemInstanceId]))
                if junkedCompanionItems[itemInstanceId] == true then
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
        local isCompanionItem, itemInstanceId = companionItemChecks(bagId, slotIndex)
        --d("[FCOCompanion.SetCompanionItemJunk]" ..GetItemLink(bagId, slotIndex).." - isCompanionItem: " ..tostring(isCompanionItem) .. ", itemInstanceId: " ..tostring(itemInstanceId) .. ", isJunk: " ..tostring(isJunk))
        if isCompanionItem and itemInstanceId ~= nil then
            if isJunk == false then isJunk = nil end
            junkedCompanionItems[itemInstanceId] = isJunk
            PlaySound(isJunk and SOUNDS.INVENTORY_ITEM_JUNKED or SOUNDS.INVENTORY_ITEM_UNJUNKED)
            --d("<true")
            return true
        end
        --d("<false")
        return false
    end
    FCOCompanion.SetCompanionItemIsJunk = setCompanionItemJunk



    --local playerInvListView = playerInv.inventories[BAG_BACKPACK].listView
    local function refreshInventoryToUpdateFilteredSlotData()
--d("[FCOCompanion]refreshInventoryToUpdateFilteredSlotData")
        local isConpanionInv = (companionEquipmentFragment:IsShowing()) or false
        local invTypeName
        if not isConpanionInv  then
            invTypeName = "playerInv"
            if IsBankOpen() then
                if BANK_FRAGMENT:IsShowing() then
                    invTypeName = "bankInv"
                elseif HOUSE_BANK_FRAGMENT:IsShowing() then
                    invTypeName = "houseBankInv"
                end
            elseif IsGuildBankOpen() and GUILD_BANK_FRAGMENT:IsShowing() then
                invTypeName = "guildBankInv"
            end
        end

        local invToUpdate = (isConpanionInv and compEquip) or playerInv
        local invVarToUse = (not isConpanionInv and invTypeToInvUpdateVar[invTypeName]) or nil
--d(">isConpanionInv: " ..tostring(isConpanionInv) .. ", invToUpdate: " ..tostring(invToUpdate) .. ", invVarToUse: " ..tostring(invVarToUse))
        if invToUpdate.UpdateList == nil then return end
        invToUpdate:UpdateList(invVarToUse)
        --ZO_ScrollList_RefreshVisible(playerInvListView, nil, nil)
    end

    local function updateInvSlotDataEntryDataForFiltering(slotActions, isJunk, bagId, slotIndex)
        local isCompanionItem, itemInstanceId = companionItemChecks(bagId, slotIndex)
        if not isCompanionItem or itemInstanceId == nil then return end

        --Update the slot so it's isJunk is set!
        local invSlotOfAction = slotActions.m_inventorySlot
        --FCOCompanion._invSlotOfActions = invSlotOfAction
        if invSlotOfAction ~= nil then
            local invSlotParent = invSlotOfAction:GetParent()
            if invSlotParent ~= nil then
                --d(">found inv slot: " ..tostring(invSlotParent.dataEntry.data.rawName))
                invSlotOfAction.isJunk = isJunk

                if invSlotParent.dataEntry ~= nil and invSlotParent.dataEntry.data ~= nil then
                    if invSlotParent.dataEntry.data.dataSource ~= nil then
                        invSlotParent.dataEntry.data.dataSource.isJunk = isJunk
                    else
                        invSlotParent.dataEntry.data.isJunk = isJunk
                    end
                end

                --Check the inventory for other companion items which use the same itemInstanceId, but another slotIndex,
                --and which need to be auto-junk marked because of this
                --or
                --Check the junked items for other companion items which use the same itemInstanceId, but another slotIndex,
                --and which need to be auto-un-junk marked because of this
                --Get cached items of the current bag
                if not FCOCompanion.settingsVars.settingsPerToon.autoJunkMarkSameCompanionItemsInBags then return end

                local changedItems = 0
                local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagId)
                if bagCache ~= nil then
                    for _, itemData in pairs(bagCache) do
                        if itemData.slotIndex ~= nil and itemData.slotIndex ~= slotIndex then
                            if itemData.actorCategory == nil then
                                itemData.actorCategory = GetItemActorCategory(bagId, itemData.slotIndex)
                            end
                            if itemData.actorCategory ~= nil and itemData.actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
                                if itemData.isJunk ~= isJunk then
                                    if itemData.itemStanceId == nil then
                                        itemData.itemStanceId = GetItemInstanceId(bagId, itemData.slotIndex)
                                    end
                                    if itemData.itemStanceId ~= nil then
                                        local iiidStr= zo_getSafeId64Key(itemData.itemStanceId)
                                        --Same item, but other slotIndex?
                                        if iiidStr == itemInstanceId then
                                            --d(">found another item: " .. GetItemLink(bagId, itemData.slotIndex))
                                            itemData.isJunk = isJunk
                                            --changedItems = changedItems + 1
                                        end
                                    end
                                end
                            end
                        end
                    end
                    --if changedItems > 0 then
                    --d(">changed items: " ..tostring(changedItems))
                    --end
                end
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

        local isCompanionItem, itemInstanceId = companionItemChecks(bagId, slotIndex)
        if not isCompanionItem or itemInstanceId == nil then return end

        --local itemLink = GetItemLink(bagId, slotIndex)
        --d(">" ..itemLink .. ", itemInstanceId: " ..tostring(itemInstanceId))
        local isJunkable = CanItemBeMarkedAsJunk(bagId, slotIndex, isCompanionItem)

        --d(">>isCompanionItem: " ..tostring(isCompanionItem) .. ", isJunkable: " ..tostring(isJunkable))
        if isCompanionItem == true and isJunkable == true then
            local isCurrentlyJunked = IsItemJunk(bagId, slotIndex, isCompanionItem)

            if isCurrentlyJunked == false then
                --:AddSlotAction(actionStringId, actionCallback, actionType, visibilityFunction, options)
                slotActions:AddCustomSlotAction(SI_ITEM_ACTION_MARK_AS_JUNK, function()
                    if setCompanionItemJunk(bagId, slotIndex, true) == true then
                        updateInvSlotDataEntryDataForFiltering(slotActions, true, bagId, slotIndex)
                        refreshInventoryToUpdateFilteredSlotData()
                    end
                end , "", nil, nil)
                preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId] = preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId] or {}
                preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId][slotIndex] = nil
            else
                slotActions:AddCustomSlotAction(SI_ITEM_ACTION_UNMARK_AS_JUNK, function()
                    if setCompanionItemJunk(bagId, slotIndex, false) == true then
                        --Update the slot so it's isJunk is set!
                        updateInvSlotDataEntryDataForFiltering(slotActions, false, bagId, slotIndex)
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

            --Select the first tab
            ZO_MenuBar_SelectDescriptor(tabs, ITEM_TYPE_DISPLAY_CATEGORY_ALL)

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

    --Prevent depositting junk marked companion items to the guild bank
    -->Will be automatically unjunked, like normal (non companion) items too
    --ZO_PreHook the TransferToGuildBank(sourceBag, sourceSlot) function
    ZO_PreHook("TransferToGuildBank", function(sourceBag, sourceSlot)
        if GetSelectedGuildBankId() then
d("[TransferToGuildBank]guildBankId: " ..tostring(GetSelectedGuildBankId()))
            local isCompanionItem, itemInstanceId = companionItemChecks(sourceBag, sourceSlot, nil)
            if isCompanionItem and itemInstanceId ~= nil then
                if not junkedCompanionItems[itemInstanceId] then return false end
                --UnJunk the companion item
d("<unjunked item: " ..GetItemLink(sourceBag, sourceSlot))
                junkedCompanionItems[itemInstanceId] = nil
            end
        end
        return false
    end)
end
FCOCompanion.EnableJunkCheck = enableJunkCheck