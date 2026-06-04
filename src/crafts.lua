-- travelnet_redo/src/crafts.lua
-- Built-in crafting recipes
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

local _int = travelnet_redo.internal
local S = _int.S

-- Un-program travelnet items
local function tvnet_unprogram(stack)
    if stack:is_empty() then
        return nil
    end

    stack = ItemStack(stack)
    local meta = stack:get_meta()

    if meta:get_string("tvnet_pp") == "" then
        return nil
    end

    local meta_t = meta:to_table()
    for key in pairs(meta_t.fields) do
        if key:sub(1, 8) == "tvnet_pp" then
            meta:set_string(key, "")
        end
    end

    meta:set_string("description", "")

    return stack
end

core.register_craft_predict(function(_, _, old_craft_grid)
    local new_stack
    for _, stack in ipairs(old_craft_grid) do
        local t_new_stack = tvnet_unprogram(stack)
        if t_new_stack and not new_stack then
            new_stack = t_new_stack
        elseif not stack:is_empty() then
            return nil
        end
    end

    if new_stack then
        new_stack:get_meta():set_string("description", S("Unprogrammed @1", new_stack:get_short_description()))
        return new_stack
    end
end)

core.register_on_craft(function(_, _, old_craft_grid, craft_inv)
    local new_stack
    for _, stack in ipairs(old_craft_grid) do
        local t_new_stack = tvnet_unprogram(stack)
        if t_new_stack and not new_stack then
            new_stack = t_new_stack
        elseif not stack:is_empty() then
            return nil
        end
    end

    if new_stack then
        craft_inv:set_list("craft", {})
        return new_stack
    end
end)