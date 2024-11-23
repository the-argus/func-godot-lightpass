@tool
class_name FuncGodotLightpassLightSpot
extends FuncGodotLightpassBaseLight

const propagated_spot_properties := {
	#floatshadow_bias[overrides Light3D: 0.03]
	"shadow_bias": 0.03,
	#floatshadow_normal_bias[overrides Light3D: 1.0]
	"shadow_normal_bias": 1.0,
	#floatspot_angle[default: 45.0]
	"spot_angle": 45.0,
	#floatspot_angle_attenuation[default: 1.0]
	"spot_angle_attenuation": 1.0,
	#floatspot_attenuation[default: 1.0]
	"spot_attenuation": 1.0,
	#floatspot_range[default: 5.0]
	"spot_range": 5.0,
}

func _ready() -> void:
	super()
	add_to_group(&"func_godot_lightpass_light_spot", true)
	_fgd_classname = "fglight_spot"

func _func_godot_apply_properties(props: Dictionary) -> void:
	super._func_godot_apply_properties(props)
	_propagate_properties(props, propagated_spot_properties.keys())

func _collect_properties_for_serialization() -> Dictionary:
	var parent_props := super._collect_properties_for_serialization()
	parent_props.merge(propagated_spot_properties, true)
	return parent_props
