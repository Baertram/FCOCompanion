FCOCO = FCOCO or  {}
local FCOCompanion = FCOCO
if not FCOCompanion.isCompanionUnlocked then return end
------------------------------------------------------------------------------------------------------------------------

local addonVars = FCOCompanion.addonVars
local addonName = addonVars.addonName
local EM = EVENT_MANAGER

------------------------------------------------------------------------------------------------------------------------
local currentStealthState = STEALTH_STATE_NONE

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
local companionWasSummonedBefore = false
local actualCompanionDefId
local function checkForActiveCompanion()
    actualCompanionDefId = nil
    local isPending = false
    local isActive = false
    if HasPendingCompanion() then
        actualCompanionDefId = GetPendingCompanionDefId()
        isPending = true
    elseif HasActiveCompanion() == true then
        actualCompanionDefId = GetActiveCompanionDefId()
        isActive = true
    end
    return isPending, isActive
end

--Check if any other collectible has dismissed the companion.
--We need to remember the last active companion then
local function wasCompanionDismissedByOtherCollectible(collectibleId, gamePlayActorCategory)
    local isPending, isActive = checkForActiveCompanion()
--d("[FCOCO]wasCompanionDismissedByOtherCollectible-pending/active: " ..tostring(isPending).."/"..tostring(isActive)) -- .. ", actor: " ..tostring(gamePlayActorCategory))
    if isPending == true or isActive == true then
        companionWasSummonedBefore = true
    end
    return false
end

local function onCollectibleUseResult(eventId, result, isAttemptingActivation)
--d("[FCOCO]onCollectibleUseResult - result: " ..tostring(result) .. ", isAttemptingActivation: " ..tostring(isAttemptingActivation))
    if result == 0 and isAttemptingActivation == true then
        wasCompanionDismissedByOtherCollectible()
    end
end

--[[
function FCOCompanion.HideCompanionUltimate(shouldHide)
    local ultiButtonCompanion = CompanionUltimateButton
    if not ultiButtonCompanion then return end
    shouldHide = shouldHide or FCOCompanion.settingsVars.settings.hideCompanionUltimate
    local isHidden = ultiButtonCompanion:IsHidden() or false
--d("HideCompanionUltimate - isHidden: " ..tostring(isHidden) .. ", shouldHide: " ..tostring(shouldHide))
    if shouldHide ~= isHidden then
        ultiButtonCompanion:SetHidden(shouldHide)
    end
end
local hideCompanionUltimate = FCOCompanion.HideCompanionUltimate

function FCOCompanion.SetupCompanionUltimateButton()
    local shouldHide = FCOCompanion.settingsVars.settings.hideCompanionUltimate
    hideCompanionUltimate(shouldHide)
    if shouldHide == true then
        EM:RegisterForEvent(addonName .. "_EVENT_ACTION_BAR_SWITCHED", EVENT_ACTIVE_WEAPON_PAIR_CHANGED, function(eventId, activeWeaponPair, locked)
--d("[FCOCOmpanion]ActiveWeaponPairChanged to: " ..tostring(activeWeaponPair) .. ", locked: " ..tostring(locked))
            if locked == true then
                zo_callLater(function()
                    hideCompanionUltimate(shouldHide)
                end, 0)
            end
        end)
    else
        EM:UnregisterForEvent(addonName .. "_EVENT_ACTION_BAR_SWITCHED", EVENT_ACTIVE_WEAPON_PAIR_CHANGED)
    end
end
local setupCompanionUltimateButton = FCOCompanion.SetupCompanionUltimateButton
]]

--======================================================================================================================
--Player activated function
function FCOCompanion.Player_Activated(eventId, waFirst)
    --Tasks here
    FCOCompanion.UpdateCompass()

    --Update settings values for the last active companion
    local isPending, isActive = checkForActiveCompanion()
    if isPending or isActive then
        FCOCompanion.settingsVars.settings.lastCompanionId = actualCompanionDefId
    end

    --Hide/show the ultimate button
    --setupCompanionUltimateButton()


    FCOCompanion.playerActivatedDone = true
end

--======================================================================================================================
function FCOCompanion.Companion_Activated(eventId, companionId)
    if not FCOCompanion.settingsVars.settings then return end
    FCOCompanion.settingsVars.settings.companionIsSummoned = true
    FCOCompanion.settingsVars.settings.lastCompanionId = companionId
end

function FCOCompanion.Companion_DeActivated(eventId)
    if not FCOCompanion.settingsVars.settings then return end
    FCOCompanion.settingsVars.settings.companionIsSummoned = false
end


--======================================================================================================================
-- Is still ... checks
--======================================================================================================================
local lastCompanionIdBeforeCrafting
local lastCompanionIdBeforeBank
local lastCompanionIdBeforeVendor
local lastCompanionIdBeforeFish
local lastCompanionIdBeforeCrouch

local isCurrentlyCrafting = false
local isCurrentlyAtBank = false
local isCurrentlyAtVendor = false
local isCurrentlyFishing = false
local isCurrentlyCrouching = false

local function resetIsAtVars()
    isCurrentlyCrafting = false
    isCurrentlyAtBank = false
    isCurrentlyAtVendor = false
    isCurrentlyFishing = false
    isCurrentlyCrouching = false
end

local function resetLastCompanionIdVars()
    lastCompanionIdBeforeCrafting = nil
    lastCompanionIdBeforeBank = nil
    lastCompanionIdBeforeVendor = nil
    lastCompanionIdBeforeFish = nil
    lastCompanionIdBeforeCrouch = nil
end

local function isFishing()
    isCurrentlyFishing = (GetInteractionType() == INTERACTION_FISH) or false
    return isCurrentlyFishing
end
local function isCrouching()
    isCurrentlyCrouching = (currentStealthState ~= STEALTH_STATE_NONE) or false
    return isCurrentlyCrouching
end

local function isStillAtChecks()
    local settings = FCOCompanion.settingsVars.settings
    local isCraftingYet = settings.unSummonAtCraftingTables and (ZO_CraftingUtils_IsCraftingWindowOpen() or ZO_CraftingUtils_IsPerformingCraftProcess() or isCurrentlyCrafting)
    local isAtBankYet = settings.unSummonAtBanks and (IsBankOpen() or IsGuildBankOpen() or isCurrentlyAtBank)
    local isAtVendorYet = settings.unSummonAtVendors and (ZO_Store_IsShopping() or isCurrentlyAtVendor)
    local isFishingYet = settings.unSummonAtFishing and (isFishing())
    local isCrouchingYet = settings.unSummonAtCrouching and (isCrouching())
d(string.format("[isStillAtChecks]-isCraftingYet: %s, isAtBankYet: %s, isAtVendorYet: %s, isCrouchingYet: %s, isFishingYet: %s", tostring(isCraftingYet) , tostring(isAtBankYet) , tostring(isAtVendorYet) , tostring(isCrouchingYet) , tostring(isFishingYet)))
    return isCraftingYet or isAtBankYet or isAtVendorYet or isCrouchingYet or isFishingYet
end

--======================================================================================================================
-- CRAFTING
--======================================================================================================================
function FCOCompanion.CraftingTableInteract(eventId, craftSkill, sameStation)
d("[FCOCompanion]CraftingTableInteract BEGIN")
    isCurrentlyCrafting = true
    local settings = FCOCompanion.settingsVars.settings
    if not settings.unSummonAtCraftingTables then
        lastCompanionIdBeforeCrafting = nil
        return
    end
    EM:RegisterForEvent(addonName, EVENT_END_CRAFTING_STATION_INTERACT, FCOCompanion.CraftingTableInteractEnd)

    --Unsummon the companion if summoned
    local isPending, isActive = checkForActiveCompanion()
    if actualCompanionDefId ~= nil then
        if isActive then
            companionWasSummonedBefore = true
            --Companion is summoning/summoned
            --Save the last summoned ID first
            lastCompanionIdBeforeCrafting = actualCompanionDefId
            --Unsummon it now
            FCOCompanion.ToggleCompanion(lastCompanionIdBeforeCrafting, false, true)
        elseif isPending then
            companionWasSummonedBefore = true
            EM:RegisterForEvent(addonVars.addonName .. "_CraftingTable", EVENT_COMPANION_ACTIVATED, function()
d(">companion summon finished after crafting table was opened")
                EM:UnregisterForEvent(addonVars.addonName .. "_CraftingTable", EVENT_COMPANION_ACTIVATED)
                --Check if we are not doing something that will unsummon the companion
                if not isStillAtChecks() then
d("<<not crafting anymore!")
                    resetIsAtVars()
                    lastCompanionIdBeforeCrafting = nil
                    return
                end
                --Companion is summoning/summoned
                --Save the last summoned ID first
                lastCompanionIdBeforeCrafting = actualCompanionDefId
                --Unsummon it now
                FCOCompanion.ToggleCompanion(lastCompanionIdBeforeCrafting, false, true)
            end)
        end
    end
end

local function setupCraftEndTimerCallback()
d("setupCraftEndTimerCallback")
    local eventUpdateNameCraft = addonName .. "_ReSummon"
    EM:UnregisterForUpdate(eventUpdateNameCraft)

    if lastCompanionIdBeforeCrafting == nil or companionWasSummonedBefore == false then return end
    local settings = FCOCompanion.settingsVars.settings
    if not settings.reSummonAfterCraftingTables then return end

    local function callbackFunc()
        EM:UnregisterForUpdate(eventUpdateNameCraft)

        --Check if we are still at a craft table, bank, vendor, fishing or crouching and if this is enabled in settings
        --to unsumon the companion: We do not need to re-summon it then
        local isCompanionUnsummonTaskDone = isStillAtChecks()
d(">callbackFunc - setupCraftEndTimerCallback. isStillCrafting: " ..tostring(isCompanionUnsummonTaskDone))
        if isCompanionUnsummonTaskDone == true then return end

        --Re-Summon the last known companion
        FCOCompanion.ToggleCompanion(lastCompanionIdBeforeCrafting, true, true)
        lastCompanionIdBeforeCrafting = nil
        companionWasSummonedBefore = false
    end


    local delay = settings.reSummonAfterCraftingTablesDelay
    if delay <= 0 then
        callbackFunc()
        return
    end

    EM:RegisterForUpdate(eventUpdateNameCraft, delay, callbackFunc)
end


local function OnCraftingEnded(craftSkill)
d("OnCraftingEnded")
    resetIsAtVars()
    local settings = FCOCompanion.settingsVars.settings
    if not settings.unSummonAtCraftingTables or not settings.reSummonAfterCraftingTables or lastCompanionIdBeforeCrafting == nil then
        lastCompanionIdBeforeCrafting = nil
        return
    end
    --Get the last active companion ID (from settings, as it could be despawned by the banker "non-combat collection pet"
    --before the bank was opened
    if lastCompanionIdBeforeCrafting == nil then
        if companionWasSummonedBefore == true and settings.lastCompanionId ~= nil then
            lastCompanionIdBeforeCrafting = settings.lastCompanionId
        else
            return
        end
    end

    --Summon the last summoned companion again now -> Start a timer delayed via the settings slider "delay re-summon after fish"
    setupCraftEndTimerCallback()
end


function FCOCompanion.CraftingTableInteractEnd(eventId, craftSkill)
d("[FCOCompanion]CraftingTableInteract END - lastCompanionIdBeforeCrafting: " ..tostring(lastCompanionIdBeforeCrafting))
    --[[
    local settings = FCOCompanion.settingsVars.settings
    if not settings.unSummonAtCraftingTables or not settings.reSummonAfterCraftingTables or lastCompanionIdBeforeCrafting == nil then
        lastCompanionIdBeforeCrafting = nil
        return
    end
    --Summon the last summoned companion again now
    FCOCompanion.ToggleCompanion(lastCompanionIdBeforeCrafting, true, true)
    lastCompanionIdBeforeCrafting = nil
    companionWasSummonedBefore = false
    ]]
    EM:UnregisterForEvent(addonName, EVENT_END_CRAFTING_STATION_INTERACT)
    OnCraftingEnded(craftSkill)
end


--======================================================================================================================
-- BANK
--======================================================================================================================
function FCOCompanion.BankInteract(eventId, bankBagId, isGuildBankBag)
d("[FCOCompanion]BankInteract BEGIN")
    isCurrentlyAtBank = true
    local settings = FCOCompanion.settingsVars.settings
    if not settings.unSummonAtBanks then
        lastCompanionIdBeforeBank = nil
        return
    end
    isGuildBankBag = isGuildBankBag or ((bankBagId == BAG_GUILDBANK) or false)
    local eventIdForBankClose = isGuildBankBag and EVENT_CLOSE_GUILD_BANK or EVENT_CLOSE_BANK
    EM:RegisterForEvent(addonName, eventIdForBankClose, function() FCOCompanion.BankInteractEnd(eventIdForBankClose, isGuildBankBag) end)

    --Unsummon the companion if summoned
    local isPending, isActive = checkForActiveCompanion()
    if actualCompanionDefId ~= nil then
        if isActive then
            companionWasSummonedBefore = true
            --Companion is summoning/summoned
            --Save the last summoned ID first
            lastCompanionIdBeforeBank = actualCompanionDefId
            --Unsummon it now
            FCOCompanion.ToggleCompanion(lastCompanionIdBeforeBank, false, true)
        elseif isPending then
            companionWasSummonedBefore = true
            EM:RegisterForEvent(addonVars.addonName .. "_Bank", EVENT_COMPANION_ACTIVATED, function()
d(">companion summon finished after bank was opened")
                EM:UnregisterForEvent(addonVars.addonName .. "_Bank", EVENT_COMPANION_ACTIVATED)
                --Check if we are not doing something that will unsummon the companion
                if not isStillAtChecks() then
d("<<not at bank anymore!")
                    resetIsAtVars()
                    lastCompanionIdBeforeBank = nil
                    return
                end
                --Companion is summoning/summoned
                --Save the last summoned ID first
                lastCompanionIdBeforeBank = actualCompanionDefId
                --Unsummon it now
                FCOCompanion.ToggleCompanion(lastCompanionIdBeforeBank, false, true)
            end)
        end
    end
end

local function setupBankEndTimerCallback()
d("setupBankEndTimerCallback")
    local eventUpdateNameBank = addonName .. "_ReSummon"
    EM:UnregisterForUpdate(eventUpdateNameBank)

    if lastCompanionIdBeforeBank == nil or companionWasSummonedBefore == false then
d(">abort bank end timer 1")
        return
    end
    local settings = FCOCompanion.settingsVars.settings
    if not settings.reSummonAfterBanks then return end

    local function callbackFunc()
        EM:UnregisterForUpdate(eventUpdateNameBank)

        --Check if we are still at a craft table, bank, vendor, fishing or crouching and if this is enabled in settings
        --to unsumon the companion: We do not need to re-summon it then
        local isCompanionUnsummonTaskDone = isStillAtChecks()
d(">callbackFunc - setupBankEndTimerCallback. isStillAtABank: " ..tostring(isCompanionUnsummonTaskDone))
        if isCompanionUnsummonTaskDone then return true end

        --Re-Summon the last known companion
        FCOCompanion.ToggleCompanion(lastCompanionIdBeforeBank, true, true)
        lastCompanionIdBeforeBank = nil
        companionWasSummonedBefore = false
    end


    local delay = settings.reSummonAfterBanksDelay
    if delay <= 0 then
        callbackFunc()
        return
    end

    EM:RegisterForUpdate(eventUpdateNameBank, delay, callbackFunc)
end


GetJournalQuestName()

local function OnBankEnded()
d("OnBankEnded")
    isCurrentlyAtBank = false
    local settings = FCOCompanion.settingsVars.settings
    if not settings.unSummonAtBanks or not settings.reSummonAfterBanks or lastCompanionIdBeforeBank == nil then
        lastCompanionIdBeforeBank = nil
d(">abort bank1")
        return
    end
    --Get the last active companion ID (from settings, as it could be despawned by the banker "non-combat collection pet"
    --before the bank was opened
    if lastCompanionIdBeforeBank == nil then
        if companionWasSummonedBefore == true and settings.lastCompanionId ~= nil then
            lastCompanionIdBeforeBank = settings.lastCompanionId
        else
d(">abort bank2")
            return
        end
    end

    --Summon the last summoned companion again now -> Start a timer delayed via the settings slider "delay re-summon after fish"
    setupBankEndTimerCallback()
end

function FCOCompanion.BankInteractEnd(eventId, isGuildBankBag)
d("[FCOCompanion]BankInteract END - lastCompanionIdBeforeBank: " ..tostring(lastCompanionIdBeforeBank))
    --[[
    local settings = FCOCompanion.settingsVars.settings
    if not settings.unSummonAtBanks or not settings.reSummonAfterBanks then
        lastCompanionIdBeforeBank = nil
        return
    end
    --Get the last active companion ID (from settings, as it could be despawned by the banker "non-combat collection pet"
    --before the bank was opened
    if lastCompanionIdBeforeBank == nil then
        if companionWasSummonedBefore == true and settings.lastCompanionId ~= nil then
            lastCompanionIdBeforeBank = settings.lastCompanionId
        else
            return
        end
    end

    --Summon the last summoned companion again now
    FCOCompanion.ToggleCompanion(lastCompanionIdBeforeBank, true, true)
    lastCompanionIdBeforeBank = nil
    companionWasSummonedBefore = false
    ]]
    local eventIdForBankClose = isGuildBankBag and EVENT_CLOSE_GUILD_BANK or EVENT_CLOSE_BANK
    EM:UnregisterForEvent(addonName, eventIdForBankClose)
    OnBankEnded()
end


--======================================================================================================================
-- VENDOR
--======================================================================================================================
function FCOCompanion.VendorInteract(eventId, allowSell, allowLaunder)
d("[FCOCompanion]VendorInteract BEGIN")
    isCurrentlyAtVendor = true
    local settings = FCOCompanion.settingsVars.settings
    if not settings.unSummonAtVendors then
        lastCompanionIdBeforeVendor = nil
        return
    end
    EM:RegisterForEvent(addonName, EVENT_CLOSE_STORE, FCOCompanion.VendorInteractEnd)

    --Unsummon the companion if summoned
    local isPending, isActive = checkForActiveCompanion()
    if actualCompanionDefId ~= nil then
        if isActive then
            companionWasSummonedBefore = true
            --Companion is summoning/summoned
            --Save the last summoned ID first
            lastCompanionIdBeforeVendor = actualCompanionDefId
            --Unsummon it now
            FCOCompanion.ToggleCompanion(lastCompanionIdBeforeVendor, false, true)
        elseif isPending then
            companionWasSummonedBefore = true
            EM:RegisterForEvent(addonVars.addonName .. "_Vendor", EVENT_COMPANION_ACTIVATED, function()
d(">companion summon finished after vendor was opened")
                EM:UnregisterForEvent(addonVars.addonName .. "_Vendor", EVENT_COMPANION_ACTIVATED)
                --Check if we are not doing something that will unsummon the companion
                if not isStillAtChecks() then
d("<<not at vendor anymore!")
                    resetIsAtVars()
                    lastCompanionIdBeforeVendor = nil
                    return
                end
                --Companion is summoning/summoned
                --Save the last summoned ID first
                lastCompanionIdBeforeVendor = actualCompanionDefId
                --Unsummon it now
                FCOCompanion.ToggleCompanion(lastCompanionIdBeforeVendor, false, true)
            end)
        end
    end
end

local function setupVendorEndTimerCallback()
d("setupVendorEndTimerCallback")
    local eventUpdateNameVendor = addonName .. "_ReSummon"
    EM:UnregisterForUpdate(eventUpdateNameVendor)

    if lastCompanionIdBeforeVendor == nil or companionWasSummonedBefore == false then return end
    local settings = FCOCompanion.settingsVars.settings
    if not settings.reSummonAfterVendors then return end

    local function callbackFunc()
        EM:UnregisterForUpdate(eventUpdateNameVendor)

        --Check if we are still at a craft table, bank, vendor, fishing or crouching and if this is enabled in settings
        --to unsumon the companion: We do not need to re-summon it then
        local isCompanionUnsummonTaskDone = isStillAtChecks()
d(">callbackFunc - setupVendorEndTimerCallback. isStillAtAVendor: " ..tostring(isCompanionUnsummonTaskDone))
        if isCompanionUnsummonTaskDone then return true end

        --Re-Summon the last known companion
        FCOCompanion.ToggleCompanion(lastCompanionIdBeforeVendor, true, true)
        lastCompanionIdBeforeVendor = nil
        companionWasSummonedBefore = false
    end


    local delay = settings.reSummonAfterVendorsDelay
    if delay <= 0 then
        callbackFunc()
        return
    end

    EM:RegisterForUpdate(eventUpdateNameVendor, delay, callbackFunc)
end


local function OnVendorEnded()
d("OnVendorEnded")
    isCurrentlyAtVendor = false
    local settings = FCOCompanion.settingsVars.settings
    if not settings.unSummonAtVendors or not settings.reSummonAfterVendors or lastCompanionIdBeforeVendor == nil then
        lastCompanionIdBeforeVendor = nil
        return
    end
    --Get the last active companion ID (from settings, as it could be despawned by the banker "non-combat collection pet"
    --before the bank was opened
    if lastCompanionIdBeforeVendor == nil then
        if companionWasSummonedBefore == true and settings.lastCompanionId ~= nil then
            lastCompanionIdBeforeVendor = settings.lastCompanionId
        else
            return
        end
    end

    --Summon the last summoned companion again now -> Start a timer delayed via the settings slider "delay re-summon after fish"
    setupVendorEndTimerCallback()
end

function FCOCompanion.VendorInteractEnd(eventId)
d("[FCOCompanion]VendorInteract END - lastCompanionIdBeforeVendor: " ..tostring(lastCompanionIdBeforeVendor))
    --[[
    local settings = FCOCompanion.settingsVars.settings
    if not settings.unSummonAtVendors or not settings.reSummonAfterVendors then
        lastCompanionIdBeforeVendor = nil
        return
    end
    --Get the last active companion ID (from settings, as it could be despawned by the banker "non-combat collection pet"
    --before the bank was opened
    if lastCompanionIdBeforeVendor == nil then
        if companionWasSummonedBefore == true and settings.lastCompanionId ~= nil then
            lastCompanionIdBeforeVendor = settings.lastCompanionId
        else
            return
        end
    end

    --Summon the last summoned companion again now
    FCOCompanion.ToggleCompanion(lastCompanionIdBeforeVendor, true, true)
    lastCompanionIdBeforeVendor = nil
    companionWasSummonedBefore = false
    ]]
    EM:UnregisterForEvent(addonName, EVENT_CLOSE_STORE)
    OnVendorEnded()
end


--======================================================================================================================
-- FISHING
--======================================================================================================================
local wasFishing = false

local function OnStartInteraction()
    zo_callLater(function()

        wasFishing = false
        isFishing()
d("InteractionManager:StartInteraction - isCurrentlyFishing: " ..tostring(isCurrentlyFishing))
        if not isCurrentlyFishing then return end

        wasFishing = true
        --local action, interactableName, interactionBlocked, isOwned, additionalInteractInfo, context, contextLink, isCriminalInteract = GetGameCameraInteractableActionInfo()
        --if additionalInteractInfo == ADDITIONAL_INTERACT_INFO_FISHING_NODE and not interactionBlocked then
        --d(">action: " ..tostring(action) .. ", interactableName: " ..tostring(interactableName) .. ", interactionBlocked: " .. tostring(interactionBlocked) .. ", isOwned: " .. tostring(isOwned) .. ", context: " ..tostring(context) .. ", contextLink: " ..tostring(contextLink))
            local settings = FCOCompanion.settingsVars.settings
            if not settings.unSummonAtFishing then
                lastCompanionIdBeforeFish = nil
                return
            end

            --Any lure selected or do we actually start fishing by selecting a lure?
            --if GetFishingLure() == 0 then return end

            --Unsummon the companion if summoned
            local isPending, isActive = checkForActiveCompanion()
            if actualCompanionDefId ~= nil then
                if isActive then
                    companionWasSummonedBefore = true
                    --Companion is summoning/summoned
                    --Save the last summoned ID first
                    lastCompanionIdBeforeFish = actualCompanionDefId
                    --Unsummon it now
                    FCOCompanion.ToggleCompanion(lastCompanionIdBeforeFish, false, true)
                elseif isPending then
                    companionWasSummonedBefore = true
                    EM:RegisterForEvent(addonVars.addonName .. "_Fish", EVENT_COMPANION_ACTIVATED, function()
                        --d(">companion summon finished after fishing was started")
                        EM:UnregisterForEvent(addonVars.addonName .. "_Fish", EVENT_COMPANION_ACTIVATED)
                        --Check if we are not doing something that will unsummon the companion
                        if not isStillAtChecks() then
                            --d("<<not fishing anymore!")
                            resetIsAtVars()
                            lastCompanionIdBeforeFish = nil
                            return
                        end
                        --Companion is summoning/summoned
                        --Save the last summoned ID first
                        lastCompanionIdBeforeFish = actualCompanionDefId
                        --Unsummon it now
                        FCOCompanion.ToggleCompanion(lastCompanionIdBeforeFish, false, true)
                    end)
                end
            end
        --end

    end, 1000)
end

local function setupFishEndTimerCallback()
d("setupFishEndTimerCallback")
    local eventUpdateNameFish = addonName .. "_ReSummon"
    EM:UnregisterForUpdate(eventUpdateNameFish)

    if lastCompanionIdBeforeFish == nil or companionWasSummonedBefore == false then return end
    local settings = FCOCompanion.settingsVars.settings
    if not settings.reSummonAfterFishing then return end

    local function callbackFunc()
        EM:UnregisterForUpdate(eventUpdateNameFish)

        --Check if we are still at a craft table, bank, vendor, fishing or crouching and if this is enabled in settings
        --to unsumon the companion: We do not need to re-summon it then
        local isCompanionUnsummonTaskDone = isStillAtChecks()
d(">callbackFunc - setupFishEndTimerCallback. isStillFishing: " ..tostring(isCompanionUnsummonTaskDone))
        if isCompanionUnsummonTaskDone == true then return end

        --Re-Summon the last known companion
        FCOCompanion.ToggleCompanion(lastCompanionIdBeforeFish, true, true)
        lastCompanionIdBeforeFish = nil
        companionWasSummonedBefore = false
    end


    local delay = settings.reSummonAfterFishingDelay
    if delay <= 0 then
        callbackFunc()
        return
    end

    EM:RegisterForUpdate(eventUpdateNameFish, delay, callbackFunc)
end

local function OnEventInteractionEnded(eventId, interactType, cancelContext)
d("[FCOCO]OnEventInteractionEnded - interactType: " ..tostring(interactType) .. ", wasFishing: " ..tostring(wasFishing))
    --InteractType is FISH if you abort fishig or get no loot. It will be LOOT if something was looted
    --Could also happen if something else was looted! Or fishing was ended and after that somethign else was looted
    if interactType == INTERACTION_LOOT then
        if not wasFishing then return end
    elseif interactType ~= INTERACTION_FISH then
        return
    end
    wasFishing = false

    local settings = FCOCompanion.settingsVars.settings
    if not settings.unSummonAtFishing or not settings.reSummonAfterFishing then
        lastCompanionIdBeforeFish = nil
        return
    end
    --Get the last active companion ID (from settings, as it could be despawned by the banker "non-combat collection pet"
    --before the bank was opened
    if lastCompanionIdBeforeFish == nil then
        if companionWasSummonedBefore == true and settings.lastCompanionId ~= nil then
            lastCompanionIdBeforeFish = settings.lastCompanionId
        else
            return
        end
    end

    --Summon the last summoned companion again now -> Start a timer delayed via the settings slider "delay re-summon after fish"
    setupFishEndTimerCallback()
end


--======================================================================================================================
-- CROUCHING
--======================================================================================================================
local function setupCrouchEndTimerCallback()
d("setupCrouchEndTimerCallback")
    local eventUpdateNameCrouch = addonName .. "_ReSummon"
    EM:UnregisterForUpdate(eventUpdateNameCrouch)

    if lastCompanionIdBeforeCrouch == nil or companionWasSummonedBefore == false then return end
    local settings = FCOCompanion.settingsVars.settings
    if not settings.reSummonAfterCrouching then return end

    local function callbackFunc()
        EM:UnregisterForUpdate(eventUpdateNameCrouch)

        --Check if we are still at a craft table, bank, vendor, fishing or crouching and if this is enabled in settings
        --to unsumon the companion: We do not need to re-summon it then
        local isCompanionUnsummonTaskDone = isStillAtChecks()
d(">callbackFunc - setupCrouchEndTimerCallback. isStillCrouching: " ..tostring(isCompanionUnsummonTaskDone))
        if isCompanionUnsummonTaskDone == true then return end

        --Re-Summon the last known companion
        FCOCompanion.ToggleCompanion(lastCompanionIdBeforeCrouch, true, true)
        lastCompanionIdBeforeCrouch = nil
        companionWasSummonedBefore = false
    end


    local delay = settings.reSummonAfterCrouchingDelay
    if delay <= 0 then
        callbackFunc()
        return
    end

    EM:RegisterForUpdate(eventUpdateNameCrouch, delay, callbackFunc)
end

local function OnCrouchingStart()
    local isInCombat = IsUnitInCombat("player")
d(">crouching start - isInCombat: " ..tostring(isInCombat))

    local settings = FCOCompanion.settingsVars.settings
    if not settings.unSummonAtCrouching then
        lastCompanionIdBeforeCrouch = nil
        return
    end
    --Only dismiss if not in combat?
    if not settings.unSummonAtCrouchingNoCombat and isInCombat then
        lastCompanionIdBeforeCrouch = nil
        return
    end

    --Unsummon the companion if summoned
    local isPending, isActive = checkForActiveCompanion()
    if actualCompanionDefId ~= nil then
        if isActive then
            companionWasSummonedBefore = true
            --Companion is summoning/summoned
            --Save the last summoned ID first
            lastCompanionIdBeforeCrouch = actualCompanionDefId
d(">unsummon companion: " ..tostring(lastCompanionIdBeforeCrouch))
            --Unsummon it now
            FCOCompanion.ToggleCompanion(lastCompanionIdBeforeCrouch, false, true)
        elseif isPending then
            companionWasSummonedBefore = true
            EM:RegisterForEvent(addonVars.addonName .. "_Crouch", EVENT_COMPANION_ACTIVATED, function()
d(">companion summon finished after croching was started")
                EM:UnregisterForEvent(addonVars.addonName .. "_Crouch", EVENT_COMPANION_ACTIVATED)
                --Check if we are not doing something that will unsummon the companion
                if not isStillAtChecks() then
                    lastCompanionIdBeforeCrouch = nil
                    return
                end
d(">>dismissing now as we are crouching")
                --Companion is summoning/summoned
                --Save the last summoned ID first
                lastCompanionIdBeforeCrouch = actualCompanionDefId
                --Unsummon it now
                FCOCompanion.ToggleCompanion(lastCompanionIdBeforeCrouch, false, true)
            end)
        end
    end
end

local function OnCrouchingEnded()
d("OnCrouchingEnded")
    local settings = FCOCompanion.settingsVars.settings
    if not settings.unSummonAtCrouching or not settings.reSummonAfterCrouching then
        lastCompanionIdBeforeCrouch = nil
        return
    end
    --Get the last active companion ID (from settings, as it could be despawned by the banker "non-combat collection pet"
    --before the bank was opened
    if lastCompanionIdBeforeCrouch == nil then
        if companionWasSummonedBefore == true and settings.lastCompanionId ~= nil then
            lastCompanionIdBeforeCrouch = settings.lastCompanionId
        else
            return
        end
    end

    --Summon the last summoned companion again now -> Start a timer delayed via the settings slider "delay re-summon after fish"
    setupCrouchEndTimerCallback()
end

--The stealth state changed
--[[
* STEALTH_STATE_DETECTED
* STEALTH_STATE_HIDDEN
* STEALTH_STATE_HIDDEN_ALMOST_DETECTED
* STEALTH_STATE_HIDING
* STEALTH_STATE_NONE
* STEALTH_STATE_STEALTH
* STEALTH_STATE_STEALTH_ALMOST_DETECTED
]]
local function OnStealthStateChanged(eventId, unitTag, newStealthState)
    currentStealthState = newStealthState
--[[
    local stealtStates = {
        [STEALTH_STATE_DETECTED] = "STEALTH_STATE_DETECTED",
        [STEALTH_STATE_HIDDEN] = "STEALTH_STATE_HIDDEN",
        [STEALTH_STATE_HIDDEN_ALMOST_DETECTED] = "STEALTH_STATE_HIDDEN_ALMOST_DETECTED",
        [STEALTH_STATE_HIDING] = "STEALTH_STATE_HIDING",
        [STEALTH_STATE_NONE] = "STEALTH_STATE_NONE",
        [STEALTH_STATE_STEALTH] = "STEALTH_STATE_STEALTH",
        [STEALTH_STATE_STEALTH_ALMOST_DETECTED] = "STEALTH_STATE_STEALTH_ALMOST_DETECTED",
    }
    local newStealthStateText = stealtStates[newStealthState] or "n/a"
]]
d("Stealth state - " ..tostring(newStealthState) .." / " ..tostring(newStealthStateText))
    local stealthStatesToHideCompanion = {
        [STEALTH_STATE_NONE]                    = false,
        [STEALTH_STATE_DETECTED]                = false,
        [STEALTH_STATE_HIDING]                  = false,
        [STEALTH_STATE_HIDDEN]                  = true,
        [STEALTH_STATE_HIDDEN_ALMOST_DETECTED]  = false,
        [STEALTH_STATE_STEALTH]                 = false,
        [STEALTH_STATE_STEALTH_ALMOST_DETECTED] = false,
    }
    local hideCompanionNow = stealthStatesToHideCompanion[newStealthState] or false
    if newStealthState == STEALTH_STATE_NONE then
        OnCrouchingEnded()
    elseif hideCompanionNow == true then
        OnCrouchingStart()
    end
end

function FCOCompanion.addonLoaded(eventName, addon)
    --[[
    if addon == "PerfectPixel" then
        FCOCompanion.otherAddons[addon] = true
    end
    ]]
    if addon ~= addonVars.addonName then return end
    EM:UnregisterForEvent(eventName)

    --Save original functions

    --Get the SavedVariables
    FCOCompanion.getSettings()

    --Libraries
    --

    --Build the LAM settings panel
    FCOCompanion.buildAddonMenu()

    --Hooks
    --Not working???
    --ZO_PreHook("UseCollectible", wasCompanionDismissedByOtherCollectible)

    --Fishing Start
    SecurePostHook(FISHING_MANAGER, "StartInteraction", OnStartInteraction)

    --EVENTS
    EM:RegisterForEvent(addonName, EVENT_PLAYER_ACTIVATED, FCOCompanion.Player_Activated)
    EM:RegisterForEvent(addonName, EVENT_COMPANION_ACTIVATED, FCOCompanion.Companion_Activated)
    EM:RegisterForEvent(addonName, EVENT_COMPANION_DEACTIVATED, FCOCompanion.Companion_DeActivated)
    --Crafting tables
    EM:RegisterForEvent(addonName, EVENT_CRAFTING_STATION_INTERACT, FCOCompanion.CraftingTableInteract)
    --Banks & Guild Banks
    EM:RegisterForEvent(addonName, EVENT_OPEN_BANK, function(eventId, bankingBagId) FCOCompanion.BankInteract(eventId, bankingBagId) end)
    EM:RegisterForEvent(addonName, EVENT_OPEN_GUILD_BANK, function(eventId) FCOCompanion.BankInteract(eventId, BAG_GUILDBANK) end)
    --Vendors
    EM:RegisterForEvent(addonName, EVENT_OPEN_STORE, FCOCompanion.VendorInteract)
    EM:RegisterForEvent(addonName, EVENT_OPEN_FENCE, FCOCompanion.VendorInteract)
    --Collectibles
    EM:RegisterForEvent(addonName, EVENT_COLLECTIBLE_USE_RESULT, onCollectibleUseResult)
    --Fishing End
    EM:RegisterForEvent(addonName, EVENT_INTERACTION_ENDED , OnEventInteractionEnded)
    --Crouching / Stealth
    EM:RegisterForEvent(addonName .. "_STEALTH_STATE_CHANGED", EVENT_STEALTH_STATE_CHANGED, OnStealthStateChanged)
    EM:AddFilterForEvent(addonName .. "_STEALTH_STATE_CHANGED", EVENT_STEALTH_STATE_CHANGED, REGISTER_FILTER_UNIT_TAG, "player")
end


function FCOCompanion.initialize()
    EM:RegisterForEvent(addonName, EVENT_ADD_ON_LOADED, FCOCompanion.addonLoaded)
end

------------------------------------------------------------------------------------------------------------------------
--Load the addon
if not FCOCompanion.isCompanionUnlocked then return end
FCOCompanion.initialize()



