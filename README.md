# Travelnet Redo

This is a rewrite of the [original Travelnet mod](https://content.luanti.org/packages/mt-mods/travelnet/), using PostgreSQL as the storage backend.

This rewrite is based on [commit `fad216d` of mt-mods' fork](https://github.com/mt-mods/travelnet/commit/fad216db52b8fc8fafa11868d80c9e35c4b4a7ac), a fork of the [unmaintained upstream](https://github.com/Sokomine/travelnet) By Sokomine.

## Why this fork?

* **No more bloated API**: You can create travelnets not only in box-like shape
* **Cleaner codes**: Getting rid of 12 years of ancient debris hidden deep inside codes
* **Lesser memory usage**: Not having to load all networks the player owns to load one network
* **More flexibility**: Allow admins to change the owner and the name (to-do) of a network easily
* **No hacky travelnet removal code**: Travelnets can be dug normally instead of asking for detachment in the UI
* **No more [cramped UIs](https://github.com/mt-mods/travelnet/issues/53)**: Using [flow](https://content.luanti.org/packages/luk3yx/flow/) as the GUI library, the elements align themselves neatly

## Travelnets catalogue

* Default travelnets: Original box-like travelnets that come with this mod, in 15 colors
* [Fancy travelnets](https://content.luanti.org/packages/Emojiminetest/travelnet_redo_fancy/): Travelnets with fancy textures, magic themed
* [Travelnet beacons](https://content.luanti.org/packages/Emojiminetest/travelnet_redo_beacons/): Single-node travelnet (not box-shaped)

## Changes

* **This mod is not a drop-in replacement of the original Travelnet mod.** Contributions are welcomed, but I don't plan to write migration scripts.
* Elevators are not included. This is mainly my personal choice - use [more realistic elevators](https://content.luanti.org/packages/shacknetisp/elevator/), they are not bad.
* Punching the travelnet no longer updates it. Instead, they are always up-to-date, and a cache system ensures the robustness of displays.
* The number of travelnets in a network is no longer limited to 24. Though packed, the system properly handles the display of >24 travelnets.
* A sorting key field is added. This is a 2-bit signed integer controlling how travelnets should be sorted when listed, the smaller the upper. Travelnets first get sorted by their sorting key, then case-insensitive alphabetically.
* Apart from "(P)" meaning protected, "(I)" means enter only - you can't exit from that travelnet unless you own that travelnet.
* If travelnet names start with integers, they are sorted numerically.

## Installation

This mod requires `pgmoon` and `luasocket`. Use the following command to install them:

```bash
luarocks install pgmoon
luarocks install luasocket
```

After installing, configure the following in your `core.conf` (see [`pgmoon.new`](https://github.com/leafo/pgmoon#newoptions) for full options list):

```text
# We need insecure environment access
secure.trusted_mods = travelnet_redo

# Note that this differs from backend definitions in world.mt
travelnet_redo.pg_connection = database=minetest host=127.0.0.1 port=5432 user=minetest password=password
```

Of course, configure your PostgreSQL server accordingly. You can safely share the same database with all Minetest storage.
