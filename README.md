# Travelnet Redo

This is a rewrite of the original Travelnet mod, using PostgreSQL as the storage backend.

## Changes

* **This mod is not a drop-in replacement of the original Trevelnet mod.** Contributions are welcomed, but I don't plan writing migration scripts.
* Elevators are not included. This is mainly my personal choice - use more realistic elevators, they are not bad.
* Punching the travelnet no longer update it. Instead, they are always up-to-date, and a cache system ensures the robustness of displays.
* The number of travelnets in a network is no longer limited to 24. Though packed, the system properly handles the display of >24 travelnets.

## Installation

This mod requires `pgmoon` and `luasocket`. Use the following command to install them:

```bash
luarocks install pgmoon
luarocks install luasocket
```

After installing, configure the following in your `minetest.conf` (see [`pgmoon.new`](https://github.com/leafo/pgmoon#newoptions) for full options list):

```text
secure.trusted_mods = travelnet_redo
travelnet_redo.pg_connection = database=minetest host=127.0.0.1 port=5432 user=minetest password=password
```

Of course, confgure your PostgreSQL server accordingly.
