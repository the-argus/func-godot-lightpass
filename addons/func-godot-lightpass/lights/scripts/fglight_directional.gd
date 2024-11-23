@tool
class_name FuncGodotLightpassLightDirectional
extends FuncGodotLightpassBaseLight

const propagated_directional_properties := {
	#booldirectional_shadow_blend_splits[default: false]
	"directional_shadow_blend_splits": false,
	#floatdirectional_shadow_fade_start[default: 0.8]
	"directional_shadow_fade_start": 0.8,
	#floatdirectional_shadow_max_distance[default: 100.0]
	"directional_shadow_max_distance": 100.0,
	#ShadowModedirectional_shadow_mode[default: 2]
	"directional_shadow_mode": DirectionalLight3D.ShadowMode.SHADOW_PARALLEL_4_SPLITS,
	#floatdirectional_shadow_pancake_size[default: 20.0]
	"directional_shadow_pancake_size": 20.0,
	#floatdirectional_shadow_split_1[default: 0.1]
	"directional_shadow_split_1": 0.1,
	#floatdirectional_shadow_split_2[default: 0.2]
	"directional_shadow_split_2": 0.2,
	#floatdirectional_shadow_split_3[default: 0.5]
	"directional_shadow_split_3": 0.5,
	#SkyModesky_mode[default: 0]
	"sky_mode": DirectionalLight3D.SkyMode.SKY_MODE_LIGHT_AND_SKY,
}

func _ready() -> void:
	super()
	add_to_group(&"func_godot_lightpass_light_directional", true)
	_fgd_classname = "fglight_directional"

func _func_godot_apply_properties(props: Dictionary) -> void:
	super._func_godot_apply_properties(props)
	_propagate_properties(props, propagated_directional_properties.keys())

func _collect_properties_for_serialization() -> Dictionary:
	var parent_props := super._collect_properties_for_serialization()
	parent_props.merge(propagated_directional_properties, true)
	return parent_props
