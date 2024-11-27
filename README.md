# func-godot-lightpass

This is a Godot addon, and a companion for [func_godot](https://github.com/func_godot/func_godot_plugin)
which allows placing visual elements in your level from godot, and exporting
back to a `.map` file. It also provides entity definitions for point, spot, and
directional lights, decals, world environment nodes, and 3D audio players.

## Getting Started

Download the source code for this repository and unzip it directly in your
project's folder. Then, open or reload godot, and navigate to
AssetLib > Plugins, and enable the addon by pressing the check mark.

In any scene where you have a `FuncGodotMap`, you can now add (as children to
the map node):

- `FGLOmniLight`
- `FGLSpotLight`
- `FGLDirectionalLight`
- `FGLDecal`
- `FGLWorldEnvironment`
- `FGLAudioPlayer`

These nodes have an additional option on them: "Export all exportable nodes."
Pressing this button will cause the node to find all of the other nodes
underneath the same `FuncGodotMap` and write them out to the corresponding `.map`
file, appending them as entities to the end.

After doing this, you will be able to see your lights, decals, audio players,
etc in TrenchBroom (or a Quake level editor of your choice). You can edit lights
equally well from within the level editor.

## WARNING

This plugin writes to your map files, which is potentially destructive. If you
close the editor while the plugin is writing, data could potentially be lost.
Always use version control or keep backups.
This plugin is in early development, so if you use it be aware that some things
may be untested or even broken. Always save and always test after doing a build.
Editors besides TrenchBroom are untested, and this plugin targets TrenchBroom
primarily.

## Features and TODO

Features:

- Writing Godot nodes back to map files (Omni, Spot, and Directional lights,
  Decals, WorldEnvironment, and AudioStreamPlayer3D)
- Editing nodes from a level editor just as well as from Godot
- Light, Decal, WorldEnvironment, and AudioStreamPlayer3D entity definitions
  which have key-value-pairs that correspond 1:1 with their Godot node counterparts

TODO:

- More testing.
- Add support for TrenchBroom groups and layers.
- Document how you can set up writing _any_ node back to a .map file yourself.
- Enable serialization of light projector textures.
- Generate TrenchBroom-style entity number comments in the `.map` file to reduce
  random diffs created when opening the file in the editor.
