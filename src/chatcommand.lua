-- travelnet_redo/src/chatcommand.lua
-- Chatcommands of interacting with the tvnet system
-- runtime: privs, db_api
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

local _int = travelnet_redo.internal
local S = _int.S
local logger = _int.logger:sublogger("chatcommand")

local f = string.format

minetest.register_chatcommand("tvnet_open", {
    params = S("(#<network id>|<network name>@@<owner>)"),
    privs = { teleport = true },
    description = S("Open a travelnet network"),
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, S("Player not found.")
        end

        local network_id
        if param:sub(1, 1) == "#" then
            network_id = tonumber(param:sub(2))
            if not network_id then
                return false, S("Invalid network ID!")
            end
            local network = travelnet_redo.get_network(network_id)
            if not network then
                return false, S("Network #@1 not found.", network_id)
            end
        else
            local params = string.split(param, "@")
            if #params ~= 2 then
                return false
            end
            local network_name, network_owner = params[1], params[2]
            local network = travelnet_redo.get_network_by_name_owner(network_name, network_owner)
            if not network then
                return false, S("Network @1@@@2 not found.", network_name, network_owner)
            end
            network_id = network.network_id
        end

        travelnet_redo.gui_tp_open_network(player, network_id)
        return true
    end
})

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

minetest.register_chatcommand("tvnet_change_network_owner", {
    param = S("<network id> <new owner>"),
    privs = { travelnet_attach = true, travelnet_remove = true },
    description = S("Change the owner of a network"),
    func = function(name, param)
        local params = string.split(param, " ")
        if #params < 2 then
            return false, S("Invalid usage, see /help @1", "tvnet_change_network_owner")
        end

        local network_id, new_owner = tonumber(params[1]), params[2]
        if not network_id then
            return false, S("Invalid network ID!")
        end

        local network = travelnet_redo.get_network(network_id)
        if not network then
            return false, S("Network #@1 not found.", network_id)
        end

        local old_owner = network.network_owner
        travelnet_redo.change_network_owner(network_id, new_owner)
        logger:action("%s changed owner of network #%d from %s to %s",
            name, network.network_id, old_owner, new_owner)
        return true, S("Successfully transfered network @1 (#@2) from @3 to @4.",
            network.network_name, network_id, old_owner, new_owner)
    end
})

minetest.register_chatcommand("tvnet_sync_ndb", {
    param = S("<network id>"),
    privs = { server = true },
    description = S("Sync travelnets with the node database"),
    func = function()
        local restored, removed, time = travelnet_redo.sync_ndb()
        return true, S("Travelnet node database synchronized. (Restored @1, removed @2, used @3 ms)",
            restored, removed, math.floor(time * 1000))
    end
})
