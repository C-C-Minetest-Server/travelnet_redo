-- travelnet_redo/src/travelnet_api.lua
-- Register travelnets
-- depends: db_api
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

local _int = travelnet_redo.internal
local S = _int.S
local logger = _int.logger:sublogger("travelnet_api")

function travelnet_redo.get_preprog_stack_from_pos(pos)
    local node = core.get_node(pos)
    local nname = node.name
    local def = core.registered_nodes[nname]
    if not (def and def.groups and def.groups.travelnet_redo) then
        return nil
    end

    local tvnet = travelnet_redo.get_travelnet_from_map(pos)
    if not tvnet then
        return
    end

    local network = travelnet_redo.get_network(tvnet.network_id)
    if not network then
        return
    end

    local display_name = tvnet.display_name or ""
    local network_name = network.network_name or ""
    local network_owner = network.network_owner or ""
    local sort_key = tvnet.sort_key or 0
    local nostack = tostring(math.random()) .. tostring(os.clock())

    local stack = ItemStack(nname .. " 1 ")
    local meta = stack:get_meta()
    meta:set_string("tvnet_pp", nostack) -- random to minimize the possibliity of stacking
    meta:set_string("tvnet_pp_display_name", display_name)
    meta:set_string("tvnet_pp_network_name", network_name)
    meta:set_string("tvnet_pp_network_owner", network_owner)
    meta:set_int("tvnet_pp_sort_key", sort_key)

    local description = table.concat({
        S("Pre-programmed @1", stack:get_short_description()),
        core.get_color_escape_sequence("orange") ..
            S("To un-program this travelnet item, place it into the crafting grid."),
        core.get_color_escape_sequence("grey") .. S("Display name: @1", display_name),
        core.get_color_escape_sequence("grey") .. S("Network: @1@@@2", network_name, network_owner),
        core.get_color_escape_sequence("grey") .. S("Sorting key: @1", sort_key),
    }, "\n")
    meta:set_string("description", description)

    return stack
end

function travelnet_redo.get_preprog_data_from_stack(stack, player_name)
    local meta = stack:get_meta()

    if meta:get_string("tvnet_pp") == "" then
        return nil
    end

    local display_name = string.trim(meta:get_string("tvnet_pp_display_name"))
    local network_name = string.trim(meta:get_string("tvnet_pp_network_name"))
    local network_owner = string.trim(meta:get_string("tvnet_pp_network_owner"))
    local sort_key = meta:get_int("tvnet_pp_sort_key")

    if not display_name or display_name == "" then
        return false, S("Display name not given")
    elseif not network_name or network_name == "" then
        return false, S("Network name not given")
    elseif string.len(display_name) > 40 then
        return false, S("Length of display name cannot exceed 40")
    elseif string.len(network_name) > 40 then
        return false, S("Length of network name cannot exceed 40")
    elseif
        not network_owner or network_owner == ""
        or (network_owner ~= player_name and not core.check_player_privs(player_name, { travelnet_attach = true }))
    then
        return false, S("Insufficant privilege to attach travelnets to other players' networks")
    elseif string.len(network_owner) > 20 then
        return false, S("Length of owner name cannot exceed 20")
    elseif sort_key < -32768 or sort_key > 32767 then
        return false, S("Invalid sorting key")
    end

    local network = travelnet_redo.get_network_by_name_owner(network_name, network_owner)
    if network then
        if travelnet_redo.get_travelnet_by_name_id(display_name, network.network_id) then
            return false, S("Travelnet of the same name already exists")
        end
    end

    return true, {
        display_name = display_name,
        network_name = network_name,
        network_owner = network_owner,
        sort_key = sort_key
    }
end

function travelnet_redo.on_place(itemstack, placer, pointed_thing)
    local pname = placer and placer:is_player() and placer:get_player_name()

    if pname == nil then
        return core.item_place(itemstack, placer, pointed_thing)
    end

    local status, data = travelnet_redo.get_preprog_data_from_stack(itemstack, pname)

    if status == false then
        core.chat_send_player(pname, S("Failed to place down pre-programmed travelnet: @1", data))
        core.chat_send_player(pname, S("To un-program this travelnet item, place it into the crafting grid."))
        return nil
    end

    -- nil: No pre-programmed data, always proceed in the normal way
    -- true: Hand over the travelnet apply logic to after_place_node
    return core.item_place(itemstack, placer, pointed_thing)
end

function travelnet_redo.after_place_node(pos, placer, itemstack)
    local pname = placer and placer:is_player() and placer:get_player_name()

    if pname == nil then
        return
    end

    local status, data = travelnet_redo.get_preprog_data_from_stack(itemstack, pname)

    if status == false then
        -- This is an error: we should not be able to reach here
        -- Anyways, the travelnet is placed and it's dirty to force it back to the inventory
        -- So we will leave behind an unprogrammed travelnet

        core.chat_send_player(pname, S("Failed to place down pre-programmed travelnet: @1", data))
        return
    end

    if status == nil then
        -- No pre-programmed data, do nothing
        return
    end

    local network_id = travelnet_redo.create_or_get_network(data.network_name, data.network_owner)
    local travelnet = travelnet_redo.add_travelnet(pos, data.display_name, network_id, data.sort_key)

    local node = core.get_node(pos)
    local def  = core.registered_nodes[node.name]
    local func = def and def._tvnet_on_setup or travelnet_redo.default_on_setup
    func(travelnet, travelnet_redo.get_network(network_id), node)

    logger:action("%s set up travelnet via pre-programmed item at %s, name = %s, network = %s@%s (#%d), sort_key = %d",
        pname, core.pos_to_string(pos), data.display_name, data.network_name,
        data.network_owner, network_id, data.sort_key
    )
    _int.show_on_next_step(placer, travelnet_redo.gui_tp, { pos = pos })
end

function travelnet_redo.gui_setup_or_tp(player, pos)
    local travelnet = travelnet_redo.get_travelnet_from_map(pos)
    local name = player:get_player_name()
    if travelnet then
        local meta = core.get_meta(pos)
        local network = travelnet_redo.get_network(travelnet.network_id)
        if not network then
            meta:set_string("infotext", S("Unconfigured travelnet, rightclick/tap to configure"))
            meta:set_string("display_name", "")
            meta:set_int("network_id", 0)
            meta:set_string("travelnet_redo_configured", "")

            core.chat_send_player(name,
                S("This travelnet is orphaned. Please set up again."))
        else
            meta:set_string("infotext",
                S("Travelnet @1 in @2@@@3, rightclick/tap to teleport.",
                    travelnet.display_name, network.network_name, network.network_owner))
            travelnet_redo.gui_tp_open_at(player, pos)
            return
        end
    end

    if core.is_protected(pos, name) then
        core.record_protection_violation(pos, name)
        return
    end
    travelnet_redo.gui_setup:show(player, { pos = pos })
end

function travelnet_redo.on_construct(pos)
    local meta = core.get_meta(pos)
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
    -- Prevent slamming onto the ground causing death if teleporting mid-fall
    -- and other velocity problems.
    local vel = player:get_velocity()
    local add_vel = vector.multiply(vel, -1)
    player:add_velocity(add_vel)

    player:set_pos(travelnet.pos)
end

---@param travelnet travelnet_redo.Travelnet
---@param network travelnet_redo.TravelnetNetwork
---@param node { name: string, param1: integer, param2: integer }
function travelnet_redo.default_on_setup(travelnet, network, _)
    local meta = core.get_meta(travelnet.pos)
    meta:set_string("infotext", S("Travelnet @1 in @2@@@3, rightclick/tap to teleport.",
        travelnet.display_name, network.network_name, network.network_owner))
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

function travelnet_redo.register_travelnet(name, def)
    def = table.copy(def)

    def.on_place = travelnet_redo.on_place
    def.after_place_node = travelnet_redo.after_place_node
    def.on_rightclick = travelnet_redo.on_rightclick
    def.can_dig = travelnet_redo.can_dig
    add_or_run_after(def, "on_construct", travelnet_redo.on_construct)
    add_or_run_after(def, "on_destruct", travelnet_redo.on_destruct)
    def.on_blast = noop

    def.groups = def.groups or {}
    def.groups.travelnet_redo = 1
    def.is_ground_content = false

    core.register_node(name, def)

    if core.global_exists("mesecons_mvps") then
        mesecon.register_mvps_stopper(name)
    end
end
