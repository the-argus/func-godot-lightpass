# func-godot-lightpass

This is a Godot addon, and a companion for [func_godot](https://github.com/func_godot/func_godot_plugin)
which allows placing visual elements in your level from godot, and exporting
back to a `.map` file. It also provides entity definitions for point, spot, and
directional lights, decals, world environment nodes, and 3D audio players.

[Documentation](./DOC.md) is available.

## Getting Started

Download the source code for this repository and unzip it directly in your
project's folder. Then, open or reload godot, and navigate to
AssetLib > Plugins, and enable the addon by pressing the check mark.

Find your FGD file resource, and add `res://addons/func-godot-lightpass/func_godot_lightpass_fgd.tres`
as a base FGD file.

In any scene where you have a `FuncGodotMap` with the edited FGD file, you can
now add (as children to the map node):

- `FGLOmniLight`
- `FGLSpotLight`
- `FGLDirectionalLight`
- `FGLDecal`
- `FGLWorldEnvironment`
- `FGLAudioPlayer`

These nodes have an additional option on them: "Export all exportable nodes."
Pressing this button will cause the node to find all of the other FGL nodes
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
- Support for modifying the groups and layers of induvidual nodes by dragging
  them to have different parent nodes, when func_godot's
  `use_trenchbroom_groups_hierarchy` is enabled
- Editing nodes from a level editor just as well as from Godot
- Light, Decal, WorldEnvironment, and AudioStreamPlayer3D entity definitions
  which have key-value-pairs that correspond 1:1 with their Godot node counterparts
- Ability to define custom scripts which can be put on your own nodes, to write
  them out to the map file as well

TODO:

- Generate TrenchBroom-style entity number comments in the `.map` file to reduce
  random diffs created when opening the file in the editor.
