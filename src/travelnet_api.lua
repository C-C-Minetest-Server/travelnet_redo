-- travelnet_redo/src/travelnet_api.lua
-- Register travelnets
-- depends: db_api
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

local _int = travelnet_redo.internal
local S = _int.S
-- local logger = _int.logger:sublogger("travelnet_api")

function travelnet_redo.gui_setup_or_tp(player, pos)
    local travelnet = travelnet_redo.get_travelnet_from_map(pos)
    if travelnet then
        local network = travelnet_redo.get_network(travelnet.network_id)
        local meta = minetest.get_meta(pos)

        meta:set_string("infotext",
            S("Travelnet @1 in @2@@@3, rightclick/tap to teleport.",
                travelnet.display_name, network.network_name, network.network_owner))

        travelnet_redo.gui_tp:show(player, { pos = pos })
    else
        local name = player:get_player_name()
        if minetest.is_protected(pos, name) then
            minetest.record_protection_violation(pos, name)
            return
        end
        travelnet_redo.gui_setup:show(player, { pos = pos })
    end
end

minetest.register_node("travelnet_redo:placeholder", {
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = false,
    drop = "",
    is_ground_content = false,
})

if minetest.global_exists("mesecons") then
    mesecon.register_mvps_stopper("travelnet_redo:placeholder")
end

function travelnet_redo.register_travelnet(name, def)
    def = table.copy(def)

    def.on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", S("Unconfigured travelnet, rightclick/tap to configure"))

        local up = vector.new(pos.x, pos.y + 1, pos.z)
        local up_node = minetest.get_node_or_nil(up)
        if up_node then
            local up_def = minetest.registered_nodes[up_node.name]
            if up_def and up_def.buildable_to then
                minetest.set_node(up, { name = "travelnet_redo:placeholder" })
            end
        end
    end

    def.on_rightclick = function(pos, _, player, itemstack)
        if not player:is_player() then return end

        travelnet_redo.gui_setup_or_tp(player, pos)
        return itemstack
    end

    def.can_dig = function(pos, player)
        if not player:is_player() then return false end
        return travelnet_redo.can_edit_travelnet(pos, player:get_player_name())
    end

    def.on_destruct = function(pos)
        local travelnet = travelnet_redo.get_travelnet_from_map(pos)
        if travelnet then
            travelnet_redo.remove_travelnet(pos, travelnet.network_id)
        end

        local up = vector.new(pos.x, pos.y + 1, pos.z)
        if minetest.get_node(up).name == "travelnet_redo:placeholder" then
            minetest.remove_node(up)
        end
    end

    def.on_blast = function() end

    def.groups = def.groups or {}
    def.groups.travelnet_redo = 1

    minetest.register_node(name, def)

    if minetest.global_exists("mesecons") then
        mesecon.register_mvps_stopper(name)
    end
end
