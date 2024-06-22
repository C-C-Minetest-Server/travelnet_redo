-- travelnet_redo/src/db.lua
-- Connect to the PostgreSQL database
-- depends: settings
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

local _int = travelnet_redo.internal
local logger = _int.logger:sublogger("db")
local pgmoon = _int.pgmoon

local f = string.format

local conn_options = {}
for key, value in string.gmatch(travelnet_redo.settings.pg_connection, "(%w+)=([^%s]+)") do
    conn_options[key] = value
end

local postgres = _int.func_with_IE_env(pgmoon.new, conn_options)
_int.postgres = postgres

function _int.query(...)
    return _int.func_with_IE_env(postgres.query, postgres, ...)
end

do
    local success, err = _int.func_with_IE_env(postgres.connect, postgres)
    if not success then
        logger:raise("Connect to database failed: %s", err)
    end
end

do
    -- Load initial schema
    local file = assert(io.open(minetest.get_modpath("travelnet_redo") .. "/init.sql"))
    local q = file:read("*a")
    file:close()

    local res, err = _int.query(q)
    if not res then
        logger:raise("Load initial schema failed: %s", err)
    end
end

postgres:settimeout(2000) -- 2 seconds

---Methods that directly read/write the database
---Use methods with caching capability whenever possible
---@class travelnet_redo.internal.database
local _db = {}
_int.database = _db

-- Read functions

function _db.get_travelnet_by_hash(hash)
    return _int.query(f(
        "SELECT tvnet_pos_hash, tvnet_display_name, tvnet_network_id, tvnet_sort_key " ..
        "FROM travelnet_redo_travelnets " ..
        "WHERE tvnet_pos_hash = %d;", hash))
end

function _db.get_travelnet_by_name_id(name, id)
    return _int.query(f(
        "SELECT tvnet_pos_hash, tvnet_display_name, tvnet_network_id, tvnet_sort_key " ..
        "FROM travelnet_redo_travelnets " ..
        "WHERE tvnet_display_name = %s AND tvnet_network_id = %d;",
        postgres:escape_literal(name), id))
end

function _db.get_network_by_id(network_id)
    return _int.query(f(
        "SELECT network_id, network_name, network_owner, network_always_cache " ..
        "FROM travelnet_redo_networks " ..
        "WHERE network_id = %d;", network_id))
end

function _db.get_network_by_name_owner(name, owner)
    return _int.query(f(
        "SELECT network_id, network_name, network_owner, network_always_cache " ..
        "FROM travelnet_redo_networks " ..
        "WHERE network_name = %s AND network_owner = %s;",
        postgres:escape_literal(name), postgres:escape_literal(owner)))
end

function _db.get_network_by_always_cache(cache)
    if cache == nil then cache = true end

    return _int.query(f(
        "SELECT network_id, network_name, network_owner, network_always_cache " ..
        "FROM travelnet_redo_networks " ..
        "WHERE network_always_cache = %s;",
        postgres:escape_literal(cache)))
end

function _db.get_travelnets_in_network(network_id)
    return _int.query(f(
        "SELECT t.tvnet_pos_hash AS tvnet_pos_hash, " ..
        "t.tvnet_display_name AS tvnet_display_name, " ..
        "t.tvnet_network_id AS tvnet_network_id, " ..
        "t.tvnet_sort_key AS tvnet_sort_key " ..
        "FROM travelnet_redo_travelnets AS t " ..
        "JOIN travelnet_redo_networks AS n " ..
        "ON t.tvnet_network_id = n.network_id " ..
        "WHERE n.network_id = %d;", network_id))
end

function _db.get_travelnets_in_network_by_name_owner(name, owner)
    return _int.query(f(
        "SELECT t.tvnet_pos_hash AS tvnet_pos_hash, " ..
        "t.tvnet_display_name AS tvnet_display_name, " ..
        "t.tvnet_network_id AS tvnet_network_id " ..
        "t.tvnet_sort_key AS tvnet_sort_key " ..
        "FROM travelnet_redo_travelnets AS t " ..
        "JOIN travelnet_redo_networks AS n " ..
        "ON t.tvnet_network_id = n.network_id " ..
        "WHERE network_name = %s AND network_owner = %s;",
        postgres:escape_literal(name), postgres:escape_literal(owner)))
end

-- Write functions

function _db.insert_travelnet_network(name, owner)
    return _int.query(f(
        "INSERT INTO travelnet_redo_networks (network_name, network_owner) " ..
        "VALUES (%s, %s) " ..
        "RETURNING network_id AS v_network_id;",
        postgres:escape_literal(name), postgres:escape_literal(owner)))
end

function _db.change_network_owner(network_id, name)
    return _int.query(f(
        "UPDATE travelnet_redo_networks " ..
        "SET network_owner = %s " ..
        "WHERE network_id = %d;", postgres:escape_literal(name), network_id))
end

function _db.set_travelnet_always_cache(network_id, always_cache)
    return _int.query(f(
        "UPDATE travelnet_redo_networks " ..
        "SET network_always_cache = %s " ..
        "WHERE network_id = %d;", always_cache and "TRUE" or "FALSE", network_id))
end

function _db.delete_travelnet_network(network_id)
    return _int.query(f(
        "DELETE FROM travelnet_redo_networks " ..
        "WHERE network_id = %d;", network_id))
end

function _db.delete_travelnet_network_by_name_owner(name, owner)
    return _int.query(f(
        "DELETE FROM travelnet_redo_networks " ..
        "WHERE network_name = %s AND network_owner = %s;",
        postgres:escape_literal(name), postgres:escape_literal(owner)))
end

function _db.add_travelnet(pos_hash, display_name, network_id, sort_key)
    return _int.query(f(
        "INSERT INTO travelnet_redo_travelnets " ..
        "(tvnet_pos_hash, tvnet_display_name, tvnet_network_id, tvnet_sort_key) " ..
        "VALUES (%d, %s, %d, %d);",
        pos_hash, postgres:escape_literal(display_name), network_id, sort_key))
end

function _db.update_travelnet(pos_hash, display_name, network_id, sort_key)
    return _int.query(f(
        "UPDATE travelnet_redo_travelnets " ..
        "SET tvnet_display_name = %s, " ..
        "tvnet_network_id = %d " ..
        "tvnet_sort_key = %d " ..
        "WHERE tvnet_pos_hash = %d;",
        postgres:escape_literal(display_name), network_id, pos_hash, sort_key))
end

function _db.remove_travelnet(pos_hash)
    return _int.query(f(
        "DELETE FROM travelnet_redo_travelnets " ..
        "WHERE tvnet_pos_hash = %d;",
        pos_hash))
end

minetest.register_on_shutdown(function()
    _int.func_with_IE_env(postgres.disconnect, postgres)
end)
