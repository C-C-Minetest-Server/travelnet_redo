-- travelnet_redo/src/db_api.lua
-- High level API handling data and cache
-- depends: db
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: GPL-3.0-or-later

local _int = travelnet_redo.internal
local logger = _int.logger:sublogger("db_api")
local S = _int.S
local _db = _int.database
local settings = travelnet_redo.settings

---@type { [integer]: travelnet_redo.TravelnetNetwork }
local cache = {}
_int.cache = cache

--[[
    Cache rules:
    1. Those with `network_always_cache` = TRUE are always cached
    2. Upon querying a network, it is cached for a configurable period
        (travelnet_redo.settings.cache_duration)

    We only cache for read operations.
    All write operations directly goes to the DB and of course, the cache if any.
]]

---A table containing data of a travelnet
---@class travelnet_redo.Travelnet: table
---@field pos vector The position of the travelnet
---@field display_name string The display name of the travelnet
---@field network_id string The ID of the network ths travelnet belongs to
---@field sort_key integer The sorting key of the travelnet when showed on gui_tp

---A table containing data of a travelnet network
---@class travelnet_redo.TravelnetNetwork: table
---@field network_id integer The ID of the network
---@field network_name string The name of the network
---@field network_owner string The owner of the network
---@field always_cache boolean Whether this network should always be cached
---@field travelnets { integer: travelnet_redo.Travelnet } List of travelnets belonging to this network, indexed: hash

-- Read functions

-- function travelnet_redo.get_travelnet_in_db(pos)
--     local hash = minetest.hash_node_position(pos)
--     local res, err = _db.get_travelnet_by_hash(hash)

--     if not res then
--         logger:raise(f("Failed to get travelnet at %s: %s",
--             minetest.pos_to_string(pos), err))
--     end

--     return {
--         pos = pos,
--         display_name = res[1].tvnet_display_name,
--         network_id = res[1].tvnet_network_id,
--         sort_key = res[1].tvnet_sort_key,
--     }
-- end

---Get travelnet from the map
---@return travelnet_redo.Travelnet?
function travelnet_redo.get_travelnet_from_map(pos)
    local meta = minetest.get_meta(pos)

    if meta:get_string("travelnet_redo_configured") == "" then
        return nil
    end

    return {
        pos = pos,
        display_name = meta:get_string("display_name"),
        network_id = meta:get_int("network_id"),
        sort_key = meta:get_int("sort_key")
    }
end

---Get travelnet by display name and network ID
---@return travelnet_redo.Travelnet?
function travelnet_redo.get_travelnet_by_name_id(display_name, network_id)
    local res, err = _db.get_travelnet_by_name_id(display_name, network_id)

    if not res then
        logger:raise("Failed to get travelnet %s@#%d: %s",
            display_name, network_id, err)
    end

    if #res == 0 then return nil end

    return {
        pos = minetest.get_position_from_hash(res[1].tvnet_pos_hash),
        display_name = res[1].tvnet_display_name,
        network_id = network_id,
        sort_key = res[1].tvnet_sort_key,
    }
end

---Get travelnets in a network, indexed by position hash
---@return { [integer]: travelnet_redo.Travelnet }
function travelnet_redo.get_travelnets_in_network(network_id)
    if cache[network_id] then return cache[network_id].travelnets end
    local res, err = _db.get_travelnets_in_network(network_id)

    if not res then
        logger:raise("Failed to get travelnets in network %s: %s",
            network_id, err)
    end

    local rtn = {}
    for _, data in ipairs(res) do
        rtn[data.tvnet_pos_hash] = {
            pos = minetest.get_position_from_hash(data.tvnet_pos_hash),
            display_name = data.tvnet_display_name,
            network_id = data.tvnet_network_id,
            sort_key = data.tvnet_sort_key,
        }
    end

    return rtn
end

---Get the data of a network
---@return travelnet_redo.TravelnetNetwork
function travelnet_redo.get_network(network_id)
    if cache[network_id] then return cache[network_id] end

    local res, err = _db.get_network_by_id(network_id)

    if not res then
        logger:raise("Failed to get network %s: %s",
            network_id, err)
    end

    if #res == 0 then return nil end

    local rtn = {
        network_id = network_id,
        network_name = res[1].network_name,
        network_owner = res[1].network_owner,
        always_cache = res[1].network_always_cache,
        travelnets = travelnet_redo.get_travelnets_in_network(network_id),
        last_accessed = os.time(),
    }
    cache[network_id] = rtn
    return rtn
end

---Get the data of a network by its name and owner
---@return travelnet_redo.TravelnetNetwork
function travelnet_redo.get_network_by_name_owner(name, owner)
    for _, network_data in pairs(cache) do
        if network_data.network_name == name and network_data.network_owner == owner then
            return network_data
        end
    end

    local res, err = _db.get_network_by_name_owner(name, owner)

    if not res then
        logger:raise("Failed to get network %s@%s: %s",
            name, owner, err)
    end

    if #res == 0 then return nil end

    local rtn = {
        network_id = res[1].network_id,
        network_name = name,
        network_owner = owner,
        always_cache = res[1].network_always_cache,
        travelnets = travelnet_redo.get_travelnets_in_network(res[1].network_id),
        last_accessed = os.time(),
    }
    cache[res[1].network_id] = rtn
    return rtn
end

-- Write functions

function travelnet_redo.add_travelnet(pos, display_name, network_id, sort_key)
    sort_key = sort_key or 0

    local pos_hash = minetest.hash_node_position(pos)
    local res, err = _db.add_travelnet(pos_hash, display_name, network_id, sort_key)

    if not res then
        logger:raise("Failed to add travelnet at %s: %s",
            minetest.pos_to_string(pos), err)
    end

    local meta = minetest.get_meta(pos)
    meta:set_string("travelnet_redo_configured", "1")
    meta:set_string("display_name", display_name)
    meta:set_int("network_id", network_id)
    meta:set_int("sort_key", sort_key)

    if cache[network_id] then
        cache[network_id].travelnets[pos_hash] = {
            pos = pos,
            display_name = display_name,
            network_id = network_id,
            sort_key = sort_key,
        }
        cache[network_id].last_accessed = os.time()
    end
end

function travelnet_redo.update_travelnet(pos, display_name, network_id, sort_key, old_network_id)
    sort_key = sort_key or 0
    local meta = minetest.get_meta(pos)
    if meta:get_string("travelnet_redo_configured") == "" then
        logger:raise("Failed to update travelnet at %s: %s",
            minetest.pos_to_string(pos), "Calling update_travelnet on unconfigured travelnet")
    end

    local pos_hash = minetest.hash_node_position(pos)
    local res, err = _db.update_travelnet(pos_hash, display_name, network_id, sort_key)

    if not res then
        logger:raise("Failed to update travelnet at %s: %s",
            minetest.pos_to_string(pos), err)
    end

    meta:set_string("display_name", display_name)
    meta:set_int("network_id", network_id)
    meta:set_int("sort_key", sort_key)

    if cache[network_id] then
        cache[network_id].travelnets[pos_hash] = {
            pos = pos,
            display_name = display_name,
            network_id = network_id,
            sort_key = sort_key,
        }
        cache[network_id].last_accessed = os.time()
    end

    if old_network_id and cache[old_network_id] then
        cache[old_network_id].travelnets[pos_hash] = nil
        cache[old_network_id].last_accessed = os.time()
    end
end

function travelnet_redo.remove_travelnet(pos, network_id)
    local meta = minetest.get_meta(pos)
    if meta:get_string("travelnet_redo_configured") == "" then
        logger:raise("Failed to remove travelnet at %s: %s",
            minetest.pos_to_string(pos), "Calling remove_travelnet on unconfigured travelnet")
    end

    local pos_hash = minetest.hash_node_position(pos)
    local res, err = _db.remove_travelnet(pos_hash)

    if not res then
        logger:raise("Failed to remove travelnet at %s: %s",
            minetest.pos_to_string(pos), err)
    end

    meta:set_string("infotext", S("Unconfigured travelnet, rightclick/tap to configure"))
    meta:set_string("travelnet_redo_configured", "")
    meta:set_string("display_name", "")
    meta:set_int("network_id", 0)
    meta:set_int("sort_key", 0)

    if cache[network_id] then
        cache[network_id].travelnets[pos_hash] = nil
        cache[network_id].last_accessed = os.time()
    end
end

function travelnet_redo.create_network(name, owner)
    local res, err = _db.insert_travelnet_network(name, owner)

    if not res then
        logger:raise("Failed to create network %s@%s: %s",
            name, owner, err)
    end

    cache[res[1].v_network_id] = {
        network_id = res[1].v_network_id,
        network_name = name,
        network_owner = owner,
        always_cache = false,
        travelnets = {},
        last_accessed = os.time(),
    }

    return res[1].v_network_id
end

function travelnet_redo.create_or_get_network(name, owner)
    local network = travelnet_redo.get_network_by_name_owner(name, owner)
    if network then
        return network.network_id
    end
    return travelnet_redo.create_network(name, owner)
end

function travelnet_redo.delete_network(network_id)
    local res, err = _db.delete_travelnet_network(network_id)

    if not res then
        logger:raise("Failed to delete network %s: %s",
            network_id, err)
    end

    cache[network_id] = nil
end

function travelnet_redo.set_network_always_cache(network_id, always_cache)
    local res, err = _db.set_travelnet_always_cache(network_id, always_cache)
    if not res then
        logger:raise("Failed to set network #%s to always_cache %s: %s",
            network_id, always_cache and "TRUE" or "FALSE", err)
    end

    if cache[network_id] then
        cache[network_id].always_cache = always_cache and true or false
    end
end

function travelnet_redo.change_network_owner(network_id, name)
    local res, err = _db.change_network_owner(network_id, name)
    if not res then
        logger:raise("Failed to transfer network #%s to %s: %s",
            network_id, name, err)
    end

    if cache[network_id] then
        cache[network_id].network_owner = name
    end
end

-- Helper functions

function travelnet_redo.can_edit_travelnet(pos, name)
    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]
    if not (def and def.groups and def.groups.travelnet_redo) then
        return false
    end

    if minetest.check_player_privs(name, { travelnet_remove = true }) then
        return true
    end

    local tvnet = travelnet_redo.get_travelnet_from_map(pos)
    if not tvnet then
        if minetest.is_protected(pos, name) then
            minetest.record_protection_violation(pos, name)
            return false
        end
        return true
    end

    local network = travelnet_redo.get_network(tvnet.network_id)
    if network
        and network.network_owner ~= name
        and not minetest.check_player_privs(name, { travelnet_attach = true }) then
        return false
    end
    return true
end

---Sync from the node DB to the map
---If an existing travelnet is having wrong network: write data to that travelnet
---If a missing travelnet is in the DB: remove from the DB
function travelnet_redo.sync_ndb()
    local t1 = os.clock()

    local restored, removed = 0, 0
    local res, err = _int.query(
        "SELECT tvnet_pos_hash, tvnet_display_name, tvnet_network_id, tvnet_sort_key " ..
        "FROM travelnet_redo_travelnets;")
    if not res then
        logger:raise("Failed to sync node DB: %s", err)
    end

    for _, travelnet in ipairs(res) do
        local pos = minetest.get_position_from_hash(travelnet.tvnet_pos_hash)
        local node = minetest.get_node(pos)
        local node_def = minetest.registered_nodes[node.name]
        if node_def and node_def.groups and node_def.groups.travelnet_redo == 1 then
            local map_travelnet = travelnet_redo.get_travelnet_from_map(pos)
            local meta = minetest.get_meta(pos)
            if not map_travelnet
            or map_travelnet.network_id ~= travelnet.tvnet_network_id
            or map_travelnet.display_name ~= travelnet.tvnet_display_name
            or map_travelnet.sort_key ~= travelnet.tvnet_sort_key then
                local network = travelnet_redo.get_network(travelnet.tvnet_network_id)
                restored = restored + 1
                meta:set_string("infotext",
                    S("Travelnet @1 in @2@@@3, rightclick/tap to teleport.",
                    travelnet.tvnet_display_name, network.network_name, network.network_owner))
                meta:set_string("travelnet_redo_configured", "1")
                meta:set_string("network_owner", travelnet.tvnet_display_name)
                meta:set_int("network_id", travelnet.tvnet_network_id)
                meta:set_int("sort_key", travelnet.tvnet_sort_key)
            end
        else
            removed = removed + 1
            travelnet_redo.remove_travelnet(pos, travelnet.tvnet_network_id)
        end
    end
    return restored, removed, os.clock() - t1
end

-- Load all always cached networks
do
    local res, err = _db.get_network_always_cached()
    if not res then
        logger:raise("Failed to load always-cached networks: %s", err)
    end
    local now = os.time()
    for i, data in ipairs(res) do
        logger:action("Preloading travelnet #%i (%s@%s) into memory",
            i, data.network_name, data.network_owner)
        cache[data.network_id] = {
            network_id = data.network_id,
            network_name = data.network_name,
            network_owner = data.network_owner,
            always_cache = true,
            travelnets = travelnet_redo.get_travelnets_in_network(data.network_id),
            last_accessed = now,
        }
    end
end

modlib.minetest.register_globalstep(59 + math.random(), function()
    -- Remove travelnets without any children
    do
        local res, err = _int.query(
            "SELECT n.network_id AS network_id " ..
            "FROM travelnet_redo_networks AS n " ..
            "LEFT JOIN travelnet_redo_travelnets AS t " ..
            "ON n.network_id = t.tvnet_network_id " ..
            "WHERE t.tvnet_network_id IS NULL;"
        )

        if not res then
            logger:raise("Failed to list unused travelnet networks: %s", err)
        end

        for _, data in ipairs(res) do
            local network_id = data.network_id
            local d_res, d_err = _db.delete_travelnet_network(network_id)
            if not d_res then
                logger:raise("Failed to delete travelnet network #%i: %s", network_id, d_err)
            end
            cache[network_id] = nil
        end
    end

    -- Drop cache not accessed for more than `cache_duration` seconds
    local now = os.time()
    for network_id, cache_data in pairs(cache) do
        if not cache_data.always_cache then
            if now - cache_data.last_accessed > settings.cache_duration then
                -- Drop the unused cache
                logger:action("Dropping unused cache of network #%i (%s@%s)",
                    network_id, cache_data.network_name, cache_data.network_owner)
                cache[network_id] = nil
            end
        end
    end
end)
