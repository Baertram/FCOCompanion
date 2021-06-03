FCOCO = FCOCO or  {}
local FCOCompanion = FCOCO
if not FCOCompanion.isCompanionUnlocked then return end
------------------------------------------------------------------------------------------------------------------------

local addonVars = FCOCompanion.addonVars
local EM = EVENT_MANAGER

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

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

--Player activated function
function FCOCompanion.Player_Activated(eventId, waFirst)
    --Tasks here

    --Update settings values for the last active companion
    local isPending, isActive = checkForActiveCompanion()
    if isPending or isActive then
        FCOCompanion.settingsVars.settings.lastCompanionId = actualCompanionDefId
    end

    FCOCompanion.playerActivatedDone = true
end

function FCOCompanion.Companion_Activated(eventId, companionId)
    if not FCOCompanion.settingsVars.settings then return end
    FCOCompanion.settingsVars.settings.lastCompanionId = companionId
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
            --Companion is summoning/summoned
            --Save the last summoned ID first
            lastCompanionIdBeforeCrafting = actualCompanionDefId
            --Unsummon it now
            FCOCompanion.ToggleCompanion(lastCompanionIdBeforeCrafting, false, true)
        elseif isPending then
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

    --EVENTS
    EM:RegisterForEvent(addonVars.addonName, EVENT_PLAYER_ACTIVATED, FCOCompanion.Player_Activated)
    EM:RegisterForEvent(addonVars.addonName, EVENT_COMPANION_ACTIVATED, FCOCompanion.Companion_Activated)
    --Crafting tables
    EM:RegisterForEvent(addonVars.addonName, EVENT_CRAFTING_STATION_INTERACT, FCOCompanion.CraftingTableInteract)
    EM:RegisterForEvent(addonVars.addonName, EVENT_END_CRAFTING_STATION_INTERACT, FCOCompanion.CraftingTableInteractEnd)
end


function FCOCompanion.initialize()
    EM:RegisterForEvent(addonVars.addonName, EVENT_ADD_ON_LOADED, FCOCompanion.addonLoaded)
end

------------------------------------------------------------------------------------------------------------------------
--Load the addon
if not FCOCompanion.isCompanionUnlocked then return end
FCOCompanion.initialize()
