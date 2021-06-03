local stringsJP = {
    FCOCO_NO_COMPANION_UNLOCKED_YET                         = "[FCOCompanion]You did not unlock any " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .. " yet. Please finish and turn in any of the unlock quests first and reload the UI afterwards!",

    --FCOCO_SHOW_COMPANION_MENU   = "見せる \'" .. GetString(SI_INTERACT_OPTION_COMPANION_MENU) .. "\'",
    FCOCO_TOGGLE_COMPANION      = "見せる/隠す " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .. " (last)",
    FCOCO_TOGGLE_COMPANION_1    = "見せる/隠す " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .. " 1",
    FCOCO_TOGGLE_COMPANION_2    = "見せる/隠す " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .. " 2",

    --LAM Settings
    FCOCO_LAM_SV_MODE                                       = 'Settings save mode',
    FCOCO_LAM_SV_MODE_TT                                    = 'Use account wide settings (the same for all your characters) or save them individually for each character?',
    FCOCO_LAM_SV_EACH_CHARACTER                             = "Each character",
    FCOCO_LAM_SV_ACCOUNT_WIDE                               = "Account wide",

    FCOCO_LAM_SETTING_HEADER_CRAFTING                       = GetString(SI_SKILLTYPE8),
    FCOCO_LAM_SETTING_UNSUMMON_AT_CRAFTING_TABLE            = "Un-summon at crafting table",
    FCOCO_LAM_SETTING_UNSUMMON_AT_CRAFTING_TABLE_TT         = "Hide your active companion if you interact with a crafting table",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_CRAFTING_TABLE         = "Re-summon after crafting table",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_CRAFTING_TABLE_TT      = "Summon your last active companion again after leaving the crafting table",
}

for stringId, stringValue in pairs(stringsJP) do
    SafeAddString(_G[stringId], stringValue, 2)
end