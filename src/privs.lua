-- travelnet_redo/src/privs.lua
-- Register privileges
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

local _int = travelnet_redo.internal
local S = _int.S

minetest.register_privilege("travelnet_attach", {
    description = S("allows to attach travelnet boxes to travelnets of other players"),
    give_to_singleplayer = false
})

minetest.register_privilege("travelnet_remove", {
    description = S("allows to dig travelnet boxes which belog to nets of other players"),
    give_to_singleplayer = false
})