@tool
class_name FuncGodotLightpassBaseLight extends Light3D

## Properties which should be found in the fgd definition and also the Light3D
## node itself
const propagated_properties := {
	"visible": true,
	"light_color": Color(1, 1, 1, 1), # one exception: this is remapped to just "color"
	"light_energy": 1.0,
	"light_indirect_energy": 1.0,
	"shadow_enabled": false,
	"shadow_bias": 0.1,
	"distance_fade_begin": 40.0,
	"distance_fade_enabled": false,
	"distance_fade_length": 10.0,
	"distance_fade_shadow": 50.0,
	"editor_only": false,
	"light_angular_distance": 0.0,
	"light_bake_mode": Light3D.BakeMode.BAKE_DYNAMIC,
	"light_cull_mask": 0xFFFFFFFF,
	"light_negative": false,
	# TODO: serialize light_projector, maybe a path of some kind could work?
	# or maybe just have people place scene instance and support serializing those
	#"light_projector", #Texture2D default: null
	"light_size": 0.0,
	"light_specular": 0.5,
	# TODO: do we need to support light_temperature at all?
	# "light_temperature", # float
	"light_volumetric_fog_energy": 1.0,
	"shadow_blur": 1.0,
	"shadow_normal_bias": 2.0,
	"shadow_opacity": 1.0,
	"shadow_reverse_cull_face": false,
	"shadow_transmittance_bias": 0.05,
}

@export var export_all_lights_in_this_map: bool = false:
	set(_value):
		if Engine.is_editor_hint() and _value != export_all_lights_in_this_map:
			var parent := get_parent()
			while parent and not parent is FuncGodotMap:
				parent = parent.get_parent()
			if not parent:
				push_error("FuncGodotLightpass: attempt to export a light ",
				"which is not in a map.")
			else:
				FuncGodotLightpass.update_mapfile_with_lightpass_lights(parent)
	get:
		return export_all_lights_in_this_map

## Any keys applied to this entity not found in propagated_properties,
## including "targetname*" keys.
@export_storage var _internal_properties: Dictionary = {}
## The classname in the fgd file. Must be overridden by child scripts.
## Example value: "lite_spot"
@export_storage var _fgd_classname: String = ""
## Unique ID which is always serialized to the map file so we can see if lights
## in the scene are already in the file or not
@export_storage var _godot_to_quake_uuid: int = 0

func _fgl_get_classname() -> String:
	return _fgd_classname

func _fgl_get_uuid() -> int:
	return _godot_to_quake_uuid

func _fgl_set_uuid(uuid: int) -> void:
	_godot_to_quake_uuid = uuid

func _ready() -> void:
	add_to_group(&"godot_to_quake_exportable", true)
	add_to_group(&"func_godot_lightpass_light", true)

## Returns a dictionary of names of fields in this node ("light_color", etc)
## mapped to values of the expected defaults.
func _collect_properties_for_serialization() -> Dictionary:
	return propagated_properties.duplicate() # just to be sure no funny business happens

func _func_godot_apply_properties(props: Dictionary) -> void:	
	# if UUID serialized (this was placed from godot) then store that
	# this number will be 0 if the light was placed in trenchbroom, but we will
	# overwrite it with a good uuid when we re-store it to the file
	_godot_to_quake_uuid = props["_godot_to_quake_uuid"]
	props.erase("_godot_to_quake_uuid")
	
	# special case for light_color
	props["light_color"] = props["color"]
	props.erase("color")
	
	_propagate_properties(props, propagated_properties.keys())
	
	_internal_properties = props

## Apply all keys found in *both* "prop_defaults" and "props" to this light
## node, removing each found key from the props dictionary as it is found
func _propagate_properties(props: Dictionary, propnames: Array) -> void:
	for propname in propnames:
		if self.get(propname) == null:
			push_warning("FuncGodotLightpass: Unknown property being sent ",
			"from FGD to node, bad godot version?: ", propname)
			continue
		if not propname in props:
			continue
		set(propname, props[propname])
		props.erase(propname)

## Convert all of our properties such as light_color, shadow_opacity, etc, and
## turn it into a string which can be appended to the entity entry in a .map
func _fgl_get_properties_string() -> String:
	var out := ""
	var properties := _collect_properties_for_serialization()
	for propname in properties.keys():
		var value: Variant = get(propname)
		if value == null:
			push_warning("FuncGodotLightpass: Unknown node property ", propname,
			" attempting to be serialized to map")
			continue
		var default: Variant = properties[propname]
		if value == default:
			continue
		if propname == "light_color": propname = "color" # NOTE: naming exception
		out += "\"" + propname + "\"" + " "
		var serialized := FuncGodotLightpass.serialize_variant_to_map(value)
		if serialized.is_empty():
			return ""
		out += serialized
		out += "\n"
	return out
