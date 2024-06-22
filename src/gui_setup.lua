-- travelnet_redo/src/gui_setup.lua
-- GUI for setting up a travelnet
-- runtime: db_api, privs, gui_tp
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

local _int = travelnet_redo.internal
local S = _int.S
local logger = _int.logger:sublogger("gui_setup")

local f = string.format
local gui = flow.widgets

local function check_can_setup(name, pos)
    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]
    if not (def and def.groups and def.groups.travelnet_redo) then
        return "Attempt to run gui_setup on non-travelnet"
    end

    if travelnet_redo.get_travelnet_from_map(pos) then
        return "Attempt to run gui_setup on configured travelnet"
    end

    if minetest.is_protected(pos, name) then
        minetest.record_protection_violation(pos, name)
        return "Attempt to set up travelnet not owned by you"
    end
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

local function on_save(player, ctx)
    local name = player:get_player_name()
    local pos = ctx.pos
    local rtnmsg = check_can_setup(name, pos)
    if rtnmsg then
        minetest.chat_send_player(name, rtnmsg)
        travelnet_redo.gui_setup:close(player)
        return
    end

    local display_name  = string.trim(ctx.form.display_name)
    local network_name  = string.trim(ctx.form.network_name)
    local network_owner = string.trim(ctx.form.network_owner)
    local sort_key      = tonumber(string.trim(ctx.form.sort_key))

    if not network_owner or network_owner == "" then
        network_owner = name
    end

    if not display_name or display_name == "" then
        ctx.errmsg = S("Display name not given")
        return true
    elseif not network_name or network_name == "" then
        ctx.errmsg = S("Network name not given")
        return true
    elseif string.len(display_name) > 40 then
        ctx.errmsg = S("Length of display name cannot exceed 40")
        return true
    elseif string.len(network_name) > 40 then
        ctx.errmsg = S("Length of network name cannot exceed 40")
        return true
    elseif network_owner ~= name and not minetest.check_player_privs(name, { travelnet_attach = true }) then
        ctx.errmsg = S("Insufficant privilege to attach travelnets!")
        return true
    elseif string.len(network_owner) > 20 then
        ctx.errmsg = S("Length of owner name cannot exceed 20")
        return true
    elseif not sort_key or sort_key < -32768 or sort_key > 32767 then
        ctx.errmsg = S("Invalid sorting key!")
        return true
    end

    local network_id = travelnet_redo.create_or_get_network(network_name, network_owner)

    if travelnet_redo.get_travelnet_by_name_id(display_name, network_id) then
        ctx.errmsg = S("Travelnet of the same name already exists")
        return true
    end
    travelnet_redo.add_travelnet(pos, display_name, network_id, sort_key)

    local meta = minetest.get_meta(pos)
    meta:set_string("infotext",
        S("Travelnet @1 in @2@@@3, rightclick/tap to teleport.", display_name, network_name, network_owner))

    logger:action("%s set up travelnet at %s, name = %s, network = %s@%s (#%d), sort_key = %d",
        name, minetest.pos_to_string(pos), display_name, network_name, network_owner, network_id, sort_key
    )
    travelnet_redo.gui_setup:close(player)
    travelnet_redo.gui_tp:show(player, { pos = pos })
end

travelnet_redo.gui_setup = flow.make_gui(function(player, ctx)
    if not ctx.pos then
        return simple_error("Attempt to run gui_setup without position")
    end
    local pos = ctx.pos

    local name = player:get_player_name()
    local rtnmsg = check_can_setup(name, pos)
    if rtnmsg then
        return simple_error(rtnmsg)
    end

    local errmsg = ctx.errmsg
    ctx.errmsg = nil

    return gui.VBox {
        min_w = 10,
        -- Header
        gui.HBox {
            gui.Label {
                label = S("Configure this travelnet station"),
                expand = true, align_h = "left",
            },
            gui.ButtonExit {
                label = "x",
                w = 0.7, h = 0.7,
            },
        },
        gui.Box { w = 0.05, h = 0.05, color = "grey", padding = 0 },

        -- Contents
        errmsg and gui.Label {
            label = minetest.colorize("red", errmsg),
        } or gui.Nil {},

        gui.Label {
            label =
                S("Name of this station, prepend \"(P)\" to protect this station:") .. "\n" ..
                S("What do you call this place here? Example: \"my first house\", \"mine\", \"shop\"..."),
        },
        gui.Field {
            name = "display_name",
        },

        gui.Label {
            label =
                S("Assign to network:") .. "\n" ..
                S("You can have more than one network. If unsure, use \"@1\".",
                    travelnet_redo.settings.default_network),
        },
        gui.Field {
            name = "network_name",
            default = travelnet_redo.settings.default_network,
        },

        gui.HBox {
            gui.VBox {
                expand = true,
                gui.Label {
                    w = 5,
                    label =
                        S("Owned by:") .. "\n" ..
                        S("Unless you know what you are doing, leave this as is.")
                },
                gui.Field {
                    name = "network_owner",
                    default = name,
                },
            },
            gui.VBox {
                w = 5,
                gui.Label {
                    w = 5,
                    label =
                        S("Sort key:") .. "\n" ..
                        S("Integer defining the order, the smaller the upper.")
                },
                gui.Field {
                    name = "sort_key",
                    default = "0",
                },
            },
        },

        gui.HBox {
            gui.Button {
                w = 3, h = 1,
                label = S("Save"),
                expand = true, align_h = "right",
                on_event = on_save,
            },
            gui.Button {
                w = 3, h = 1,
                label = S("Exit"),
            }
        }
    }
end)
