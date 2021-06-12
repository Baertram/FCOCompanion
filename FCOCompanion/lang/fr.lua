local stringsFR = {
    FCOCO_NO_COMPANION_UNLOCKED_YET                         = "[FCOCompanion]You did not unlock any " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .. " yet. Please finish and turn in any of the unlock quests first and reload the UI afterwards!",

    --FCOCO_SHOW_COMPANION_MENU   = "Afficher le \'" .. GetString(SI_INTERACT_OPTION_COMPANION_MENU) .. "\'",
    FCOCO_TOGGLE_COMPANION      = "Afficher/masquer " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .." (dernier)",
    FCOCO_TOGGLE_COMPANION_1    = "Afficher/masquer " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .." 1",
    FCOCO_TOGGLE_COMPANION_2    = "Afficher/masquer " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .." 2",

    --LAM Settings
}

for stringId, stringValue in pairs(stringsFR) do
    SafeAddString(_G[stringId], stringValue, 2)
end