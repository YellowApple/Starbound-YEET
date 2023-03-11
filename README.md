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

All known bugs are tracked on
[GitHub](https://github.com/YellowApple/YEET/issues).

# I'm a modder.  How can I hack on it?

It's just an ordinary Starbound mod, so all the Lua files and such are
in their normal places.  Clone the repo, make your changes, submit a
PR, all that jazz :)

I use GNU Make (BSD Make might work too?) to automate packaging for
the Steam Workshop (using
[SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD); running
`make` in the mod's directory will generate `out/pkg/contents.pak`,
and running `make upload` will generate a valid `manifest.vdf` and
handle the uploading.  Obviously you need permissions in order to
actually upload over the top of my version; if you're publishing your
own fork, change the `"publishedfileid"` field in
`metadata.vdf.template` to `"0"` to tell SteamCMD to create a new
Workshop item instead of attempting to overwrite mine (and don't
forget to change that to whatever gets set in the generated
`manifest.vdf`!).

Note that you need the `STEAMCMD_USER` environment variable set for
`make upload` to work; I use [`asdf` and
`direnv`](https://github.com/asdf-community/asdf-direnv) to
automatically set `STEAMCMD_USER` to my Steam username whenever I `cd`
into YEET's mod folder; you can do the same by copying `.envrc.sample`
to `.envrc`, adjusting to use your Steam username (whichever one you
use to log into Steam itself), and running `direnv allow` to activate
it.
