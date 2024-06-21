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

function travelnet_redo.register_default_travelnet(name, description, color, light)
    travelnet_redo.register_travelnet(name, {
        description = description,
        drawtype = "mesh",
        mesh = "travelnet.obj",
        sunlight_propagates = true,
        paramtype = "light",
        paramtype2 = "facedir",
        wield_scale = { x = 0.6, y = 0.6, z = 0.6 },
        selection_box = node_box,
        collision_box = node_box,
        on_rotate = minetest.global_exists("screwdriver") and screwdriver.rotate_simple or nil,

        tiles = {
            "(travelnet_travelnet_front_color.png^[multiply:" .. color .. ")^travelnet_travelnet_front.png", -- backward
            "(travelnet_travelnet_back_color.png^[multiply:" .. color .. ")^travelnet_travelnet_back.png", -- front view
            "(travelnet_travelnet_side_color.png^[multiply:" .. color .. ")^travelnet_travelnet_side.png", -- sides :)
            "travelnet_top.png",                                                                    -- view from top
            "travelnet_bottom.png",                                                                 -- view from bottom
        },

        use_texture_alpha = "clip",
        inventory_image = "travelnet_inv_base.png^(travelnet_inv_colorable.png^[multiply:" .. color .. ")",
        is_ground_content = false,
        groups = { cracky = 3, pickaxey=1, transport=1 },
        sounds = xcompat.sounds.node_sound_glass_defaults(),
        light_source = light or 10,
    })
end

local default_travelnets = {
    ["travelnet_redo:travelnet_yellow"] = {
        dye = xcompat.materials.dye_yellow,
        color = "#e0bb2d",
        description = S("@1 Travelnet-Box", S("Yellow")),
    },
    ["travelnet_redo:travelnet_red"] = {
        dye = xcompat.materials.dye_red,
        color = "#ce1a1a",
        description = S("@1 Travelnet-Box", S("Red")),
    },
    ["travelnet_redo:travelnet_orange"] = {
        dye = xcompat.materials.dye_orange,
        color = "#e2621b",
        description = S("@1 Travelnet-Box", S("Orange")),
    },
    ["travelnet_redo:travelnet_blue"] = {
        dye = xcompat.materials.dye_blue,
        color = "#0051c5",
        description = S("@1 Travelnet-Box", S("Blue")),
    },
    ["travelnet_redo:travelnet_cyan"] = {
        dye = xcompat.materials.dye_cyan,
        color = "#00a6ae",
        description = S("@1 Travelnet-Box", S("Cyan")),
    },
    ["travelnet_redo:travelnet_green"] = {
        dye = xcompat.materials.dye_green,
        color = "#53c41c",
        description = S("@1 Travelnet-Box", S("Green")),
    },
    ["travelnet_redo:travelnet_dark_green"] = {
        dye = xcompat.materials.dye_dark_green,
        color = "#2c7f00",
        description = S("@1 Travelnet-Box", S("Dark Green")),
    },
    ["travelnet_redo:travelnet_violet"] = {
        dye = xcompat.materials.dye_violet,
        color = "#660bb3",
        description = S("@1 Travelnet-Box", S("Violet")),
    },
    ["travelnet_redo:travelnet_pink"] = {
        dye = xcompat.materials.dye_pink,
        color = "#ff9494",
        description = S("@1 Travelnet-Box", S("Pink")),
    },
    ["travelnet_redo:travelnet_magenta"] = {
        dye = xcompat.materials.dye_magenta,
        color = "#d10377",
        description = S("@1 Travelnet-Box", S("Magenta")),
    },
    ["travelnet_redo:travelnet_brown"] = {
        dye = xcompat.materials.dye_brown,
        color = "#572c00",
        description = S("@1 Travelnet-Box", S("Brown")),
    },
    ["travelnet_redo:travelnet_grey"] = {
        dye = xcompat.materials.dye_grey,
        color = "#a2a2a2",
        description = S("@1 Travelnet-Box", S("Grey")),
    },
    ["travelnet_redo:travelnet_dark_grey"] = {
        dye = xcompat.materials.dye_dark_grey,
        color = "#3d3d3d",
        description = S("@1 Travelnet-Box", S("Dark Grey")),
    },
    ["travelnet_redo:travelnet_black"] = {
        dye = xcompat.materials.dye_black,
        color = "#0f0f0f",
        light = 1, -- Original: 0
        description = S("@1 Travelnet-Box", S("Black")),
    },
    ["travelnet_redo:travelnet_white"] = {
        dye = xcompat.materials.dye_white,
        color = "#ffffff",
        light = minetest.LIGHT_MAX,
        description = S("@1 Travelnet-Box", S("White")),
    },
}

for name, cfg in pairs(default_travelnets) do
    travelnet_redo.register_default_travelnet(name, cfg.description, cfg.color, cfg.light)

    if cfg.dye then
        minetest.register_craft({
            output = name,
            type = "shapeless",
            recipe = { "group:travelnet_redo", cfg.dye },
        })
    end
end

minetest.register_craft({
    output = "travelnet_redo:travelnet_yellow",
    recipe = {
        { xcompat.materials.glass, xcompat.materials.steel_ingot, xcompat.materials.glass },
        { xcompat.materials.glass, xcompat.materials.mese,        xcompat.materials.glass },
        { xcompat.materials.glass, xcompat.materials.steel_ingot, xcompat.materials.glass },
    }
})
