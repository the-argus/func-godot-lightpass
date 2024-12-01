# func-godot-lightpass documentation

This is a simple plugin, and for the most part all you need to do is press the
"export all exportable nodes" button on an `FGL*` node. However, there are some
cases where you may wonder what to expect, or get warnings when you do something
incorrectly. Those are explained here. Also, it is possible to set up your own
nodes to be exported by FuncGodotLightpass. That API is documented after the
more common usecase scenarios.

## Expected workflow

FuncGodotLightpass was designed with a certain level creation workflow in mind.

1. Greybox and texture the level in TrenchBroom
2. Import the level into Godot, and place lights there, adjusting color and
   brightness and range in the editor view
3. Export the placed lights back into TrenchBroom map file
4. Optionally repeat this process on the same `.map` file, greyboxing a new
   area of the level and then lighting it, until they level is complete.
5. Touch-up the map file from either TrenchBroom or Godot at any point afterwards

Notice that its not expected for you to edit the lights from TrenchBroom.
Although you *can*, the point is that you should be able to group, rotate, or
move the lights while editing the level to keep things aligned. Changing the
color or intensity of lights from TrenchBroom is not going to be as easy as
from Godot. The light entity definitions are made simply to save values from
Godot into the .map file, not to be edited from TrenchBroom.

## Adding exportable nodes

To place a node, select your `FuncGodotMap`, right click, and select "Add Child
Node." Alternatively, select it and then press Ctrl + A on your keyboard. Then
type the name of a FuncGodotLightpass node, and hit enter. After, you may use
Ctrl + D to duplicate these nodes. Try to keep them as direct children of the
map node, as it will lead to the most predictable results.

The available nodes for placement using FuncGodotLightpass are as follows:

- `FGLOmniLight`
- `FGLSpotLight`
- `FGLDirectionalLight`
- `FGLDecal`
- `FGLWorldEnvironment`
- `FGLAudioPlayer`

Each of these has an in-editor button at the top of its inspector window labelled
"Export all Exportable Nodes." Clicking this button will search the scene tree
for all of the nodes under the same FuncGodotMap as the one which the user pressed
the button on. It will write each of them out into the `.map` file.

## Warnings and duplicating lights

You may get warnings after duplicating lights in either Godot or TrenchBroom.
If you can tell that the warnings correspond to lights you just duplicated, then
you can safely ignore them. Most users should only ever see those warnings
emitted by FuncGodotLightpass.

As a rule of thumb, though, if you see warnings go away after one export, that
means that some auto fix-up was applied to your nodes and you can ignore the warnings.

## Adding nodes to TrenchBroom layers or groups from Godot

This feature is only enabled for `FuncGodotMap` nodes whose map settings have
`use_trenchbroom_groups_hierarchy` enabled.
When not enabled, exportable nodes will simply retain the same group or layer
as defined in the `.map` file. Duplicated generated nodes will have the same
group or layer as the original.

After enabling this feature, re-build your map in Godot. You should see that
organizational `Node3D`s have been added, with names such as `layer_0_My Layer`
or `group_2_lamppost`. When exporting, nodes will check if they have any ancestors
with a name starting with `group_` or `layer_` and use the number that follows
that prefix to determine the group or layer of the node. Therefore, you can move
nodes around, and their groups and layers will be determined by parent nodes.

Note thate you cannot change the layer a group is in through this interface. It
is intended only to edit the layers and groups of the exportable nodes themselves.

### TrenchBroom linked duplicates

Linked duplicates in TrenchBroom are a way of copy and pasting a group of objects,
and having TrenchBroom automatically copy + paste any changes you make from the
edited group into all other groups.

When moving nodes around in Godot, you may cause these groups to become out of
sync. According to the TrenchBroom manual, the correct approach to re-syncing
the groups is to open the map in TrenchBroom and then make a small edit to one
of the groups- then the contents of that edited group will be copied to all other
instances.

## Export API

TODO

```gdscript
func _ready() -> void:
	FuncGodotLightpass.apply_classname_metadata("misc_object", self)

func _func_godot_apply_properties(props: Dictionary) -> void:
	FuncGodotLightpass.apply_build_metadata(props, self)

func _get_property_list_with_context(context: Variant) -> Array[Dictionary]:
	return []
```
