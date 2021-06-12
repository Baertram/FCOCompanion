local stringsDE = {
    FCOCO_NO_COMPANION_UNLOCKED_YET                    = "[FCOCompanion]Du hast noch keinen " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .. " freigeschaltet. Bitte schließe eine der Freischalt-Quests zuerst ab und lade danach die Benutzeroberfläche neu!",

    --FCOCO_SHOW_COMPANION_MENU   = "Zeige \'" .. GetString(SI_INTERACT_OPTION_COMPANION_MENU) .. "\'",
    FCOCO_TOGGLE_COMPANION                             = "Zeige/Verst. " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .. " (letzten)",
    FCOCO_TOGGLE_COMPANION_1                           = "Zeige/Verst. " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .. " 1",
    FCOCO_TOGGLE_COMPANION_2                           = "Zeige/Verst. " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .. " 2",

    --LAM Settings
    FCOCO_LAM_SV_MODE                                  = 'Einstellungen Sicherungs-Modus',
    FCOCO_LAM_SV_MODE_TT                               = 'Verwende Account-weite Einstellungen (identisch für alle deine Charaktere) oder individuelle Einstellungen je Charakter?',
    FCOCO_LAM_SV_EACH_CHARACTER                        = "Jeder Charakter einzeln",
    FCOCO_LAM_SV_ACCOUNT_WIDE                          = "Account weit",

    FCOCO_LAM_SETTING_UNSUMMON_AT_CRAFTING_TABLE       = "Wegschicken an Handwerksstationen",
    FCOCO_LAM_SETTING_UNSUMMON_AT_CRAFTING_TABLE_TT    = "Schickt deinen Begleiter an einer Handwerksstation fort, wenn du mit dieser interagierst",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_CRAFTING_TABLE    = "Wieder beschwören nach der Handwerksstation",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_CRAFTING_TABLE_TT = "Beschwört den zuletzt aktiven Begleiter, wenn du die Handwerksstation wieder verlässt",

    FCOCO_LAM_SETTING_UNSUMMON_AT_BANK                  = "Wegschicken an Banken",
    FCOCO_LAM_SETTING_UNSUMMON_AT_BANK_TT               = "Schickt deinen Begleiter an einer Bank fort, wenn du mit dieser interagierst",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_BANK               = "Wieder beschwören nach der Bank",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_BANK_TT            = "Beschwört den zuletzt aktiven Begleiter, wenn du die Bank wieder verlässt",

    FCOCO_LAM_SETTING_UNSUMMON_AT_VENDOR                = "Wegschicken beim Händler/Hehler",
    FCOCO_LAM_SETTING_UNSUMMON_AT_VENDOR_TT             = "Schickt deinen Begleiter bei einem Händler/Hehler fort, wenn du mit diesem interagierst",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_VENDOR             = "Wieder beschwören nach dem Händler/Hehler",
    FCOCO_LAM_SETTING_RESUMMON_AFTER_VENDOR_TT          = "Beschwört den zuletzt aktiven Begleiter, wenn du den Händler/Hehler wieder verlässt",

    FCOCO_LAM_SETTING_DISABLE_PIN_AT_COMPASS            = "Kompass Pin verstecken",
    FCOCO_LAM_SETTING_DISABLE_PIN_AT_COMPASS_TT         = "Verstecke den Gefährten Pin auf dem Kompass",
}

for stringId, stringValue in pairs(stringsDE) do
    SafeAddString(_G[stringId], stringValue, 2)
end
