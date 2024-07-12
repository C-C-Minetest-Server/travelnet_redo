-- travelnet_redo/init.lua
-- Travelnet with improved performance and code tidiness
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

travelnet_redo = {}
travelnet_redo.internal = {}
travelnet_redo.internal.S = minetest.get_translator("travelnet_redo")
travelnet_redo.internal.logger = logging.logger("travelnet_redo")

local insecure = minetest.request_insecure_environment()
if not insecure then
	travelnet_redo.internal.logger:raise("Please add `travelnet_redo` into secure.trusted_mods.")
end

function travelnet_redo.internal.func_with_IE_env(func, ...)
	-- be sure that there is no hook, otherwise one could get IE via getfenv
	insecure.debug.sethook()

	local old_thread_env = insecure.getfenv(0)
	local old_string_metatable = insecure.debug.getmetatable("")

	-- set env of thread
	-- (the loader used by insecure.require will probably use the thread env for
	-- the loaded functions)
	insecure.setfenv(0, insecure)

	-- also set the string metatable because the lib might use it while loading
	-- (actually, we probably have to do this every time we call a `require()`d
	-- function, but for performance reasons we only do it if the function
	-- uses the string metatable)
	-- (Maybe it would make sense to set the string metatable __index field
	-- to a function that grabs the string table from the thread env.)
	insecure.debug.setmetatable("", { __index = insecure.string })

	-- (insecure.require's env is neither _G, nor insecure. we need to leave it like this,
	-- otherwise it won't find the loaders (it uses the global `loaders`, not
	-- `package.loaders` btw. (see luajit/src/lib_package.c)))

	-- we might be pcall()ed, so we need to pcall to make sure that we reset
	-- the thread env afterwards
	local ok, ret = insecure.pcall(func, ...)

	-- reset env of thread
	insecure.setfenv(0, old_thread_env)

	-- also reset the string metatable
	insecure.debug.setmetatable("", old_string_metatable)

	if not ok then
		insecure.error(ret)
	end
	return ret
end

-- luacheck: ignore 211
local ngx = nil

---@module 'pgmoon'
travelnet_redo.internal.pgmoon = travelnet_redo.internal.func_with_IE_env(insecure.require, "pgmoon")

local MP = minetest.get_modpath("travelnet_redo")
for _, name in ipairs({
	"settings",
	"privs",
	"db",              -- depends: settings
	"db_api",          -- depends: db
	"gui_attributions",
	"gui_setup",       -- runtime: db_api, privs, gui_tp, gui_atribution
	"gui_tp",          -- runtime: db_api, gui_edit, privs, gui_atribution, travelnet_api
	"gui_edit",        -- runtime: db_api, gui_tp, gui_atribution
	"travelnet_api",   -- depends: gui_setup, gui_tp
	"travelnet_register", -- depends: travelnet_api
	"chatcommand",     -- runtime: privs, db_api
}) do
	dofile(MP .. DIR_DELIM .. "src" .. DIR_DELIM .. name .. ".lua")
end

travelnet_redo.internal = nil
