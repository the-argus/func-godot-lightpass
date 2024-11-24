@tool
class_name FuncGodotLightpassNode
extends Node

@export var export_all_exportable_nodes: bool = false:
	set(_value):
		if Engine.is_editor_hint() and _value != export_all_exportable_nodes:
			var parent := get_parent()
			while parent and not parent is FuncGodotMap:
				parent = parent.get_parent()
			if not parent:
				push_error("FuncGodotLightpass: attempt to export a light ",
				"which is not in a map.")
			else:
				FuncGodotLightpass.export_entities_to_map_file(parent)
	get:
		return export_all_exportable_nodes

func _ready() -> void:
	if not Engine.is_editor_hint(): return
	add_to_group(&"godot_to_quake_exportable", true)
	var classname: String = ""
	if is_class("DirectionalLight3D"):
		classname = "fglight_directional"
	elif is_class("SpotLight3D"):
		classname = "fglight_spot"
	elif is_class("OmniLight3D"):
		classname = "fglight_omni"
	if not classname.is_empty():
		FuncGodotLightpass.apply_classname_metadata(classname, self)

func _func_godot_apply_properties(props: Dictionary) -> void:
	FuncGodotLightpass.apply_build_metadata(props, self)

	# the FuncGodotLightpass FGD definition are almost 1:1 with the properties
	# of the nodes they generate, so just  apply the props to this node's values
	var plist := ObjectSerializer.get_object_properties(self, null)
	# filter out stuff that isnt @export, or is handled by func_godot
	FuncGodotLightpass._filter_property_list_for_func_godot(self, plist)
	FuncGodotLightpass.apply_entity_properties_as_object_properties(self, props, plist)

