-- travelnet_redo/src/gui_attribution.lua
-- Show license notice and GPL text
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

local _int = travelnet_redo.internal
local S = _int.S
local logger = _int.logger:sublogger("gui_setup")

local gui = flow.widgets

local notice = [[
    Copyright (C) 2013-2024  Sokomine, mt-mods members and contributors
    Copyright (C) 2024  1F616EMO

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

local media_notice = [[
    The models and textures as found in the textures/ and models/ folders
    where created by VanessaE and are provided under the CC0 license.

    Exceptions:

    * `textures/travelnet_top.png` CC BY-SA 3.0 from Minetest Game
            (`default_steel_block.png`)
    * `textures/travelnet_bottom.png` CC BY-SA 3.0 from Minetest Game
            (`default_clay.png`)

    CC0: <https://creativecommons.org/publicdomain/zero/1.0/>
    CC BY-SA 3.0: <https://creativecommons.org/licenses/by-sa/3.0/>
    Minetest Game: <https://github.com/minetest/minetest_game>
]]

local easteregg_text = [[
    meow~~ nya~~

    (Why did you scrol this deep lol)
]]

local full_text
do
    local file = io.open(minetest.get_modpath("travelnet_redo") .. DIR_DELIM .. "gpl-3.0.txt", "r")
    if file then
        full_text = file:read("*a")
        file:close()
    else
        logger:error("Error reading license text. The GPL text will not be avaliable in-game.")
        full_text = S("Error reading license text. For full text, see <https://www.gnu.org/licenses/>.")
    end
end

travelnet_redo.gui_attribution = flow.make_gui(function(_, ctx)
    return gui.VBox {
        min_w = 20,
        -- Header
        gui.HBox {
            gui.Label {
                w = 8,
                label = S("Licenses of Travelnet Redo"),
                expand = true, align_h = "left",
            },
            gui.Button {
                label = ctx.old_ctx and ctx.old_ui and S("Back") or S("Exit"),
                w = 1, h = 0.7,
                on_event = function(e_player, e_ctx)
                    travelnet_redo.gui_attribution:close(e_player)
                    if e_ctx.old_ctx and e_ctx.old_ui then
                        e_ctx.old_ui:show(e_player, e_ctx.old_ctx)
                    end
                end,
            },
        },
        gui.Box { w = 0.05, h = 0.05, color = "grey", padding = 0 },
        gui.ScrollableVBox {
            name = "scvb_licenses",
            w = 10, h = 15,
            gui.Textarea {
                w = 10,
                default = notice,
            },
            gui.Box { w = 0.05, h = 0.05, color = "grey", padding = 0 },
            gui.Textarea {
                w = 10,
                default = media_notice,
            },
            gui.Box { w = 0.05, h = 0.05, color = "grey", padding = 0 },
            gui.Textarea {
                w = 10,
                default = full_text,
            },
            gui.Box { w = 0.05, h = 0.05, color = "grey", padding = 0 },
            gui.Textarea {
                w = 10,
                default = easteregg_text,
            },
        }
    }
end)
