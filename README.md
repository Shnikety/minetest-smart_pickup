# minetest-smart_pickup
Another version of [item_drop] Mod for MineTest with refinements and new features.

Lets players choose weather to add item-drops from nodes to there inventory or drop them in the game.

Based on variouse other versions, [see also](https://forum.minetest.net/search.php?keywords=item+drop&terms=all&author=&fid%5B%5D=46&sc=1&sf=titleonly&sr=topics&sk=t&sd=d&st=0&ch=300&t=0&submit=Search) and PilzAdam's original at https://forum.minetest.net/viewtopic.php?t=2656

## Licence:
LGPLv2.1/CC BY-SA 3.0. Particle code from WCILA mod by Aurailus, originally licensed MIT.

some code borrowed from other mods, see comments in init.lua for details

## Settings:
* Player settings may be configured from within the game itself.
  (Settings tab > Advanced settings > Mods > item_drop)
* 'pickup_mode': There are three unique modes to choose from...
  * Auto: items within magnet radius automaticly zoom towards player and are picked up when within pickup radius.
  * KeyPress: same as auto but the player has to press a key otherwise items are ignored.
  * Both: use key to pull items towards you, items within pickup radius are automatic.
  * 'keytype': What key to use to pickup items.
  * 'keyinvert': Collect items when the key is not pressed instead of when it is pressed.
  * 'pickup_sound_gain': There is a sound when picking up items. This controls the volume.
  * 'pickup_particle': Displays a particle of the item picked up above the player if true.
  * 'pickup_radius': The maximum distance (in nodes) from which items are collected.
  * 'magnet_radius': Items between pickup_radius and this begin flying to the player.
