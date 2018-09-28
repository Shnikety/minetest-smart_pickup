# minetest-smart_pickup

Lets players choose weather to add item-drops from nodes to their inventory or drop them in the game.

Currently in development:
a blacklist of items to be ignored and not picked up along with chat commands
and a menu to edit the list.

This makes mining and harvesting far more pleasant, even if editing the list of
items to be ignored is painfull right now. Note that ignored items can still be
picked up manualy via point and click. Dropped items are also always ignored
(with no timers or anything).

Based on [variouse versions](https://forum.minetest.net/search.php?keywords=item+drop&terms=all&author=&fid%5B%5D=46&sc=1&sf=titleonly&sr=topics&sk=t&sd=d&st=0&ch=300&t=0&submit=Search)
of [item_drop] mod for MineTest with refinements and new features. See also [PilzAdam's original](https://forum.minetest.net/viewtopic.php?t=2656).

## Licence:
LGPLv2.1/CC BY-SA 3.0. Particle code from WCILA mod by Aurailus, originally licensed MIT.

some code borrowed from other mods, see comments in init.lua for details

## Settings:
* Player settings may be configured from within the game itself.
  (Settings tab > Advanced settings > Mods > item_drop)
* `pickup_mode`: There are three unique modes to choose from...
  * Auto: items within `magnet_radius` automaticly zoom towards player and are picked up when within `pickup_radius`.
  * KeyPress: same as Auto but the player has to press a key otherwise items are ignored.
  * Both: use key to pull items towards you, items within `pickup_radius` are automatic.
* `keytype`: What key to use to pickup items.
* `keyinvert`: Collect items when the key is not pressed instead of when it is pressed.
* `pickup_sound_gain`: There is a sound when picking up items. This controls the volume.
* `pickup_particle`: Displays a particle of the item picked up above the player if `true`.
* `pickup_radius`: The maximum distance (in nodes) from which items are collected.
* `magnet_radius`: Items within this range will fly to the player.

## Chat Commands:
(Please note that these are very primitive, and annoying to use, right now.  Expect these to change.)

* `item_ignore <ItemString>`: will cause the player to ignore and not pick up valid items.
* `item_pickup <ItemString>`: lets various modes auto pick-up the item.
This is default behavior so this just undoes 'item_ignore.'
* `item_list`: prints out the list of items that are not to be picked up.
* `item_clear`: clears all entries in the blacklist of items.
