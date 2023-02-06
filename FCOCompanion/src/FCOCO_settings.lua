FCOCO = FCOCO or  {}
local FCOCompanion = FCOCO
if not FCOCompanion.isCompanionUnlocked then return end
------------------------------------------------------------------------------------------------------------------------


local addonVars = FCOCompanion.addonVars

------------------------------------------------------------------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------------------------------------------------------------------
--Read the SavedVariables
function FCOCompanion.getSettings()
    local serverName    = GetWorldName()
    local svName        = addonVars.addonSavedVariablesName
    local svVersion     = addonVars.addonSavedVarsVersion
    local svForAllTable = addonVars.addonSavedVarsForAllTable
    local svNormalTable = addonVars.addonSavedVarsNormalTable

    --The default values for the language and save mode
    local defaultsSettings = {
        language 	 		    = 1, --Standard: English
        saveMode     		    = 2, --Standard: Account wide settings
    }

    --Pre-set the deafult values
    local defaults = {
        alwaysUseClientLanguage			    = true,

        companionIsSummoned                 = false,
        lastCompanionId                     = 1, --Bastian Helix, companionDefId 1
        unSummonAtCraftingTables            = true,
        reSummonAfterCraftingTables         = true,
        unSummonAtBanks                     = false,
        reSummonAfterBanks                  = false,
        unSummonAtVendors                   = false,
        reSummonAfterVendors                = false,
        unSummonAtFishing                   = false,
        reSummonAfterFishing                = false,
        reSummonAfterFishingDelay           = 5000,
        disableCompanionAtCompass           = false,
        unSummonAtCrouching                 = false,
        unSummonAtCrouchingNoCombat         = false,
        reSummonAfterCrouching              = false,
        reSummonAfterCrouchingDelay         = 5000,

        enableCompanionItemJunk             = false,
        companionItemsJunked                = {},
    }
    FCOCompanion.settingsVars.defaults = defaults

    --=============================================================================================================
    --	LOAD USER SETTINGS
    --=============================================================================================================
    --Load the user's settings from SavedVariables file -> Account wide of basic version 999 at first
    FCOCompanion.settingsVars.defaultSettings = ZO_SavedVars:NewAccountWide( svName, 999, svForAllTable, defaultsSettings, serverName )

    --Check, by help of basic version 999 settings, if the settings should be loaded for each character or account wide
    --Use the current addon version to read the settings now
    if (FCOCompanion.settingsVars.defaultSettings.saveMode == 1) then
        FCOCompanion.settingsVars.settings = ZO_SavedVars:NewCharacterIdSettings( svName, svVersion , svNormalTable, defaults, serverName )
    else
        FCOCompanion.settingsVars.settings = ZO_SavedVars:NewAccountWide( svName, svVersion, svNormalTable, defaults, serverName )
    end
    --=============================================================================================================
end