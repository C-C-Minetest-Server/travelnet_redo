-- travelnet_redo/src/utils.lua
-- internal utils
-- depends: travelnet_api
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

local _int = travelnet_redo.internal

local function safe_player_after(func, pname, ...)
    local player = minetest.get_player_by_name(pname)
    if player then
        func(player, ...)
    end
end
function _int.safe_player_after(delay, func, player, ...)
    return minetest.after(delay, safe_player_after, func, player:get_player_name(), ...)
end

local function show_on_next_step(player, gui, ctx)
    gui:show(player, ctx)
end
function _int.show_on_next_step(player, gui, ctx)
    return _int.safe_player_after(0, show_on_next_step, player, gui, ctx)
end
