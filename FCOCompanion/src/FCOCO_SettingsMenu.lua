FCOCO = FCOCO or  {}
local FCOCompanion = FCOCO
if not FCOCompanion.isCompanionUnlocked then return end
------------------------------------------------------------------------------------------------------------------------


local addonVars = FCOCompanion.addonVars
local LAM2 = FCOCompanion.LAM

------------------------------------------------------------------------------------------------------------------------
-- SETTINGS MENU
------------------------------------------------------------------------------------------------------------------------

function FCOCompanion.buildAddonMenu()
    local settings = FCOCompanion.settingsVars.settings
    if not settings or not LAM2 then return false end
    local defaults = FCOCompanion.settingsVars.defaults
    local addonName = addonVars.addonName


    local panelData = {
        type 				= 'panel',
        name 				= addonVars.addonNameMenu,
        displayName 		= addonVars.addonNameMenuDisplay,
        author 				= addonVars.addonAuthor,
        version 			= tostring(addonVars.addonVersion),
        registerForRefresh 	= true,
        registerForDefaults = true,
        slashCommand        = "/fcocos",
        website             = addonVars.addonWebsite,
        feedback            = addonVars.addonFeedback,
        donation            = addonVars.addonDonation,
    }
    FCOCompanion.FCOSettingsPanel = LAM2:RegisterAddonPanel(addonName .. "_LAM", panelData)

    local savedVariablesOptions = {
        [1] = GetString(FCOCO_LAM_SV_EACH_CHARACTER),   --'Each character',
        [2] = GetString(FCOCO_LAM_SV_ACCOUNT_WIDE),     --'Account wide'
    }
    local savedVariablesOptionsValues = {
        [1] = 1,
        [2] = 2,
    }

    local optionsTable =
    {	-- BEGIN OF OPTIONS TABLE

        {
            type = 'dropdown',
            name = GetString(FCOCO_LAM_SV_MODE),
            tooltip = GetString(FCOCO_LAM_SV_MODE_TT),
            choices = savedVariablesOptions,
            choicesValues = savedVariablesOptionsValues,
            getFunc = function() return FCOCompanion.settingsVars.defaultSettings.saveMode end,
            setFunc = function(value)
                FCOCompanion.settingsVars.defaultSettings.saveMode = value
            end,
            requiresReload = true,
        },

        --==============================================================================
        {
            type = 'header',
            name = GetString(FCOCO_LAM_SETTING_HEADER_CRAFTING),
        },
        {
            type = "checkbox",
            name = GetString(FCOCO_LAM_SETTING_UNSUMMON_AT_CRAFTING_TABLE),
            tooltip = GetString(FCOCO_LAM_SETTING_UNSUMMON_AT_CRAFTING_TABLE_TT),
            getFunc = function() return settings.unSummonAtCraftingTables end,
            setFunc = function(value) settings.unSummonAtCraftingTables = value
            end,
            default = defaults.unSummonAtCraftingTables,
            width="full",
        },
        {
            type = "checkbox",
            name = GetString(FCOCO_LAM_SETTING_RESUMMON_AFTER_CRAFTING_TABLE),
            tooltip = GetString(FCOCO_LAM_SETTING_RESUMMON_AFTER_CRAFTING_TABLE_TT),
            getFunc = function() return settings.reSummonAfterCraftingTables end,
            setFunc = function(value) settings.reSummonAfterCraftingTables = value
            end,
            default = defaults.reSummonAfterCraftingTables,
            disabled = function() return not settings.unSummonAtCraftingTables end,
            width="full",
        },
        --==============================================================================
        {
            type = 'header',
            name = GetString(FCOCO_LAM_SETTING_HEADER_BANKS),
        },
        {
            type = "checkbox",
            name = GetString(FCOCO_LAM_SETTING_UNSUMMON_AT_BANK),
            tooltip = GetString(FCOCO_LAM_SETTING_UNSUMMON_AT_BANK_TT),
            getFunc = function() return settings.unSummonAtBanks end,
            setFunc = function(value) settings.unSummonAtBanks = value
            end,
            default = defaults.unSummonAtBanks,
            width="full",
        },
        {
            type = "checkbox",
            name = GetString(FCOCO_LAM_SETTING_RESUMMON_AFTER_BANK),
            tooltip = GetString(FCOCO_LAM_SETTING_RESUMMON_AFTER_BANK_TT),
            getFunc = function() return settings.reSummonAfterBanks end,
            setFunc = function(value) settings.reSummonAfterBanks = value
            end,
            default = defaults.reSummonAfterBanks,
            disabled = function() return not settings.unSummonAtBanks end,
            width="full",
        },
        --==============================================================================
        {
            type = 'header',
            name = GetString(FCOCO_LAM_SETTING_HEADER_VENDORS),
        },
        {
            type = "checkbox",
            name = GetString(FCOCO_LAM_SETTING_UNSUMMON_AT_VENDOR),
            tooltip = GetString(FCOCO_LAM_SETTING_UNSUMMON_AT_VENDOR_TT),
            getFunc = function() return settings.unSummonAtVendors end,
            setFunc = function(value) settings.unSummonAtVendors = value
            end,
            default = defaults.unSummonAtVendors,
            width="full",
        },
        {
            type = "checkbox",
            name = GetString(FCOCO_LAM_SETTING_RESUMMON_AFTER_VENDOR),
            tooltip = GetString(FCOCO_LAM_SETTING_RESUMMON_AFTER_VENDOR_TT),
            getFunc = function() return settings.reSummonAfterVendors end,
            setFunc = function(value) settings.reSummonAfterVendors = value
            end,
            default = defaults.reSummonAfterVendors,
            disabled = function() return not settings.unSummonAtVendors end,
            width="full",
        },
    } -- optionsTable
    -- END OF OPTIONS TABLE
    --[[
    local lamPanelCreationInitDone = false
    local function LAMControlsCreatedCallbackFunc(pPanel)
        if pPanel ~= FCOCompanion.FCOSettingsPanel then return end
        if lamPanelCreationInitDone == true then return end
        --Do stiff here
        lamPanelCreationInitDone = true
    end
    ]]
    --CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", LAMControlsCreatedCallbackFunc)

    LAM2:RegisterOptionControls(addonName .. "_LAM", optionsTable)
end