-- travelnet_redo/src/register.lua
-- Regsiter callbacks
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

local _int = travelnet_redo.internal
local logger = _int.logger:sublogger("register")

-- travelnet_redo.register_on_teleport(function(player, network, travelnet))
travelnet_redo.regsitered_on_teleport = {}
travelnet_redo.register_on_teleport = function(func)
    logger:assert(type(func) == "function", "func must be a function")
    table.insert(travelnet_redo.regsitered_on_teleport, func)
end
