-- travelnet_redo/src/utils.lua
-- internal utils
-- depends: travelnet_api
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

local _int = travelnet_redo.internal

local function show_on_next_step(pname, gui, ctx)
    local player = minetest.get_player_by_name(pname)
    if player then
        gui:show(player, ctx)
    end
end
function _int.show_on_next_step(player, gui, ctx)
    return minetest.after(0, show_on_next_step, player:get_player_name(), gui, ctx)
end
