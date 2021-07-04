local stringsEN = {
    FCOCO_NO_COMPANION_UNLOCKED_YET                         = "[FCOCompanion]You did not unlock any " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .. " yet. Please finish and turn in any of the unlock quests first and reload the UI afterwards!",
    --FCOCO_SHOW_COMPANION_MENU                             = "Show \'" .. GetString(SI_INTERACT_OPTION_COMPANION_MENU) .. "\'",

    FCOCO_TOGGLE_COMPANION                                  = "Show/hide " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .." (last)",
    FCOCO_TOGGLE_COMPANION_1                                = "Show/hide " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .." 1",
    FCOCO_TOGGLE_COMPANION_2                                = "Show/hide " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .." 2",

    --LAM Settings
    FCOCO_LAM_SV_MODE                                       = 'Settings save mode',
    FCOCO_LAM_SV_MODE_TT                                    = 'Use account wide settings (the same for all your characters) or save them individually for each character?',
    FCOCO_LAM_SV_EACH_CHARACTER                             = "Each character",
    FCOCO_LAM_SV_ACCOUNT_WIDE                               = "Account wide",

    FCOCO_LAM_SETTING_HEADER_CRAFTING                       = GetString(SI_SKILLTYPE8),
    FCOCO_LAM_SETTING_UNSUMMON_AT_CRAFTING_TABLE            = "Dismiss at crafting table",
    FCOCO_LAM_SETTING_UNSUMMON_AT_CRAFTING_TABLE_TT         = "Hide your active companion if you interact with a crafting table",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_CRAFTING_TABLE         = "Re-summon after crafting table",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_CRAFTING_TABLE_TT      = "Summon your last active companion again after leaving the crafting table",

    FCOCO_LAM_SETTING_HEADER_BANKS                          = GetString(SI_CURRENCYLOCATION1),
    FCOCO_LAM_SETTING_UNSUMMON_AT_BANK                      = "Dismiss at bank",
    FCOCO_LAM_SETTING_UNSUMMON_AT_BANK_TT                   = "Hide your active companion if you interact with a bank",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_BANK                   = "Re-summon after bank",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_BANK_TT                = "Summon your last active companion again after leaving the bank",

    FCOCO_LAM_SETTING_HEADER_VENDORS                        = GetString(SI_MAPDISPLAYFILTER2),
    FCOCO_LAM_SETTING_UNSUMMON_AT_VENDOR                    = "Dismiss at vendor/fence",
    FCOCO_LAM_SETTING_UNSUMMON_AT_VENDOR_TT                 = "Hide your active companion if you interact with a vendor/fence",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_VENDOR                 = "Re-summon after vendor/fence",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_VENDOR_TT              = "Summon your last active companion again after leaving the vendor/fence",

    FCOCO_LAM_SETTING_HEADER_FISHING                        = GetString(SI_GUILDACTIVITYATTRIBUTEVALUE9),
    FCOCO_LAM_SETTING_UNSUMMON_AT_FISHING                   = "Dismiss at Fish hole",
    FCOCO_LAM_SETTING_UNSUMMON_AT_FISHING_TT                = "Hide your active companion if you interact with a fish hole",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_FISHING                = "Re-summon after fishing",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_FISHING_TT             = "Summon your last active companion again after leaving the fish hole.\n\'Leaving the fish hole\' means at the end of a fishing attempt, after the delay of milliseconds you setup below. If a new fishing attempt is started before the delay was met, the re-summon will be aborted.",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_FISHING_DELAY          = "Re-summon delay after fishing",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_FISHING_DELAY_TT       = "Delay the re-summoning after ending the fishing hole interaction with this milliseconds value (1000 = 1 second)",

    FCOCO_LAM_SETTING_HEADER_CROUCH                         = GetString(SI_BINDING_NAME_SPECIAL_MOVE_CROUCH),
    FCOCO_LAM_SETTING_UNSUMMON_AT_CROUCHING                 = "Dismiss at crouching",
    FCOCO_LAM_SETTING_UNSUMMON_AT_CROUCHING_TT              = "Hide your active companion if you start to crouch",
    FCOCO_LAM_SETTING_UNSUMMON_AT_CROUCHING_NO_COMBAT       = "Not in combat",
    FCOCO_LAM_SETTING_UNSUMMON_AT_CROUCHING_NO_COMBAT_TT    = "Only hide the companion if you are not in combat, as you start to crouch",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_CROUCHING              = "Re-summon after crouching",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_CROUCHING_TT           = "Summon your last active companion again after leaving the crouched state.\n\'Leaving the crouched state\' means as you get unhidden or stop to crouch the delay of milliseconds you setup below will be waited until the re-summon takes place. If you start to crouch again before the delay was met, the re-summon will be aborted.",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_CROUCHING_DELAY        = "Re-summon delay after crouching",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_CROUCHING_DELAY_TT     = "Delay the re-summoning after end of crouching with this milliseconds value (1000 = 1 second)",

    
    FCOCO_LAM_SETTING_HEADER_COMPASS                        = GetString(SI_CUSTOMERSERVICESUBMITFEEDBACKSUBCATEGORIES1304),
    FCOCO_LAM_SETTING_DISABLE_PIN_AT_COMPASS                = "Disable pin at compass",
    FCOCO_LAM_SETTING_DISABLE_PIN_AT_COMPASS_TT             = "Disable the companion's pin at the compass",
}

for stringId, stringValue in pairs(stringsEN) do
   ZO_CreateStringId(stringId, stringValue)
   SafeAddVersion(stringId, 1)
end