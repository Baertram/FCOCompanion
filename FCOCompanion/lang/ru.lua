local stringsRU = {
    FCOCO_NO_COMPANION_UNLOCKED_YET                         = "[FCOCompanion]You did not unlock any " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .. " yet. Please finish and turn in any of the unlock quests first and reload the UI afterwards!",

    --FCOCO_SHOW_COMPANION_MENU   = "Показать \'" .. GetString(SI_INTERACT_OPTION_COMPANION_MENU) .. "\'",
    FCOCO_TOGGLE_COMPANION      = "Показать/скрывать " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .." (последний)",
    FCOCO_TOGGLE_COMPANION_1    = "Показать/скрывать " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .." 1",
    FCOCO_TOGGLE_COMPANION_2    = "Показать/скрывать " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .." 2",

    --LAM Settings
}

for stringId, stringValue in pairs(stringsRU) do
    SafeAddString(_G[stringId], stringValue, 2)
end