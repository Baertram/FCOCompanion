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
--Supported bagIds where companion items can be stored
local companionItemBags = {
    [BAG_BACKPACK]          = true,
    [BAG_BANK]              = true,
    --[BAG_GUILDBANK]         = true,
    [BAG_HOUSE_BANK_ONE]    = true,
    [BAG_HOUSE_BANK_TWO]    = true,
    [BAG_HOUSE_BANK_THREE]  = true,
    [BAG_HOUSE_BANK_FOUR]   = true,
    [BAG_HOUSE_BANK_FIVE]   = true,
    [BAG_HOUSE_BANK_SIX]    = true,
    [BAG_HOUSE_BANK_SEVEN]  = true,
    [BAG_HOUSE_BANK_EIGHT]  = true,
    [BAG_HOUSE_BANK_NINE]   = true,
    [BAG_HOUSE_BANK_TEN]    = true,
}

--local preventNextSameBagIdAndSlotIndexUnjunkContextMenu = {}
--FCOCompanion.preventNextSameBagIdAndSlotIndexUnjunkContextMenu = preventNextSameBagIdAndSlotIndexUnjunkContextMenu

------------------------------------------------------------------------------------------------------------------------

--Is companion junk enabled at the settings?
--returns boolean isCompanionJunkEnabled, table junkedItemsWithItemInstanceIdSavedVariablesOfCurrentToon
function FCOCompanion.IsCompanionJunkEnabled()
    local settingsPerToon = FCOCompanion.settingsVars.settingsPerToon
    local isCompanionJunkEnabled = settingsPerToon ~= nil and settingsPerToon.enableCompanionItemJunk
    return isCompanionJunkEnabled, settingsPerToon.companionItemsJunked
end
local isCompanionJunkEnabled = FCOCompanion.IsCompanionJunkEnabled


local function enableJunkCheck()
    if not LibCustomMenu then return end
    local LCM = LibCustomMenu

    local isCompanionJunkCurrentlyEnabled = isCompanionJunkEnabled()
    if not isCompanionJunkCurrentlyEnabled then return end

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

    local origHasAnyJunk = HasAnyJunk
    function HasAnyJunk(bagId, excludeStolenItems)
        excludeStolenItems = excludeStolenItems or false
        local origRetVar = origHasAnyJunk(bagId, excludeStolenItems)

        local isCompanionItemSupportedBag = companionItemBags[bagId] or false
        if origRetVar == false and isCompanionItemSupportedBag == true then --Only supported companion item bagIds
            --Check if there is any "junked companion item in the bag"
            local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagId)
            if bagCache ~= nil then
                for _, itemData in pairs(bagCache) do
                    if itemData.actorCategory == nil then
                        itemData.actorCategory = GetItemActorCategory(bagId, itemData.slotIndex)
                    end
                    --Is a companion item?
                    if itemData.actorCategory ~= nil and itemData.actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION then
                        --Is junked?
                        if itemData.isJunk == true then
                            --Exclude stolen items?
                            if excludeStolenItems == true then
                                if itemData.isStolen == nil then
                                    itemData.isStolen = IsItemStolen(bagId, itemData.slotIndex)
                                end
                                --Is nt stolen: So we found a junked companion item
                                if not itemData.isStolen then
                                    return true
                                end
                            else
                                --We found a junked companion items
                                return true
                            end
                        end
                    end
                end
            end
        end
        return origRetVar
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
        --Orig function says: Is no junk
        if origReturnVar == false then

            --[[
            --Not needed anymore as functon AddItems below does not add a custom context menu entry for "Remove from junk" anymore.
            --We will just reuse the vanilla code API functions and context menu entry (as the slotActions for remove junk do not check the gameplayActorCategory,
            --only the "Add to junk" does...)

            --Was called from ESO vanilla code?
            if isCompanionItem == nil then
                --Check if the origFunction must return false in order to suppress the context menu entry "Remove from junk", as the entry "Remoe from junk" was added by
                --this addon FCOCompanion already -> See function "AddItems" below
                -->We cannot simply use vanilla code to add the entries for "Add to junk" and "Remove from junk" as the ActionCategoryOwner companion was explicitly excluded there :(
                --So we set a "skip variable" based on bagId and slotIndex at function "AddItems" and the next time the slotActions for "Remove from junk" are build this function
                --IsItemJunk will be called and the "Remove from junk" entry wil be skipped

                --So first check if slotActions are currently determined for the context menu, so another check with IsItemJunk(bagId, slotIndex) won't remove the "skip variables"
                --to early!
                --todo
                --Then check if the skip variables are in place
                -->Checking preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId][slotIndex] == true and resetting
                if preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId] ~= nil and
                        preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId][slotIndex] == true then
d("<<<!!!ABORT [IsItemJunk] preventNextSameBagIdAndSlotIndexUnjunkContextMenu[" ..tostring(bagId) .. "][" ..tostring(slotIndex) .. "] = nil")
                    preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId][slotIndex] = nil
                    --Return false to revent the 2nd entry to context menu: "Remove from junk"
                    return origReturnVar
                end
            end
            ]]

            local itemInstanceId
            isCompanionItem, itemInstanceId = companionItemChecks(bagId, slotIndex, isCompanionItem)
--d("[IsItemJunk]" ..GetItemLink(bagId, slotIndex).." - isCompanionItem: " ..tostring(isCompanionItem) .. ", itemInstanceId: " ..tostring(itemInstanceId) .. ", itemIsJunked: " ..tostring(junkedCompanionItems[itemInstanceId]))
            if isCompanionItem and itemInstanceId ~= nil then
                if junkedCompanionItems[itemInstanceId] == true then
                    --d("<true")
                    return true
                else
                    --d("<false")
                    return false
                end
            end
        end
--        if isCompanionItem == true then
--d("<[IsItemJunk]origFuncCall return var: " ..tostring(origReturnVar))
--        end
        return origReturnVar
    end


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
    FCOCompanion.RefreshInventoryToUpdateFilteredSlotData = refreshInventoryToUpdateFilteredSlotData

    local calledUpdateInvSlotDataEntryDataForFilteringFromExternalAddon = nil
    local function updateInvSlotDataEntryDataForFiltering(inventorySlot, isJunk, bagId, slotIndex, isCompanionItem, itemInstanceId)
        if bagId == nil or slotIndex == nil then
            calledUpdateInvSlotDataEntryDataForFilteringFromExternalAddon = nil
            return
        end
--d("[FCOCO]updateInvSlotDataEntryDataForFiltering - " .. GetItemLink(bagId, slotIndex) .. ", isJunk: " ..tostring(isJunk))

        if calledUpdateInvSlotDataEntryDataForFilteringFromExternalAddon == nil then calledUpdateInvSlotDataEntryDataForFilteringFromExternalAddon = true end
        if calledUpdateInvSlotDataEntryDataForFilteringFromExternalAddon == false and isJunk == nil then
            calledUpdateInvSlotDataEntryDataForFilteringFromExternalAddon = nil
            return
        end

        if isCompanionItem == nil or itemInstanceId == nil then
            isCompanionItem, itemInstanceId = companionItemChecks(bagId, slotIndex)
        end
        if not isCompanionItem or itemInstanceId == nil then
            calledUpdateInvSlotDataEntryDataForFilteringFromExternalAddon = nil
            return
        end
--d(">isCompanionItem!")
        --Update the slot so it's isJunk is set!
        --local invSlotOfAction = slotActions.m_inventorySlot
        --FCOCompanion._invSlotOfActions = invSlotOfAction

        local data, bagCache
        if inventorySlot ~= nil then
            local invSlotParent = inventorySlot:GetParent()
            if invSlotParent ~= nil and invSlotParent.dataEntry ~= nil and invSlotParent.dataEntry.data ~= nil then
--d(">found inv slot parent -> data")
                data = invSlotParent.dataEntry.data
            end
        end

        --Determine the current inventory slot
        if inventorySlot == nil or data == nil then
            --inventorySlot = moc() --is this enough? Should be the current control below the mouse
            bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagId)
            if bagCache ~= nil and bagCache[slotIndex] ~= nil then
--d(">found inv slot by BAG cache -> data")
                data = bagCache[slotIndex]
                inventorySlot = bagCache[slotIndex].slotControl
            end
        end

        if data ~= nil and inventorySlot ~= nil then
            --For calls from other addons: Detect is item currently got isJunk flag true or false
            if calledUpdateInvSlotDataEntryDataForFilteringFromExternalAddon == true and isJunk == nil then
                isJunk = IsItemJunk(bagId, slotIndex, isCompanionItem)
            end

--d(">found inv slot & data, isJunk: " ..tostring(isJunk))
            inventorySlot.isJunk = isJunk

            if data.dataSource ~= nil then
                data.dataSource.isJunk = isJunk
            else
                data.isJunk = isJunk
            end

            --No other junk item checks if called from external addon!
            if calledUpdateInvSlotDataEntryDataForFilteringFromExternalAddon == true then
                calledUpdateInvSlotDataEntryDataForFilteringFromExternalAddon = nil
                return
            end

            --Check the inventory for other companion items which use the same itemInstanceId, but another slotIndex,
            --and which need to be auto-junk marked because of this
            --or
            --Check the junked items for other companion items which use the same itemInstanceId, but another slotIndex,
            --and which need to be auto-un-junk marked because of this
            --Get cached items of the current bag
            if not FCOCompanion.settingsVars.settingsPerToon.autoJunkMarkSameCompanionItemsInBags then
                calledUpdateInvSlotDataEntryDataForFilteringFromExternalAddon = nil
                return
            end

            local changedItems = 0
            if bagCache == nil then
                bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagId)
            end
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
    FCOCompanion.UpdateInvSlotDataEntryDataForFiltering = updateInvSlotDataEntryDataForFiltering

    local function updateInvSlotDataAndRefreshInv(inventorySlot, isJunk, bagId, slotIndex, isCompanionItem, itemInstanceId)
        --Set flag that we have called this from internally of this addon
        calledUpdateInvSlotDataEntryDataForFilteringFromExternalAddon = false
        updateInvSlotDataEntryDataForFiltering(inventorySlot, isJunk, bagId, slotIndex, isCompanionItem, itemInstanceId)
        --Reset flag that we have called this from internally fo this addon
        calledUpdateInvSlotDataEntryDataForFilteringFromExternalAddon = nil
        --refresh the visible scroll list
        refreshInventoryToUpdateFilteredSlotData()
    end

    --Do not use an own API function FCOCompanion.SetCompanionItemIsJunk but use normal SetItemIsJunk(bagId, slotIndex, isItemJunk) instead
    local function setCompanionItemJunk(bagId, slotIndex, isJunk, isCompanionItem, itemInstanceId, inventorySlot)
        if isCompanionItem == nil or itemInstanceId == nil then
            isCompanionItem, itemInstanceId = companionItemChecks(bagId, slotIndex)
        end
--d("[FCOCompanion.SetCompanionItemJunk]" ..GetItemLink(bagId, slotIndex).." - isCompanionItem: " ..tostring(isCompanionItem) .. ", itemInstanceId: " ..tostring(itemInstanceId) .. ", isJunk: " ..tostring(isJunk))
        if isCompanionItem == true and itemInstanceId ~= nil then
            local isJunkForSavedVars = isJunk
            if isJunkForSavedVars == false then isJunkForSavedVars = nil end
            junkedCompanionItems[itemInstanceId] = isJunkForSavedVars
            PlaySound(isJunk and SOUNDS.INVENTORY_ITEM_JUNKED or SOUNDS.INVENTORY_ITEM_UNJUNKED)

            --Update the inventory slot data
            updateInvSlotDataAndRefreshInv(inventorySlot, isJunk, bagId, slotIndex, isCompanionItem, itemInstanceId)

            --d("<true")
            return true
        end
        --d("<false")
        return false
    end


    local origSetItemIsJunk = SetItemIsJunk
    function SetItemIsJunk(bagId, slotIndex, isJunk, isCompanionItem)
        local itemInstanceId
        isCompanionItem, itemInstanceId = companionItemChecks(bagId, slotIndex, isCompanionItem)
        if isCompanionItem == true and itemInstanceId ~= nil then
--d(">SetItemIsJunk - Companion item!")
            return setCompanionItemJunk(bagId, slotIndex, isJunk, isCompanionItem, itemInstanceId, nil)
        end
        --No Companion item, just call the original function SetItemIsJunk
        return origSetItemIsJunk(bagId, slotIndex, isJunk)
    end

    --Will create or read the bagCache of bagId, and check for companion items that are junked
    --if found, the callbackFunc will be called with parameters (bagId, slotIndex, ...) where ... are the additional params passed in after callbackFunc#
    --If the parameter boolean addItemData is true the passed in params to the callback function will be bagId, slotIndex, itemData, ...
    local function getBagCacheAndCheckForJunkedCompanionItemsAndCallCallback(bagId, callbackFunc, addItemData, ...)
        if bagId == nil or callbackFunc == nil or type(callbackFunc) ~= "function" then return end
        addItemData = addItemData or false

        --Get the companion items, which are junked, at the bagId now
        local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagId)
        if bagCache ~= nil then
            junkedCompanionItems = FCOCompanion.settingsVars.settingsPerToon.companionItemsJunked

            for _, itemData in pairs(bagCache) do
                local isCompanionItem, itemInstanceId
                local slotIndex = itemData.slotIndex
                local isJunk = itemData.isJunk
                if slotIndex ~= nil then
                    if isJunk == nil then
                        isJunk = IsItemJunk(bagId,slotIndex)
                    end
                    if isJunk == true then
                        if itemData.actorCategory == GAMEPLAY_ACTOR_CATEGORY_COMPANION and itemData.itemInstanceId ~= nil then
                            --Check if item is on the FCOCOmpanion junkedItem list and remove it there
                            isCompanionItem = true
                            itemInstanceId = zo_getSafeId64Key(itemData.itemInstanceId)
                        else
                            isCompanionItem, itemInstanceId = companionItemChecks(bagId, slotIndex, nil)
                        end
                        if isCompanionItem == true and itemInstanceId ~= nil then
--d(">companion item: " ..GetItemLink(bagId, slotIndex))
                            --Remove item from FCOCompanion junkedItems SavedVariables
                            if junkedCompanionItems[itemInstanceId] ~= nil then
                                junkedCompanionItems[itemInstanceId] = nil
--d(">SavedVars of companion junk item removed")
                            end
                            --Call the callback func now
--d(">Callback func call: " ..tostring(callbackFunc))
                            if addItemData == true then
                                callbackFunc(bagId, slotIndex, itemData, ...)
                            else
                                callbackFunc(bagId, slotIndex, ...)
                            end
                        end
                    end
                end
            end
        end
    end


    local origSellAllJunk = SellAllJunk
    function SellAllJunk()
--d("[FCOCO]SellAllJunk")
        --Sell the normal junk items now
        origSellAllJunk()
        --Sell possible companion junked items nows
        getBagCacheAndCheckForJunkedCompanionItemsAndCallCallback(BAG_BACKPACK, SellInventoryItem, false, 1) --param 1 = stackCount 1 = sell 1 companion item
    end
    --Assign the overwritten SellAllJunk function to the ESO dialog again, as else it won't be used
    ESO_Dialogs["SELL_ALL_JUNK"].buttons[1].callback = SellAllJunk


  --[[
    local function destroyInventoryItemBySlotControl(bagId, slotIndex, slotData)
        if slotData == nil or slotData.slotControl == nil then return end
        local inventorySlot = slotData.slotControl
        if not IsSlotLocked(inventorySlot) and ZO_InventorySlot_CanDestroyItem(inventorySlot) then
--d(">DestroyItemInit now: " ..GetItemLink(bagId, slotIndex))
            --ZO_InventorySlot_InitiateDestroyItem(inventorySlot)
        end
    end
    ]]

    local origDestroyAllJunk = DestroyAllJunk
    function DestroyAllJunk()
--d("[FCOCO]DestroyAllJunk")
        --Sell the normal junk items now
        origDestroyAllJunk()

        --Destroy possible companion junked items now
        getBagCacheAndCheckForJunkedCompanionItemsAndCallCallback(BAG_BACKPACK, DestroyItem, false)
    end
    --Assign the overwritten DestroyAllJunk function to the ESO dialog again, as else it won't be used
    ESO_Dialogs["DESTROY_ALL_JUNK"].buttons[1].callback = DestroyAllJunk



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

        if isCompanionItem == true and isJunkable == true then
--(">>isCompanionItem: " ..tostring(isCompanionItem) .. ", isJunkable: " ..tostring(isJunkable))
            local isCurrentlyJunked = IsItemJunk(bagId, slotIndex, isCompanionItem)

            if isCurrentlyJunked == false then
                --:AddSlotAction(actionStringId, actionCallback, actionType, visibilityFunction, options)
                slotActions:AddCustomSlotAction(SI_ITEM_ACTION_MARK_AS_JUNK, function()
                    if setCompanionItemJunk(bagId, slotIndex, true, isCompanionItem, itemInstanceId, slotActions.m_inventorySlot) == true then
                        --[[
                        --Update the slot so it's isJunk is set!
                        updateInvSlotDataEntryDataForFiltering(slotActions, true, bagId, slotIndex, isCompanionItem, itemInstanceId)
                        --Refresh the visible scrolllist and the slotsData properly -> Inventory refresh?
                        refreshInventoryToUpdateFilteredSlotData()
                        ]]
                    end
                end , "", nil, nil)
--d("<<!!!preventNextSameBagIdAndSlotIndexUnjunkContextMenu[" ..tostring(bagId) .. "][" ..tostring(slotIndex) .. "] = nil")
                --preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId] = preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId] or {}
                --preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId][slotIndex] = nil

            --[[
            --The slotAction is not checking the gameplay actor category at "Unmark junk"!
            --As API function SetItemIsJunk was hooked now we do not need to explicitly add a new entry for "Unmark from junk".
            --We will just reuse the vanilla jode "Remove from junk" now as the API functions will take care of the "companion item" checks
            --Even if this addon is disabled you will be able ti "unmark companion items from junk then"
            else
                slotActions:AddCustomSlotAction(SI_ITEM_ACTION_UNMARK_AS_JUNK, function()
                    if setCompanionItemJunk(bagId, slotIndex, false, isCompanionItem, itemInstanceId, slotActions.m_inventorySlot) == true then
                    end
                end , "", nil, nil)
d(">>!!!preventNextSameBagIdAndSlotIndexUnjunkContextMenu[" ..tostring(bagId) .. "][" ..tostring(slotIndex) .. "] = nil")
                --Prevent showing the "Unjunk item" entry at teh context menu slotActions -> Vanilla ESO -> Checked at function IsItemJunk!
                preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId] = preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId] or {}
                preventNextSameBagIdAndSlotIndexUnjunkContextMenu[bagId][slotIndex] = true
            ]]
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
--d("[TransferToGuildBank]guildBankId: " ..tostring(GetSelectedGuildBankId()))
            local isCompanionItem, itemInstanceId = companionItemChecks(sourceBag, sourceSlot, nil)
            if isCompanionItem and itemInstanceId ~= nil then
                if not junkedCompanionItems[itemInstanceId] then return false end
                --UnJunk the companion item
--d("<unjunked item: " ..GetItemLink(sourceBag, sourceSlot))
                junkedCompanionItems[itemInstanceId] = nil
            end
        end
        return false
    end)
end
FCOCompanion.EnableJunkCheck = enableJunkCheck