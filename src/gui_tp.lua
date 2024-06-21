-- travelnet_redo/src/gui_tp.lua
-- GUI for using a travelnet
-- runtime: db_api, privs
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

local _int = travelnet_redo.internal
local S = _int.S
-- local logger = _int.logger:sublogger("gui_tp")

local gui = flow.widgets
local hud = minetest.global_exists("mhud") and mhud.init()

local f = string.format

---@param travelnets { [integer]: travelnet_redo.Travelnet }
---@return travelnet_redo.Travelnet[]
local function sort_travelnets(travelnets)
    ---@type travelnet_redo.Travelnet[]
    local rtn = {}
    for _, def in pairs(travelnets) do
        rtn[#rtn + 1] = def
    end

    table.sort(rtn, function(a, b)
        local name_a = a.display_name
        local name_b = b.display_name

        if string.sub(name_a, 1, 3) == "(P)" then
            name_a = string.sub(name_a, 4)
        end

        if string.sub(name_b, 1, 3) == "(P)" then
            name_b = string.sub(name_b, 4)
        end

        ---@type string
        name_a = string.trim(name_a)
        ---@type string
        name_b = string.trim(name_b)

        return name_a < name_b
    end)

    return rtn
end

local function emerge_and_teleport(name, pos, callback)
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
        player:set_pos(pos)
        callback()
    end)
end

local function btn_event_tp_to(tp_pos)
    return function(player, ctx)
        local hash = minetest.hash_node_position(tp_pos)
        local network = travelnet_redo.get_network(ctx.network_id)
        local travelnet = network.travelnets[hash]
        if travelnet then
            local name = player:get_player_name()
            if string.sub(travelnet.display_name, 1, 3) == "(P)" then
                if minetest.is_protected(travelnet.pos, name) then
                    minetest.record_protection_violation(travelnet.pos, name)
                    ctx.errmsg = S("Travelnet @1: Position protected!", travelnet.display_name)
                    return true
                end
            end

            local callback = function()
                local node = minetest.get_node(travelnet.pos)

                if node.param2 > 3 then
                    node.param2 = 0
                    minetest.swap_node(travelnet.pos, node)
                end

                local dir  = vector.multiply(minetest.facedir_to_dir(node.param2), -1)
                local yaw  = minetest.dir_to_yaw(dir)

                player:set_look_horizontal(yaw)
                player:set_look_vertical(math.pi * 10 / 180)

                minetest.sound_play("travelnet_travel", {
                    pos = travelnet.pos,
                    gain = 0.75,
                    max_hear_distance = 10
                })
            end
            if hud then
                local hudname = f("tp_%d_%d_%d", travelnet.pos.x, travelnet.pos.y, travelnet.pos.z)
                hud:add(player, hudname, {
                    hud_elem_type = "text",
                    position = { x = 0.5, y = 0.5 },
                    offset = { x = 0, y = 40 },
                    text = S("Teleporting..."),
                    text_scale = 1,
                    color = 0xFFD700,
                })
                local old_callback = callback
                callback = function()
                    old_callback()
                    hud:remove(player, hudname)
                end
            end
            minetest.chat_send_player(name, minetest.colorize("#FFD700", S("Teleporting...")))
            emerge_and_teleport(name, travelnet.pos, callback)
            travelnet_redo.gui_tp:close(player)
        else
            ctx.errmsg = S("Travelnet @1: Not Found!", travelnet.display_name)
            return true
        end
    end
end

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
    local col_length = math.max(math.ceil(len_travelnets / 3), 8)
    local columns = {}
    for base = 1, len_travelnets, col_length do
        local col = {}
        for i = base, math.min(base + col_length - 1, len_travelnets) do
            local tvnet = sorted_travelnets[i]

            local btn = {
                w = 6,
                h = 1,
                label = tvnet.display_name,
            }
            if vector.equals(this_pos, tvnet.pos) then
                btn.style = {
                    bgcolor = "green"
                }
                btn.label = S("[HERE] @1", btn.label)
            elseif string.sub(tvnet.display_name, 1, 3) == "(P)" then
                if minetest.is_protected(tvnet.pos, name) then
                    btn.style = {
                        bgcolor = "red"
                    }
                end
            else
                btn.on_event = btn_event_tp_to(tvnet.pos)
            end
            col[#col + 1] = gui.Button(btn)
        end

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

    local this = travelnet_redo.get_travelnet_from_map(pos)
    if not this then
        return simple_error("Attempt to run gui_tp on unconfigured travelnet")
    end

    local network = travelnet_redo.get_network(this.network_id)
    if not network then
        -- orphaned
        return simple_error("Orphaned travelnet. Please dig it and set up again.")
    end

    local errmsg = ctx.errmsg
    ctx.errmsg = nil

    return gui.VBox {
        min_w = 18, min_h = 10.5,
        gui.HBox {
            gui.Label {
                w = 10, h = 0.5,
                label = S("Travelnet-box Teleport Interface"),
                expand = true, align_h = "left",
            },
            gui.ButtonExit {
                w = 1, h = 0.5,
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
            w = 10,
            label = errmsg and minetest.colorize("red", errmsg) or S("Click or tap on the destion you want to go to.")
        },
        generate_btn_list(player, ctx, network.travelnets)
    }
end)
