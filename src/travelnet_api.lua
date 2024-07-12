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
    local name = player:get_player_name()
    if travelnet then
        local meta = minetest.get_meta(pos)
        local network = travelnet_redo.get_network(travelnet.network_id)
        if not network then
            meta:set_string("infotext", S("Unconfigured travelnet, rightclick/tap to configure"))
            meta:set_string("display_name", "")
            meta:set_int("network_id", 0)
            meta:set_string("travelnet_redo_configured", "")

            minetest.chat_send_player(name,
                S("This travelnet is orphaned. Please set up again."))
        else
            meta:set_string("infotext",
                S("Travelnet @1 in @2@@@3, rightclick/tap to teleport.",
                    travelnet.display_name, network.network_name, network.network_owner))
            travelnet_redo.gui_tp:show(player, { pos = pos })
            return
        end
    end

    if minetest.is_protected(pos, name) then
        minetest.record_protection_violation(pos, name)
        return
    end
    travelnet_redo.gui_setup:show(player, { pos = pos })
end

function travelnet_redo.on_construct(pos)
    local meta = minetest.get_meta(pos)
    meta:set_string("infotext", S("Unconfigured travelnet, rightclick/tap to configure"))
end

function travelnet_redo.on_rightclick(pos, _, player, itemstack)
    if not player:is_player() then return end

    travelnet_redo.gui_setup_or_tp(player, pos)
    return itemstack
end

function travelnet_redo.can_dig(pos, player)
    if not player:is_player() then return false end
    return travelnet_redo.can_edit_travelnet(pos, player:get_player_name())
end

function travelnet_redo.on_destruct(pos)
    local travelnet = travelnet_redo.get_travelnet_from_map(pos)
    if travelnet then
        travelnet_redo.remove_travelnet(pos, travelnet.network_id)
    end
end

---@param travelnet travelnet_redo.Travelnet
---@param node { name: string, param1: integer, param2: integer }
---@param player ObjectRef
function travelnet_redo.default_on_teleport(travelnet, _, player)
    player:set_pos(travelnet.pos)
end

local function noop() end

local function add_or_run_after(tb, key, func)
    local old_func = tb[key]
    if old_func then
        tb[key] = function(...)
            func(...)
            old_func(...)
        end
    else
        tb[key] = func
    end
end

if minetest.global_exists("mesecons") then
    mesecon.register_mvps_stopper("travelnet_redo:placeholder")
end

function travelnet_redo.register_travelnet(name, def)
    def = table.copy(def)

    def.on_rightclick = travelnet_redo.on_rightclick
    def.can_dig = travelnet_redo.can_dig
    add_or_run_after(def, "on_construct", travelnet_redo.on_construct)
    add_or_run_after(def, "on_destruct", travelnet_redo.on_destruct)
    def.on_blast = noop

    def.groups = def.groups or {}
    def.groups.travelnet_redo = 1
    def.is_ground_content = false

    minetest.register_node(name, def)

    if minetest.global_exists("mesecons") then
        mesecon.register_mvps_stopper(name)
    end
end
