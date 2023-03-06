# YEET: YellowApple's Easy Editing Tool

Matter manipulation the likes of which even **GOD** has never seen!

# !!! WARNING !!!

This is highly experimental and alpha-quality.  There are glaring
bugs.  The UI is a trainwreck.  A lot of features are missing.  Use at
your own risk.  *Caveat emptor*.

# What is it?

It's a mod for [Starbound](https://playstarbound.com/) that gives
players a tool capable of cutting/copying/pasting arbitrary regions of
the game world.  If [Modules In A
Box](https://steamcommunity.com/sharedfiles/filedetails/?id=729456260),
[WEdit](https://steamcommunity.com/sharedfiles/filedetails/?id=734859295),
and [Holographic
Ruler](https://steamcommunity.com/sharedfiles/filedetails/?id=743604545)
were in some sort of spicy love triangle, this would be the resulting
offspring (don't ask me how a child can have three biological parents;
that's between you and your doctor).

# Why'd you make it?

For awhile I was using WEdit, but I didn't like its insistence on me
using a specific tech upgrade, and I didn't like having to be in the
debug UI (with the massive lagfest that entails).  I ended up
switching to Base In A Box / Modules In A Box.

MIAB is a wonderful mod, but having to place objects introduces its
own share of inconveniences; after fighting with carefully aligning
printers while building a subway track around my starting planet, I
started to wonder if I could create a successor that didn't require
placing objects and didn't require the debug UI to see what I'm doing.

I remembered that the Holographic Ruler mod is able to create overlays
that are indeed visible without needing the debug UI enabled, and down
the rabbit hole I dove...

# How do I install it?

Multiple ways:

- Subscribe to it on the [Steam
  Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=2943033037)
- Clone it into Starbound's `mods` folder:
  - On Linux: `git clone https://github.com/YellowApple/YEET.git
    ~/.steam/steam/steamapps/common/Starbound/mods/YEET`
  - On other platforms: ¯\\\_(ツ)_/¯


# How do I get it?

There's no crafting recipe for it yet, but you can spawn it with
`/spawnitem yeet`.

# What does it do, and how do I use it?

Equip it like any other tool/weapon.  When equipped, you should see
some yellow text hovering by your character showing the controls.

## Selection

YEET works with rectangular regions.  Left-clicking somewhere in the
world will set that point as the "origin" and mark it with a pink
square; holding the Shift key while left-clicking will set the
"extent" and mark it with a pink circle with an X through it.

When the origin and extent are both set, YEET will project a pink
border around the selected region and display (in yellow text) both
the current editing mode and the name of the currently-loaded datacard
(more on that below).

## Operations

Right-click anywhere to open YEET's UI.  Here you can select an
operation via one of the buttons at the top of the window:

- **Cut**: erase everything in the selected region and save it to a
  new datacard
- **Snarf**: copy everything in the selected region and save it to a
  new datacard
- **Paste**: erase everything in the selected region and replace it
  with whatever's in the current datacard

When you select an operation, you'll see the selection box change: the
mode line at the top will reflect your selection, and the inside of
the box will change as a visual/symbolic indicator of what's going to
happen.

When you're ready to execute the selected operation, click the big
yellow "YEET" button, or hold Shift and right-click anywhere.  YEET
will diligently (attempt to) perform whatever action you selected.

A small strip above the "YEET" button shows some additional
information about the selected region - namely, the origin/extent
world coordinates and the dimensions of the selection.  At the very
bottom is a status line and a tiny "RESET" button to clear the current
selection.

## Datacards

Every time you cut or snarf a selection, YEET will create a new
datacard containing everything that was selected: blocks, tile mods,
liquids, objects, you name it.  Near the bottom of the YEET GUI are
two text fields where you can set the name and description on the
datacard.  Clicking on the datacard's icon (in the space below the
text fields) will spit out a copy for you to keep in your inventory.

You can also drop existing data cards from your inventory into the
datacard slot to load your saved blueprints.  When a datacard is
present (be it from you loading an existing one or creating a new one
via a cut/snarf), YEET's paste operation will replace whatever's
selected with the datacard's contents.  Dropping a module printer from
Modules In A Box is also supported; YEET will treat it like a datacard
(**WARNING:** this feature is untested; *caveat emptor*).

**WARNING:** YEET does not yet update the visible selection when a
user loads an existing datacard, so the selection rectangle might not
match what actually gets replaced.

# Will this work in multiplayer?

I have no idea.  I only play singleplayer, so I haven't tested it in a
multiplayer setting.  If any brave souls want to try it out and report
back, I'd appreciate it.

# Is this compatible with other mods?

It doesn't touch other mods in any way.  It doesn't even touch or
depend upon MIAB in any way, and it's explicitly compatible with it.

# Will this break my saves?

Probably not?  I'd strongly suggest backing up your world files before
YEETing all over it.  If you plan on uninstalling it, the usual
cautions apply w.r.t. any YEETs or datacards you've got lying around -
and I'd also strongly suggest *not* uninstalling it while a
YEET's in the middle of an operation.  You know, normal modding common
sense.

# What are the known issues with it?

Per the top of this Workshop item description, this is alpha-quality
software and has undergone very minimal testing.  My to-do list so
far:

- The UI is a mess and needs cleaned up.
- The UI and item fight with each other sometimes (race conditions,
  probably), so cutting/snarfing won't always update the UI fields to
  indicate that they've overwritten the loaded datacard, and holding
  Backspace in the text fields will stick as the item keeps resetting
  what it thinks the field should be.
- YEET supports outputting serialized MIAB printers to starbound.log,
  but there's no way to invoke this yet.
- YEET (unlike MIAB) doesn't preserve crafting table upgrades.
- There's a log of debug logging that I should probably start turning
  off instead of spamming everyone's starbound.log.
- Sometimes you gotta snarf something a second time before it
  correctly overwrites the existing datacard (race condition
  somewhere?).
- A YEET-native template format (instead of literally just using
  MIAB's format) is planned but not yet implemented.
- I hope for YEET to eventually support WEdit templates/blueprints,
  but that has barely been investigated (let alone implemented).
- Selections are rectangular only, and overwrite both tile layers;
  non-rectangular and layer-specific selections are planned but not
  yet implemented (this will likely depend on the YEET-native template
  format mentioned above).
