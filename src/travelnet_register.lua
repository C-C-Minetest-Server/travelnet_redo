-- travelnet_redo/src/travelnet_register.lua
-- Really register travelnets
-- depends: travelnet_api
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

local _int = travelnet_redo.internal
local S = _int.S
-- local logger = _int.logger:sublogger("travelnet_register")

local node_box = {
    type = "fixed",
    fixed = {
        { -0.5,   -0.5,   0.4375, 0.5,     1.5,     0.5 }, -- Back
        { -0.5,   -0.5,   -0.5,   -0.4375, 1.5,     0.5 }, -- Right
        { 0.4375, -0.5,   -0.5,   0.5,     1.5,     0.5 }, -- Left
        { -0.5,   -0.5,   -0.5,   0.5,     -0.4375, 0.5 }, -- Floor
        { -0.5,   1.4375, -0.5,   0.5,     1.5,     0.5 }, -- Roof
    }
}

local dye_to_travelnet = {}
local function on_punch(pos, node, player)
    if not player:is_player() then return end
    local wield = player:get_wielded_item()
    local new_travelnet = dye_to_travelnet[wield:get_name()]
    if new_travelnet and new_travelnet ~= node.name then
        local name = player:get_player_name()
        if not travelnet_redo.can_edit_travelnet(pos, name) then return end

        if not core.is_creative_enabled(name) then
            wield:take_item()
            player:set_wielded_item(wield)
        end

        node.name = new_travelnet
        core.swap_node(pos, node)
    end
end

local placeholder_box = {
    type = "fixed",
    fixed = { -0.5, 0.4375 , -0.5,   0.5,     0.5,     0.5 }
}
local placeholder_registered = {}

core.register_lbm({
    label = "Replace old Travelnet placeholders",
    name = "travelnet_redo:replace_old_placeholder",
    nodenames = { "travelnet_redo:placeholder" },
    run_at_every_load = false,
    action = function(pos, node)
        local below = vector.new(pos.x, pos.y - 1, pos.z)
        local below_node = core.get_node(below)
        local below_def = core.registered_nodes[below_node.name]
        local light = below_def and below_def.light_source or 0
        if placeholder_registered[light] then
            node.name = "travelnet_redo:placeholder_" .. light
            core.swap_node(pos, node)
        else
            core.remove_node(pos)
        end
    end,
})

function travelnet_redo.boxlike_on_teleport(travelnet, node, player)
    player:set_pos(vector.add(travelnet.pos, vector.new(0, -0.4, 0)))

    local dir = vector.multiply(core.facedir_to_dir(node.param2), -1)
    local yaw = core.dir_to_yaw(dir)

    player:set_look_horizontal(yaw)
    player:set_look_vertical(math.pi * 10 / 180)

    core.sound_play("travelnet_travel", {
        pos = travelnet.pos,
        gain = 0.75,
        max_hear_distance = 10
    })
end

function travelnet_redo.register_boxlike_travelnet(name, def)
    local light = def.light_source or 10
    local placeholder_name = "travelnet_redo:placeholder_" .. light
    if not placeholder_registered[light] then
        placeholder_registered[light] = true
        core.register_node(placeholder_name, {
            drawtype = "airlike",
            paramtype = "light",
            sunlight_propagates = true,
            pointable = false,
            diggable = false,
            buildable_to = false,
            light_source = light,
            drop = "",
            is_ground_content = false,
            collision_box = placeholder_box,
            sounds = xcompat.sounds.node_sound_glass_defaults(),
        })
    end

    local reg_def = {
        drawtype = "mesh",
        mesh = "travelnet.obj",
        sunlight_propagates = true,
        paramtype = "light",
        paramtype2 = "facedir",
        wield_scale = { x = 0.6, y = 0.6, z = 0.6 },
        selection_box = node_box,
        collision_box = node_box,
        on_rotate = core.global_exists("screwdriver") and screwdriver.rotate_simple or nil,
        use_texture_alpha = "clip",

        on_punch = on_punch,

        on_construct = function(pos)
            local up = vector.new(pos.x, pos.y + 1, pos.z)
            local up_node = core.get_node_or_nil(up)
            if up_node then
                local up_def = core.registered_nodes[up_node.name]
                if up_def and up_def.buildable_to then
                    core.set_node(up, { name = placeholder_name })
                end
            end
        end,

        on_destruct = function(pos)
            local up = vector.new(pos.x, pos.y + 1, pos.z)
            if core.get_node(up).name == placeholder_name then
                core.remove_node(up)
            end
        end,

        _travelnet_on_teleport = travelnet_redo.boxlike_on_teleport,
    }

    for k, v in pairs(def) do
        reg_def[k] = v
    end
    travelnet_redo.register_travelnet(name, reg_def)
end

function travelnet_redo.register_default_travelnet(name, description, tiles, inventory_image, light, sounds)
    travelnet_redo.register_boxlike_travelnet(name, {
        description = description,
        tiles = tiles,
        inventory_image = inventory_image,
        light_source = light or 10,
        groups = {
            cracky = 3,
            pickaxey = 1,
            transport = 1,
            travelnet_redo_default = 1,
            travelnet_redo_walkin_open = 1
        },
        sounds = sounds or xcompat.sounds.node_sound_glass_defaults(),
    })
end

local materials = core.global_exists("xcompat") and xcompat.materials or nil

local default_travelnets = {
    ["travelnet_redo:travelnet_yellow"] = {
        dye = materials and materials.dye_yellow,
        color = "#e0bb2d",
        description = S("@1 Travelnet-Box", S("Yellow")),
    },
    ["travelnet_redo:travelnet_red"] = {
        dye = materials and materials.dye_red,
        color = "#ce1a1a",
        description = S("@1 Travelnet-Box", S("Red")),
    },
    ["travelnet_redo:travelnet_orange"] = {
        dye = materials and materials.dye_orange,
        color = "#e2621b",
        description = S("@1 Travelnet-Box", S("Orange")),
    },
    ["travelnet_redo:travelnet_blue"] = {
        dye = materials and materials.dye_blue,
        color = "#0051c5",
        description = S("@1 Travelnet-Box", S("Blue")),
    },
    ["travelnet_redo:travelnet_cyan"] = {
        dye = materials and materials.dye_cyan,
        color = "#00a6ae",
        description = S("@1 Travelnet-Box", S("Cyan")),
    },
    ["travelnet_redo:travelnet_green"] = {
        dye = materials and materials.dye_green,
        color = "#53c41c",
        description = S("@1 Travelnet-Box", S("Green")),
    },
    ["travelnet_redo:travelnet_dark_green"] = {
        dye = materials and materials.dye_dark_green,
        color = "#2c7f00",
        description = S("@1 Travelnet-Box", S("Dark Green")),
    },
    ["travelnet_redo:travelnet_violet"] = {
        dye = materials and materials.dye_violet,
        color = "#660bb3",
        description = S("@1 Travelnet-Box", S("Violet")),
    },
    ["travelnet_redo:travelnet_pink"] = {
        dye = materials and materials.dye_pink,
        color = "#ff9494",
        description = S("@1 Travelnet-Box", S("Pink")),
    },
    ["travelnet_redo:travelnet_magenta"] = {
        dye = materials and materials.dye_magenta,
        color = "#d10377",
        description = S("@1 Travelnet-Box", S("Magenta")),
    },
    ["travelnet_redo:travelnet_brown"] = {
        dye = materials and materials.dye_brown,
        color = "#572c00",
        description = S("@1 Travelnet-Box", S("Brown")),
    },
    ["travelnet_redo:travelnet_grey"] = {
        dye = materials and materials.dye_grey,
        color = "#a2a2a2",
        description = S("@1 Travelnet-Box", S("Grey")),
    },
    ["travelnet_redo:travelnet_dark_grey"] = {
        dye = materials and materials.dye_dark_grey,
        color = "#3d3d3d",
        description = S("@1 Travelnet-Box", S("Dark Grey")),
    },
    ["travelnet_redo:travelnet_black"] = {
        dye = materials and materials.dye_black,
        color = "#0f0f0f",
        light = 1, -- Original: 0
        description = S("@1 Travelnet-Box", S("Black")),
    },
    ["travelnet_redo:travelnet_white"] = {
        dye = materials and materials.dye_white,
        color = "#ffffff",
        light = core.LIGHT_MAX,
        description = S("@1 Travelnet-Box", S("White")),
    },
}

for name, cfg in pairs(default_travelnets) do
    local tiles = {
        "(travelnet_travelnet_front_color.png^[multiply:" .. cfg.color .. ")^travelnet_travelnet_front.png",
        "(travelnet_travelnet_back_color.png^[multiply:" .. cfg.color .. ")^travelnet_travelnet_back.png",
        "(travelnet_travelnet_side_color.png^[multiply:" .. cfg.color .. ")^travelnet_travelnet_side.png",
        "travelnet_top.png",
        "travelnet_bottom.png",
    }
    local inventory_image = "travelnet_inv_base.png^(travelnet_inv_colorable.png^[multiply:" .. cfg.color .. ")"
    travelnet_redo.register_default_travelnet(name, cfg.description, tiles, inventory_image, cfg.light)

    if cfg.dye then
        core.register_craft({
            output = name,
            type = "shapeless",
            recipe = { "group:travelnet_redo_default", cfg.dye },
        })

        dye_to_travelnet[cfg.dye] = name
    end
end

if materials then
    core.register_craft({
        output = "travelnet_redo:travelnet_yellow",
        recipe = {
            { materials.glass, materials.steel_ingot, materials.glass },
            { materials.glass, materials.mese,        materials.glass },
            { materials.glass, materials.steel_ingot, materials.glass },
        }
    })
end

-- travelnet_redo_walkin_open

local last_seen_pos = {}

modlib.minetest.register_globalstep(0.5, function()
    if not travelnet_redo.settings.walkin_open then return end
    for _, player in ipairs(core.get_connected_players()) do
        local name = player:get_player_name()
        local last_seen = last_seen_pos[name]
        local pos = vector.round(player:get_pos())
        if last_seen and not vector.equals(last_seen, pos) then
            local node = core.get_node(pos)
            local def = core.registered_nodes[node.name]
            local groups = def and def.groups
            if groups and groups.travelnet_redo_walkin_open then
                local travelnet = travelnet_redo.get_travelnet_from_map(pos)
                if travelnet then
                    local network = travelnet_redo.get_network(travelnet.network_id)
                    if network then
                        travelnet_redo.gui_tp_open_at(player, pos)
                    end
                end
            end
        end
        last_seen_pos[name] = pos
    end
end)

travelnet_redo.register_on_teleport(function(player, _, travelnet)
    local name = player:get_player_name()
    local pos = travelnet.pos
    last_seen_pos[name] = pos
end)

core.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    last_seen_pos[name] = nil
end)