-- travelnet_redo/src/teacher.lua
-- Teacher tutorials
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

if not minetest.get_modpath("teacher_core") then return end

local _int = travelnet_redo.internal
local S = _int.S

teacher.register_turorial("travelnet_redo:default_travelnet", {
    title = S("Travelnets"),
    show_on_unlock = true,
    triggers = {
        {
            name = "approach_node",
            nodenames = "group:travelnet_redo",
        },
    },

    {
        texture = "travelnet_teacher_1.png",
        text =
            S("Travelnets are devices providing instant transportation between distinct locations.") .. "\n\n" ..
            S("To use a travelnet, right-click a configured travelnet and select a destination.")
    },
    {
        texture = "travelnet_teacher_2.png",
        text =
            S("In the interface of a travelnet, click or tap on the name of your desired destination.") .. "\n\n" ..
            S("If the background is green, you are already in this travelnet. " ..
                "There is no point in teleporting there.") .. "\n\n" ..
            S("If the background is red, the destination is protected. You cannot teleport there.")
    },
    {
        texture = "travelnet_teacher_3.png",
        text =
            S("To set up a travelnet, place down a new travelnet and right click it. " ..
                "Fill in the form, then click/tap save.") .. "\n\n" ..
            S("To edit an existing travelnet, right click it then click/tap edit. " ..
                "To remove one, dig the travelnet.")
    },
})
