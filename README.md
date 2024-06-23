# Travelnet Redo

This is a rewrite of the [original Travelnet mod](https://content.minetest.net/packages/mt-mods/travelnet/), using PostgreSQL as the storage backend.

## Why this fork?

* Cleaner codes: Getting rid of 12 years of ancient debris hidden deep inside codes
* (Probably?) lesser memory usage: Not having to load all networks the player owns to load one network
* More flexibility: Allow admins to change the owner and the name (to-do) of a network easily
* Easier sorting: Adds a sorting key field to customize the order of travelnets in the list
* No hacky digging/removal code: Travelnets can be dug normally instead of asking for detachment in the UI
* No more [cramped UIs](https://github.com/mt-mods/travelnet/issues/53): Using flow as the GUI library, the elements align themselves neatly
* You know why you can't teleport: Current travelnet is in green, protected ones are in sharp red

## Changes

* **This mod is not a drop-in replacement of the original Trevelnet mod.** Contributions are welcomed, but I don't plan to write migration scripts.
* Elevators are not included. This is mainly my personal choice - use [more realistic elevators](https://content.minetest.net/packages/shacknetisp/elevator/), they are not bad.
* Punching the travelnet no longer updates it. Instead, they are always up-to-date, and a cache system ensures the robustness of displays.
* The number of travelnets in a network is no longer limited to 24. Though packed, the system properly handles the display of >24 travelnets.
* A sorting key field is added. This is a 2-bit integer controlling how travelnets should be sorted when listed. Travelnets first get sorted by their sorting key, then case-insensitive alphabetically.

## Installation

This mod requires `pgmoon` and `luasocket`. Use the following command to install them:

```bash
luarocks install pgmoon
luarocks install luasocket
```

After installing, configure the following in your `minetest.conf` (see [`pgmoon.new`](https://github.com/leafo/pgmoon#newoptions) for full options list):

```text
# We need insecure environment access
secure.trusted_mods = travelnet_redo

# Note that this differs from backend definitions in world.mt
travelnet_redo.pg_connection = database=minetest host=127.0.0.1 port=5432 user=minetest password=password
```

Of course, configure your PostgreSQL server accordingly. You can safely share the same database with all Minetest storage.
