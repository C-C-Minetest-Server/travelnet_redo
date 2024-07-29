-- travelnet_redo/src/gui_tp.lua
-- GUI for using a travelnet
-- runtime: db_api, privs, travelnet_api
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

local _int = travelnet_redo.internal
local S = _int.S
-- local logger = _int.logger:sublogger("gui_tp")

local gui = flow.widgets
local hud = minetest.global_exists("mhud") and mhud.init()

local f = string.format
local lower = string.lower
local sub = string.sub
local trim = string.trim

---Compare two travelnets
---@param a travelnet_redo.Travelnet
---@param b travelnet_redo.Travelnet
---@return boolean
---@see table.sort
function travelnet_redo.travelnet_sort_compare(a, b)
    if a.sort_key ~= b.sort_key then
        return a.sort_key < b.sort_key
    end

    local name_a = lower(a.display_name)
    local name_b = lower(b.display_name)

    if string.find(name_a, "^%([pi]%)") then
        name_a = sub(name_a, 4)
    end

    if string.find(name_b, "^%([pi]%)") then
        name_b = sub(name_b, 4)
    end

    ---@type string
    name_a = trim(name_a)
    ---@type string
    name_b = trim(name_b)

    -- Do integral comparison if they both start with integers
    local num_a = tonumber(string.match(name_a, "^%d+"))
    local num_b = tonumber(string.match(name_b, "^%d+"))
    if num_a and num_b and num_a ~= num_b then
        return num_a < num_b
    end

    return name_a < name_b
end

---@param travelnets { [integer]: travelnet_redo.Travelnet }
---@return travelnet_redo.Travelnet[]
local function sort_travelnets(travelnets)
    ---@type travelnet_redo.Travelnet[]
    local rtn = {}
    for _, def in pairs(travelnets) do
        rtn[#rtn + 1] = def
    end

    table.sort(rtn, travelnet_redo.travelnet_sort_compare)

    return rtn
end

local function emerge_and_callback(name, pos, callback)
    -- Range to preload
    local minp = vector.subtract(pos, 16)
    local maxp = vector.add(pos, 16)

    local stop_exec = false
    minetest.emerge_area(minp, maxp, function(blockpos, _, calls_remaining, _)
        if stop_exec then return end

        local player = minetest.get_player_by_name(name)
        if not player then -- Went offline?
            stop_exec = true
            return
        end

        -- Send the mapblock to the player
        player:send_mapblock(blockpos)

        -- Don't do thing until all mapblocks loaded
        if calls_remaining ~= 0 then return end

        -- Finally do the teleport
        callback()
    end)
end

local teleporting = {}
local function btn_event_tp_to(tp_pos)
    return function(player, ctx)
        local hash = minetest.hash_node_position(tp_pos)
        local network = travelnet_redo.get_network(ctx.network_id)
        local travelnet = network.travelnets[hash]
        if travelnet then
            local name = player:get_player_name()
            local prefix = string.sub(travelnet.display_name, 1, 3)
            if teleporting[name] then
                ctx.errmsg = minetest.get_color_escape_sequence("red") ..
                    S("Too fast!")
                return true
            elseif prefix == "(P)"
                and minetest.is_protected(travelnet.pos, name)
                and not travelnet_redo.can_edit_travelnet(travelnet.pos, name) then
                minetest.record_protection_violation(travelnet.pos, name)
                ctx.errmsg = minetest.get_color_escape_sequence("red") ..
                    S("Travelnet @1: Position protected!", travelnet.display_name)
                return true
            elseif prefix == "(I)"
                and not travelnet_redo.can_edit_travelnet(travelnet.pos, name) then
                ctx.errmsg = minetest.get_color_escape_sequence("red") ..
                    S("Travelnet @1: You cannot exit from this tgravelnet!", travelnet.display_name)
                return true
            end

            local callback = function()
                local node = minetest.get_node(travelnet.pos)
                local def = minetest.registered_nodes[node.name]
                local tp_func = def and def._travelnet_on_teleport or travelnet_redo.default_on_teleport
                tp_func(travelnet, node, player)

                teleporting[name] = nil
            end
            if hud then
                local hudname = f("tp_%d_%d_%d", travelnet.pos.x, travelnet.pos.y, travelnet.pos.z)
                hud:add(player, hudname, {
                    hud_elem_type = "text",
                    position = { x = 0.5, y = 0.5 },
                    offset = { x = 0, y = 40 },
                    text = S("Teleporting to @1...", travelnet.display_name),
                    text_scale = 1,
                    color = 0xFFD700,
                })
                local old_callback = callback
                callback = function()
                    old_callback()
                    hud:remove(player, hudname)
                end
            end
            if minetest.global_exists("background_music") then
                local old_callback = callback
                callback = function()
                    old_callback()
                    background_music.decide_and_play(player, true)
                end
            end
            teleporting[name] = true
            minetest.chat_send_player(name,
                minetest.colorize("#FFD700", S("Teleporting to @1...", travelnet.display_name)))
            emerge_and_callback(name, travelnet.pos, callback)
            travelnet_redo.gui_tp:close(player)
        else
            ctx.errmsg = minetest.get_color_escape_sequence("red") ..
                S("Travelnet @1: Not Found!", travelnet.display_name)
            return true
        end
    end
end

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    teleporting[name] = nil
end)

-- Height: 8 btns; Width 3 btns
-- Within 8 btns: center
-- 9~16: 2 columns
-- 17~24: 3 columns
-- 25+: ScrolableHBox, add columns right to screen
local function generate_btn_list(player, ctx, travelnets)
    local name = player:get_player_name()
    local this_pos = ctx.pos
    local this_travelnet = travelnet_redo.get_travelnet_from_map(this_pos)

    if not this_travelnet then
        return gui.Label {
            label = "Network not found"
        }
    end
    ctx.network_id = this_travelnet.network_id

    local sorted_travelnets = sort_travelnets(travelnets)
    local len_travelnets = #sorted_travelnets
    if len_travelnets == 0 then return gui.Nil {} end -- should not happen
    local btns = {}

    for i = 1, len_travelnets do
        local tvnet = sorted_travelnets[i]
        local prefix = string.sub(tvnet.display_name, 1, 3)

        -- luacheck: ignore 542
        if vector.equals(this_pos, tvnet.pos) then
            btns[#btns + 1] = gui.Button {
                w = 6, h = 1,
                label = S("[HERE] @1", tvnet.display_name),
                on_event = function(_, e_ctx)
                    e_ctx.errmsg = minetest.get_color_escape_sequence("green") ..
                        S("You are already at @1!", tvnet.display_name)
                    return true
                end,
                style = {
                    bgcolor = "green"
                },
            }
        elseif prefix == "(I)"
            and not travelnet_redo.can_edit_travelnet(tvnet.pos, name) then
            -- Enter only
        elseif prefix == "(P)"
            and minetest.is_protected(tvnet.pos, name)
            and not travelnet_redo.can_edit_travelnet(tvnet.pos, name) then
            -- Protected
            btns[#btns + 1] = gui.Button {
                w = 6, h = 1,
                label = tvnet.display_name,
                on_event = function(_, e_ctx)
                    e_ctx.errmsg = minetest.get_color_escape_sequence("red") ..
                        S("Travelnet @1 is protected!", tvnet.display_name)
                    return true
                end,
                style = {
                    bgcolor = "red"
                },
            }
        else
            btns[#btns + 1] = gui.Button {
                w = 6, h = 1,
                label = tvnet.display_name,
                on_event = btn_event_tp_to(tvnet.pos),
            }
        end
    end

    local columns = {}
    local col_length = math.max(math.ceil(#btns / 3), 8)
    for i = 1, #btns, col_length do
        local col = { unpack(btns, i, i + col_length - 1) }
        col.min_w = 6
        col.min_h = 8
        col.expand = true
        col.align_h = "center"
        columns[#columns + 1] = gui.VBox(col)
    end

    columns.min_w = 18
    columns.min_h = 8
    columns.name = "tvnet_btns"
    return gui.HBox(columns)
end

local function simple_error(msg)
    return gui.HBox {
        gui.Label {
            label = msg,
        },
        gui.ButtonExit {
            label = S("Exit")
        }
    }
end

travelnet_redo.gui_tp = flow.make_gui(function(player, ctx)
    if not ctx.pos then
        return simple_error("Attempt to run gui_tp without position")
    end
    local pos = ctx.pos
    local name = player:get_player_name(0)
    local this = travelnet_redo.get_travelnet_from_map(pos)
    if not this then
        return simple_error("Attempt to run gui_tp on unconfigured travelnet")
    end

    local network = travelnet_redo.get_network(this.network_id)
    if not network then
        -- orphaned
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", S("Unconfigured travelnet, rightclick/tap to configure"))
        meta:set_string("display_name", "")
        meta:set_int("network_id", 0)
        meta:set_string("travelnet_redo_configured", "")

        return gui.VBox {
            gui.Label {
                label = S("This travelnet is orphaned. Please set up again."),
            },
            gui.HBox {
                gui.Button {
                    label = S("Setup"),
                    expand = true,
                    on_event = function(e_player, e_ctx)
                        travelnet_redo.gui_tp:close(e_player)
                        _int.show_on_next_step(e_player, travelnet_redo.gui_setup, { pos = e_ctx.pos })
                    end,
                },
                gui.ButtonExit {
                    label = S("Exit"),
                    expand = true,
                },
            }
        }
    end

    local errmsg = ctx.errmsg
    ctx.errmsg = nil

    return gui.VBox {
        min_w = 18, min_h = 11.5,
        gui.HBox {
            gui.Label {
                w = 10, h = 0.5,
                label = S("Travelnet-box Teleport Interface"),
                expand = true, align_h = "left",
            },
            gui.Button {
                label = "(C)",
                w = 1, h = 1,
                on_event = function(e_player, e_ctx)
                    travelnet_redo.gui_setup:close(e_player)
                    _int.show_on_next_step(e_player, travelnet_redo.gui_attribution, {
                        old_ctx = e_ctx,
                        old_ui = travelnet_redo.gui_tp,
                    })
                end,
            },
            travelnet_redo.can_edit_travelnet(pos, name) and gui.Button {
                w = 1, h = 0.8,
                label = S("Edit"),
                on_event = function(e_player, e_ctx)
                    local e_name = e_player:get_player_name()
                    if not travelnet_redo.can_edit_travelnet(e_ctx.pos, e_name) then
                        ctx.errmsg = minetest.get_color_escape_sequence("red") ..
                            S("You can't edit this travelnet.")
                        return true
                    end

                    travelnet_redo.gui_tp:close(e_player)
                    _int.show_on_next_step(e_player, travelnet_redo.gui_edit, { pos = e_ctx.pos })
                end,
            } or gui.Nil {},
            gui.ButtonExit {
                w = 1, h = 0.8,
                label = S("Exit"),
            },
        },
        gui.Box { w = 0.05, h = 0.05, color = "grey" },
        gui.HBox {
            gui.Label {
                w = 8,
                label = S("Name of this travelnet: @1", this.display_name),
                expand = true,
            },
            gui.Label {
                w = 8,
                label = S("Network attached: @1@@@2 (#@3)",
                    network.network_name, network.network_owner, network.network_id),
                expand = true,
            },
        },
        gui.Label {
            w = 8, h = 0.5,
            label = errmsg or S("Click or tap on the destion you want to go to."),
        },
        generate_btn_list(player, ctx, network.travelnets)
    }
end)
