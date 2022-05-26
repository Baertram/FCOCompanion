local companionStr = GetString(SI_UNIT_FRAME_NAME_COMPANION)
local companionKeybindBaseStr = "Afficher/masquer " .. companionStr

local stringsFR = {
    FCOCO_NO_COMPANION_UNLOCKED_YET                         = "[FCOCompanion]You did not unlock any " .. GetString(SI_UNIT_FRAME_NAME_COMPANION) .. " yet. Please finish and turn in any of the unlock quests first and reload the UI afterwards!",

    --FCOCO_SHOW_COMPANION_MENU   = "Afficher le \'" .. GetString(SI_INTERACT_OPTION_COMPANION_MENU) .. "\'",
    FCOCO_TOGGLE_COMPANION      = companionKeybindBaseStr .." (dernier)",

    --LAM Settings
}

for i=1, 10, 1 do
    stringsFR["FCOCO_TOGGLE_COMPANION_" .. tostring(i)]     = companionKeybindBaseStr .. " " .. tostring(i)
end


for stringId, stringValue in pairs(stringsFR) do
    SafeAddString(_G[stringId], stringValue, 2)
end