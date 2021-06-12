FCOCO = FCOCO or  {}
local FCOCompanion = FCOCO
if not FCOCompanion.isCompanionUnlocked then return end
------------------------------------------------------------------------------------------------------------------------

local addonVars = FCOCompanion.addonVars
local EM = EVENT_MANAGER

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

--Player activated function
function FCOCompanion.Player_Activated(eventId, waFirst)
    --Tasks here
    FCOCompanion.UpdateCompass()

    --Update settings values for the last active companion
    local isPending, isActive = checkForActiveCompanion()
    if isPending or isActive then
        FCOCompanion.settingsVars.settings.lastCompanionId = actualCompanionDefId
    end

    FCOCompanion.playerActivatedDone = true
end

function FCOCompanion.Companion_Activated(eventId, companionId)
    if not FCOCompanion.settingsVars.settings then return end
    FCOCompanion.settingsVars.settings.companionIsSummoned = true
    FCOCompanion.settingsVars.settings.lastCompanionId = companionId
end

function FCOCompanion.Companion_DeActivated(eventId)
    if not FCOCompanion.settingsVars.settings then return end
    FCOCompanion.settingsVars.settings.companionIsSummoned = false
end

local lastCompanionIdBeforeCrafting
function FCOCompanion.CraftingTableInteract(eventId, craftSkill, sameStation)
--d("[FCOCompanion]CraftingTableInteract BEGIN")
    local settings = FCOCompanion.settingsVars.settings
    if not settings.unSummonAtCraftingTables then
        lastCompanionIdBeforeCrafting = nil
        return
    end
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
--d(">companion summon finished after crafting table was opened")
                EM:UnregisterForEvent(addonVars.addonName .. "_CraftingTable", EVENT_COMPANION_ACTIVATED)
                --Check if we are still at a crafting table
                if not ZO_CraftingUtils_IsCraftingWindowOpen() and not ZO_CraftingUtils_IsPerformingCraftProcess() then
--d("<<not crafting anymore!")
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

function FCOCompanion.CraftingTableInteractEnd(eventId, craftSkill)
    local settings = FCOCompanion.settingsVars.settings
--d("[FCOCompanion]CraftingTableInteract END - lastCompanionIdBeforeCrafting: " ..tostring(lastCompanionIdBeforeCrafting))
    if not settings.unSummonAtCraftingTables or not settings.reSummonAfterCraftingTables or lastCompanionIdBeforeCrafting == nil then
        lastCompanionIdBeforeCrafting = nil
        return
    end
    --Summon the last summoned companion again now
    FCOCompanion.ToggleCompanion(lastCompanionIdBeforeCrafting, true, true)
    lastCompanionIdBeforeCrafting = nil
    companionWasSummonedBefore = false
end

local lastCompanionIdBeforeBank
function FCOCompanion.BankInteract(eventId, bankBagId)
--d("[FCOCompanion]BankInteract BEGIN")
    local settings = FCOCompanion.settingsVars.settings
    if not settings.unSummonAtBanks then
        lastCompanionIdBeforeBank = nil
        return
    end
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
--d(">companion summon finished after bank was opened")
                EM:UnregisterForEvent(addonVars.addonName .. "_Bank", EVENT_COMPANION_ACTIVATED)
                --Check if we are still at a bank
                if not IsBankOpen() and not IsGuildBankOpen() then
--d("<<not at bank anymore!")
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

function FCOCompanion.BankInteractEnd(eventId)
    local settings = FCOCompanion.settingsVars.settings
--d("[FCOCompanion]BankInteract END - lastCompanionIdBeforeBank: " ..tostring(lastCompanionIdBeforeBank))
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
end

local lastCompanionIdBeforeVendor
function FCOCompanion.VendorInteract(eventId, allowSell, allowLaunder)
--d("[FCOCompanion]VendorInteract BEGIN")
    local settings = FCOCompanion.settingsVars.settings
    if not settings.unSummonAtVendors then
        lastCompanionIdBeforeVendor = nil
        return
    end
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
--d(">companion summon finished after vendor was opened")
                EM:UnregisterForEvent(addonVars.addonName .. "_Vendor", EVENT_COMPANION_ACTIVATED)
                --Check if we are still at a vendor
                if not ZO_Store_IsShopping() then
--d("<<not at vendor anymore!")
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

function FCOCompanion.VendorInteractEnd(eventId)
    local settings = FCOCompanion.settingsVars.settings
--d("[FCOCompanion]VendorInteract END - lastCompanionIdBeforeVendor: " ..tostring(lastCompanionIdBeforeVendor))
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
end

local function onCollectibleUseResult(eventId, result, isAttemptingActivation)
--d("[FCOCO]onCollectibleUseResult - result: " ..tostring(result) .. ", isAttemptingActivation: " ..tostring(isAttemptingActivation))
    if result == 0 and isAttemptingActivation == true then
        wasCompanionDismissedByOtherCollectible()
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

    --EVENTS
    EM:RegisterForEvent(addonVars.addonName, EVENT_PLAYER_ACTIVATED, FCOCompanion.Player_Activated)
    EM:RegisterForEvent(addonVars.addonName, EVENT_COMPANION_ACTIVATED, FCOCompanion.Companion_Activated)
    EM:RegisterForEvent(addonVars.addonName, EVENT_COMPANION_DEACTIVATED, FCOCompanion.Companion_DeActivated)
    --Crafting tables
    EM:RegisterForEvent(addonVars.addonName, EVENT_CRAFTING_STATION_INTERACT, FCOCompanion.CraftingTableInteract)
    EM:RegisterForEvent(addonVars.addonName, EVENT_END_CRAFTING_STATION_INTERACT, FCOCompanion.CraftingTableInteractEnd)
    --Banks & Guild Banks
    EM:RegisterForEvent(addonVars.addonName, EVENT_OPEN_BANK, FCOCompanion.BankInteract)
    EM:RegisterForEvent(addonVars.addonName, EVENT_CLOSE_BANK, FCOCompanion.BankInteractEnd)
    EM:RegisterForEvent(addonVars.addonName, EVENT_OPEN_GUILD_BANK, FCOCompanion.BankInteract)
    EM:RegisterForEvent(addonVars.addonName, EVENT_CLOSE_GUILD_BANK, FCOCompanion.BankInteractEnd)
    --Vendors
    EM:RegisterForEvent(addonVars.addonName, EVENT_OPEN_STORE, FCOCompanion.VendorInteract)
    EM:RegisterForEvent(addonVars.addonName, EVENT_OPEN_FENCE, FCOCompanion.VendorInteract)
    EM:RegisterForEvent(addonVars.addonName, EVENT_CLOSE_STORE, FCOCompanion.VendorInteractEnd)
    --Collectibles
    EM:RegisterForEvent(addonVars.addonName, EVENT_COLLECTIBLE_USE_RESULT, onCollectibleUseResult)
end


function FCOCompanion.initialize()
    EM:RegisterForEvent(addonVars.addonName, EVENT_ADD_ON_LOADED, FCOCompanion.addonLoaded)
end

------------------------------------------------------------------------------------------------------------------------
--Load the addon
if not FCOCompanion.isCompanionUnlocked then return end
FCOCompanion.initialize()
