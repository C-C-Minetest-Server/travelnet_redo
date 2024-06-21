-- travelnet_redo/src/chatcommand.lua
-- Chatcommands of interacting with the tvnet system
-- runtime: db_api
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

local _int = travelnet_redo.internal
local S = _int.S
local logger = _int.logger:sublogger("chatcommand")

local f = string.format

minetest.register_chatcommand("tvnet_set_always_cache", {
    param = S("<network id>"),
    privs = { server = true },
    description = S("Set a network to be always cached"),
    func = function(name, param)
        local network_id = tonumber(param)
        if not network_id then
            return false, S("Invalid network ID!")
        end

        local network = travelnet_redo.get_network(network_id)
        if not network then
            return false, S("Network #@1 not found.", network_id)
        end

        travelnet_redo.set_network_always_cache(network_id, true)
        logger:action(f("%s set network #%d to be always cached", name, network_id))
        return true, S("Successfully set network @1@@@2 (#@3) to be always cached.",
            network.network_name, network.network_owner, network_id)
    end
})

minetest.register_chatcommand("tvnet_unset_always_cache", {
    param = S("<network id>"),
    privs = { server = true },
    description = S("Set a network to no longer be always cached"),
    func = function(name, param)
        local network_id = tonumber(param)
        if not network_id then
            return false, S("Invalid network ID!")
        end

        local network = travelnet_redo.get_network(network_id)
        if not network then
            return false, S("Network #@1 not found.", network_id)
        end

        travelnet_redo.set_network_always_cache(network_id, false)
        logger:action(f("%s set network #%d to no longer be always cached", name, network_id))
        return true, S("Successfully set network @1@@@2 (#@3) to no longer be always cached.",
            network.network_name, network.network_owner, network_id)
    end
})
