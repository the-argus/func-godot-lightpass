@tool
class_name FuncGodotLightpassLightOmni
extends FuncGodotLightpassBaseLight

const propagated_omni_properties := {
	"shadow_normal_bias": 1.0, # OVERRIDING base Light3D default of 2.0
	"omni_attenuation": 1.0,
	"omni_range": 5.0,
	"omni_shadow_mode": OmniLight3D.ShadowMode.SHADOW_CUBE,
}

func _ready() -> void:
	super()
	add_to_group(&"func_godot_lightpass_light_omni", true)
	_fgd_classname = "fglight_omni"

func _func_godot_apply_properties(props: Dictionary) -> void:
	super._func_godot_apply_properties(props)
	_propagate_properties(props, propagated_omni_properties.keys())

func _collect_properties_for_serialization() -> Dictionary:
	var parent_props := super._collect_properties_for_serialization()
	parent_props.merge(propagated_omni_properties, true)
	return parent_props
