class_name FuncGodotLightpassDefaultProperties

# defaults which don't include parent class's business
const _DEFAULTS_BY_CLASSNAME := {
	"Node": {
		# AutoTranslateMode auto_translate_mode[default: 0]
		"auto_translate_mode": Node.AutoTranslateMode.AUTO_TRANSLATE_MODE_INHERIT,
		# Stringeditor_description[default: ""]
		"editor_description": "",
		# MultiplayerAPImultiplayer
		"multiplayer": null,
		# NOTE: ignoring name and owner and scene_file_path, should always be handled explicitly
		# StringNamename
		# "name"
		# Nodeowner
		# Stringscene_file_path
		# PhysicsInterpolationMode physics_interpolation_mode[default: 0]
		"physics_interpolation_mode": Node.PhysicsInterpolationMode.PHYSICS_INTERPOLATION_MODE_INHERIT,
		# ProcessMode process_mode[default: 0]
		"process_mode": Node.ProcessMode.PROCESS_MODE_INHERIT,
		# int process_physics_priority[default: 0]
		"process_physics_priority": 0,
		# intprocess_priority[default: 0]
		"process_priority": 0,
		# ProcessThreadGroup process_thread_group[default: 0]
		"process_thread_group": Node.ProcessThreadGroup.PROCESS_THREAD_GROUP_INHERIT,
		# int process_thread_group_order
		"process_thread_group_order": 0,
		# BitField[ProcessThreadMessages] process_thread_messages
		"process_thread_messages": 0,
		# bool unique_name_in_owner [default: false]
		"unique_name_in_owner": false,
	},

	"Node3D": {
		# Basis basis
		# Basis global_basis
		# Vector3 global_position
		# Vector3 global_rotation
		# Vector3 global_rotation_degrees
		# Transform3D global_transform
		# Vector3 position[default: Vector3(0, 0, 0)]
		# Quaternion quaternion
		# Vector3 rotation[default: Vector3(0, 0, 0)]
		# Vector3 rotation_degrees
		# RotationEditMode rotation_edit_mode[default: 0]
		"rotation_edit_mode": Node3D.RotationEditMode.ROTATION_EDIT_MODE_EULER,
		# EulerOrder rotation_order[default: 2]
		"rotation_order": EulerOrder.EULER_ORDER_YXZ,
		# Vector3 scale[default: Vector3(1, 1, 1)]
		"scale": Vector3.ONE,
		# bool top_level[default: false]
		"top_level": false,
		# Transform3D transform[default: Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)]
		# NodePath visibility_parent[default: NodePath("")]
		# bool visible[default: true]
		"visible": true,
	},

	"VisualInstance3D": {
		# int layers[default: 1]
		"layers": 1,
		# float sorting_offset[default: 0.0]
		"sorting_offset": 0.0,
		# bool sorting_use_aabb_center
		"sorting_use_aabb_center": true,
	},

	"Light3D": {
		# float distance_fade_begin[default: 40.0]
		"distance_fade_begin": 40.0,
		# bool distance_fade_enabled[default: false]
		"distance_fade_enabled": false,
		# float distance_fade_length[default: 10.0]
		"distance_fade_length": 10.0,
		# float distance_fade_shadow[default: 50.0]
		"distance_fade_shadow": 50.0,
		# bool editor_only[default: false]
		"editor_only": false,
		# float light_angular_distance[default: 0.0]
		"light_angular_distance": 0.0,
		# BakeMode light_bake_mode[default: 2]
		"light_bake_mode": Light3D.BakeMode.BAKE_DYNAMIC,
		# Color light_color[default: Color(1, 1, 1, 1)]
		"light_color": Color(1, 1, 1, 1),
		# int light_cull_mask[default: 0xFFFFFFFF]
		"light_cull_mask": 0xFFFFFFFF,
		# float light_energy[default: 1.0]
		"light_energy": 1.0,
		# float light_indirect_energy[default: 1.0]
		"light_indirect_energy": 1.0,
		# float light_intensity_lumens
		# float light_intensity_lux
		# bool light_negative[default: false]
		"light_negative": false,
		# Texture2D light_projector
		# float light_size[default: 0.0]
		"light_size": 0.0,
		# float light_specular[default: 0.5]
		"light_specular": 0.5,
		# float light_temperature
		# float light_volumetric_fog_energy[default: 1.0]
		"light_volumetric_fog_energy": 1.0,
		# float shadow_bias[default: 0.1]
		"shadow_bias": 0.1,
		# float shadow_blur[default: 1.0]
		"shadow_blur": 1.0,
		# bool shadow_enabled[default: false]
		"shadow_enabled": false,
		# float shadow_normal_bias[default: 2.0]
		"shadow_normal_bias": 2.0,
		# float shadow_opacity[default: 1.0]
		"shadow_opacity": 1.0,
		# bool shadow_reverse_cull_face[default: false]
		"shadow_reverse_cull_face": false,
		# float shadow_transmittance_bias[default: 0.05]
		"shadow_transmittance_bias": 0.05,
	},
	"OmniLight3D": {
		# float shadow_normal_bias[overrides Light3D: 1.0]
		"shadow_normal_bias": 1.0,
		# float omni_attenuation[default: 1.0]
		"omni_attenuation": 1.0,
		# float omni_range[default: 5.0]
		"omni_range": 5.0,
		# ShadowMode omni_shadow_mode[default: 1]
		"omni_shadow_mode": OmniLight3D.ShadowMode.SHADOW_CUBE,
	},
	"DirectionalLight3D": {
		# bool directional_shadow_blend_splits[default: false]
		"directional_shadow_blend_splits": false,
		# float directional_shadow_fade_start[default: 0.8]
		"directional_shadow_fade_start": 0.8,
		# float directional_shadow_max_distance[default: 100.0]
		"directional_shadow_max_distance": 100.0,
		# ShadowMode directional_shadow_mode[default: 2]
		"directional_shadow_mode": DirectionalLight3D.ShadowMode.SHADOW_PARALLEL_4_SPLITS,
		# float directional_shadow_pancake_size[default: 20.0]
		"directional_shadow_pancake_size": 20.0,
		# float directional_shadow_split_1[default: 0.1]
		"directional_shadow_split_1": 0.1,
		# float directional_shadow_split_2[default: 0.2]
		"directional_shadow_split_2": 0.2,
		# float directional_shadow_split_3[default: 0.5]
		"directional_shadow_split_3": 0.5,
		# SkyMode sky_mode[default: 0]
		"sky_mode": DirectionalLight3D.SkyMode.SKY_MODE_LIGHT_AND_SKY,
	},
	"SpotLight3D": {
		# float shadow_bias[overrides Light3D: 0.03]
		"shadow_bias": 0.03,
		# float shadow_normal_bias[overrides Light3D: 1.0]
		"shadow_normal_bias": 1.0,
		# float spot_angle[default: 45.0]
		"spot_angle": 45.0,
		# float spot_angle_attenuation[default: 1.0]
		"spot_angle_attenuation": 1.0,
		# float spot_attenuation[default: 1.0]
		"spot_attenuation": 1.0,
		# float spot_range[default: 5.0]
		"spot_range": 5.0,
	},
	"Decal": {
		# float albedo_mix[default: 1.0]
		"albedo_mix": 1.0,
		# int cull_mask[default: 0xFFFFF]
		"cull_mask": 0xFFFFF,
		# float distance_fade_begin[default: 40.0]
		"distance_fade_begin": 40.0,
		# bool distance_fade_enabled[default: false]
		"distance_fade_enabled": false,
		# float distance_fade_length[default: 10.0]
		"distance_fade_length": 10.0,
		# float emission_energy[default: 1.0]
		"emission_energy": 1.0,
		# float lower_fade[default: 0.3]
		"lower_fade": 0.3,
		# Color modulate[default: Color(1, 1, 1, 1)]
		"modulate": Color(1, 1, 1, 1),
		# float normal_fade[default: 0.0]
		"normal_fade": 0.0,
		# Vector3 size[default: Vector3(2, 2, 2)]
		"size": Vector3(2, 2, 2),
		# Texture2D texture_albedo
		"texture_albedo": null,
		# Texture2D texture_emission
		"texture_emission": null,
		# Texture2D texture_normal
		"texture_normal": null,
		# Texture2D texture_orm
		"texture_orm": null,
		# float upper_fade [default: 0.3]
		"upper_fade": 0.3,
	},
	"WorldEnvironment": {
		# CameraAttributes camera_attributes
		"camera_attributes": null,
		# Compositor compositor
		"compositor": null,
		# Environment environment
		"environment": null,
	},
}

static func get_default_values_for_class(classname: String) -> Dictionary:
	match classname:
		"Node":
			return _DEFAULTS_BY_CLASSNAME["Node"]
		"Node3D":
			return _DEFAULTS_BY_CLASSNAME["Node"].merged(_DEFAULTS_BY_CLASSNAME["Node3D"], true)
		"VisualInstance3D":
			return _DEFAULTS_BY_CLASSNAME["Node"].merged(
				_DEFAULTS_BY_CLASSNAME["Node3D"], true).merged(
				_DEFAULTS_BY_CLASSNAME["VisualInstance3D"])
		"Light3D":
			return _DEFAULTS_BY_CLASSNAME["Node"].merged(
			_DEFAULTS_BY_CLASSNAME["Node3D"], true).merged(
			_DEFAULTS_BY_CLASSNAME["VisualInstance3D"], true).merged(
			_DEFAULTS_BY_CLASSNAME["Light3D"], true)
		"OmniLight3D":
			return _DEFAULTS_BY_CLASSNAME["Node"].merged(
			_DEFAULTS_BY_CLASSNAME["Node3D"], true).merged(
			_DEFAULTS_BY_CLASSNAME["VisualInstance3D"], true).merged(
			_DEFAULTS_BY_CLASSNAME["Light3D"], true).merged(
			_DEFAULTS_BY_CLASSNAME["OmniLight3D"], true)
		"DirectionalLight3D":
			return _DEFAULTS_BY_CLASSNAME["Node"].merged(
			_DEFAULTS_BY_CLASSNAME["Node3D"], true).merged(
			_DEFAULTS_BY_CLASSNAME["VisualInstance3D"], true).merged(
			_DEFAULTS_BY_CLASSNAME["Light3D"], true).merged(
			_DEFAULTS_BY_CLASSNAME["DirectionalLight3D"], true)
		"SpotLight3D":
			return _DEFAULTS_BY_CLASSNAME["Node"].merged(
			_DEFAULTS_BY_CLASSNAME["Node3D"], true).merged(
			_DEFAULTS_BY_CLASSNAME["VisualInstance3D"], true).merged(
			_DEFAULTS_BY_CLASSNAME["Light3D"], true).merged(
			_DEFAULTS_BY_CLASSNAME["SpotLight3D"], true)
		"Decal":
			return _DEFAULTS_BY_CLASSNAME["Node"].merged(
			_DEFAULTS_BY_CLASSNAME["Node3D"], true).merged(
			_DEFAULTS_BY_CLASSNAME["VisualInstance3D"], true).merged(
			_DEFAULTS_BY_CLASSNAME["Decal"], true)
		"WorldEnvironment":
			return _DEFAULTS_BY_CLASSNAME["Node"].merged(
			_DEFAULTS_BY_CLASSNAME["WorldEnvironment"], true)
	push_error("FuncGodotLightpass: attempt to get defaults for unsupported node type ", classname)
	return {}
