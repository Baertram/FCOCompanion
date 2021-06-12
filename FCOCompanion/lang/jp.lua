local stringsJP = {
    FCOCO_NO_COMPANION_UNLOCKED_YET                         = "[FCOCompanion]You did not unlock any " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .. " yet. Please finish and turn in any of the unlock quests first and reload the UI afterwards!",

    --FCOCO_SHOW_COMPANION_MENU   = "見せる \'" .. GetString(SI_INTERACT_OPTION_COMPANION_MENU) .. "\'",
    FCOCO_TOGGLE_COMPANION      = "見せる/隠す " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .. " (最終)",
    FCOCO_TOGGLE_COMPANION_1    = "見せる/隠す " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .. " 1",
    FCOCO_TOGGLE_COMPANION_2    = "見せる/隠す " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .. " 2",

    --LAM Settings
}

for stringId, stringValue in pairs(stringsJP) do
    SafeAddString(_G[stringId], stringValue, 2)
end