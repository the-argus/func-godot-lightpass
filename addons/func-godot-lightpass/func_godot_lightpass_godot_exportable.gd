@tool
## This is a very simply class which covers some boilerplate needed to make a
## godot -> quake map exportable entity. If inheriting from this becomes a
## problem, you can just copy paste this implementation into your
## scripts. Make sure it is @tool
class_name FuncGodotLightpassGodotExportable
extends Node3D

@export_storage var _godot_to_quake_uuid: int = 0

func _fgl_get_classname() -> String:
	push_warning(	"Inheriting script on ", self,
					" needs to override _fgl_get_classname")
	return "" # should return something like "enemy_chomper" or "info_delay" etc

func _fgl_get_uuid() -> int:
	return _godot_to_quake_uuid

func _fgl_set_uuid(uuid: int) -> void:
	_godot_to_quake_uuid = uuid

func _func_godot_apply_properties(props: Dictionary) -> void:
	_godot_to_quake_uuid = props["_godot_to_quake_uuid"]
	props.erase("_godot_to_quake_uuid")

func _ready() -> void:
	add_to_group(&"godot_to_quake_exportable", true)
