-- travelnet_redo/src/settings.lua
-- Load settings
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

local settings = {}

-- These can't be modified without server restart
settings_loader.load_settings("travelnet_redo.", {
    pg_connection = {
        stype = "string",
        default = "",
    }
}, false, settings)

-- These can be modified and reloaded
settings_loader.load_settings("travelnet_redo.", {
    cache_duration = {
        stype = "integer",
        default = 120, -- 2 minutes
    },
    default_network = {
        stype = "string",
        default = "net1",
    },
    walkin_open = {
        stype = "boolean",
        default = false,
    }
}, true, settings)

travelnet_redo.settings = settings
