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
A node can only be on a layer or a group, never both, since groups are fundamentally
all on the same layer, and the layer of grouped objects are therefore defined
by the group, not the object itself. As FuncGodotLightpass traverses upwards from
each exportable node towards the ancestor `FuncGodotMap`, the first encountered
group is used. The last encountered layer is used. If a group is encountered at
any point, it always overrides any layer information.

Note thate you cannot change the layer a group is in through this interface. It
is intended only to edit the layers and groups of the exportable nodes themselves.

### TrenchBroom linked duplicates

Linked duplicates in TrenchBroom are a way of copy and pasting a group of objects,
and having TrenchBroom automatically copy and paste any changes you make from the
edited group into all other groups.

When moving nodes around in Godot, you may cause these groups to become out of
sync. According to the TrenchBroom manual, the correct approach to re-syncing
the groups is to open the map in TrenchBroom and then make a small edit to one
of the groups- then the contents of that edited group will be copied to all other
instances.

## Export API

In order to make a node exportable to TrenchBroom, two functions must be called
in the node's script, and the script must be added to a generated node whose
entity definition inherits from `base_godot_exportable`, an entity definition
resource found within the plugin files, ie. `addons/func-godot-lightpass/`.
This entity definition should already be in your FGD, since you should have added
the FuncGodotLightpass FGD file as a base to yours.

The script on the generated node (set either by the "Script" option on the
entity definition or by assigning the script to the root of the generated scene
of the entity definition) must be `@tool`. The following base content is needed,
where `"misc_object"` is replaced by the entity definition classname- `"info_playerstart"`,
or `"light_point"`, etc.

```gdscript
@tool

func _ready() -> void:
	FuncGodotLightpass.apply_classname_metadata("misc_object", self)

func _func_godot_apply_properties(props: Dictionary) -> void:
	FuncGodotLightpass.apply_build_metadata(props, self)
```

FuncGodotLightpass needs to know the classname so that it can serialize a node to
the map file and provide the correct classname there. However, `apply_build_metadata`
is internally called by `apply_build_metadata`, using a `"classname"` value found
in `props`. So if you don't plan on ever creating your nodes in Godot, you can
omit the contents of the `_ready()` function in the above example. The
`_ready()` function is just necessary so that FuncGodotLightpass knows the
classname / entity definition assigned to the entity even if it is placed normally,
without ever recieving any data through a `_func_godot_apply_properties()` call.

By default, when serializing your node, FuncGodotLightpass will serialize all
`@export` properties, as well as builtin node properties. It learns what properties
a node has by reading a "property list" data structure, usually returned by
`Object.get_property_list()`. Read the documentation for that function to learn
how to format a property list. You can override `_get_property_list_with_context()`
to change what properties FuncGodotLightpass knows about, and you can override
`_get()` to change how it gets them. For example, here is a script which has only
one property, regardless of what node type it inherits from:

```gdscript
@export var custom_amount: float = 0.0

func _get_property_list_with_context(context: Variant) -> Array[Dictionary]:
	if context is FuncGodotMapSettings:
	    return [
			{ name = "custom_prop", type = Variant.Type.TYPE_FLOAT, ignore_if = 0.0, usage = Object.PropertyUsageFlags.PROPERTY_USAGE_STORAGE, }
		]
	else:
		return get_property_list()

func _get(property: StringName) -> Variant:
	match property:
		&"custom_prop":
				return custom_amount
	return null
```

`ignore_if` is not a standard value for a property list. It is an additional
property description values understood only by FuncGodotLightpass. Hopefully,
it is self explanatory: ignore this property, if it is some value. It is usually
set to the default value.

If a property is of type float, FuncGodotLightpass will try to account for
floating point error when comparing for equality with the `ignore_if` value.
Values which are very slightly different from the `ignore_if` will be ignored,
too.

`usage` must always contain `PROPERTY_USAGE_STORAGE`, as FuncGodotLightpass
ignores all properties which do not have this usage flag. It must never contain
`PROPERTY_USAGE_INTERNAL`, as FuncGodotLightpass also ignores any properties
with that flag. FuncGodotLightpass will also ignore any properties that begin
with `"metadata/"`, or have the name `"script"` or `"export_all_exportable_nodes"`.

FuncGodotLightpass will also always ignore `"name"`, `"owner"`, and `"scene_file_path"`
when writing out to a map file. Also, in `Node3D`, `"visibility_parent"`. And,
if the node inherits from `Light3D`, `"light_color"` is serialized under just
`"color"`, so do not try to add a property called `"color"` to a light.

In your property list, do not include position or rotation values- if your node
inherits from `Node3D`, FuncGodot will detect that and automatically handle it.
