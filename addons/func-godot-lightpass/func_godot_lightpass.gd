@tool
class_name FuncGodotLightpass
extends EditorPlugin

const CUSTOM_NODE_NAMES := [
	"FGLOmniLight",
	"FGLSpotLight",
	"FGLDirectionalLight",
	"FGLDecal",
	"FGLWorldEnvironment",
	"FGLAudioPlayer",
]
const FGL_NODE_SCRIPT := preload("fgl_node.gd")
const CUSTOM_NODE_INHERITANCE := [
	"OmniLight3D",
	"SpotLight3D",
	"DirectionalLight3D",
	"Decal",
	"WorldEnvironment",
	"AudioStreamPlayer3D",
]
const LIGHT_ICON = preload("./icon/omni.png")
const DEFAULTS_SCRIPT = preload("./builtin_node_default_property_values.gd")
const FP_EPSILON := 0.001

func _enter_tree() -> void:
	for idx in CUSTOM_NODE_NAMES.size():
		add_custom_type(
			CUSTOM_NODE_NAMES[idx],
			CUSTOM_NODE_INHERITANCE[idx],
			FGL_NODE_SCRIPT,
			LIGHT_ICON)

func _exit_tree() -> void:
	for nodename in CUSTOM_NODE_NAMES:
		remove_custom_type(nodename)

class FuncGodotLightpassParseData:
	var tokens: Array[String] = []
	var point_entities: Array[Dictionary] = []
	var token_index_to_entity_index := {}
	var uuids_to_point_entities_buckets := {}

## For every node that you want to be serializable into a .map file, call this
## function from _func_godot_apply_properties.
## Also, make sure to add the node to group "godot_to_quake_exportable" and
## call apply_classname_metadata in _ready()
static func apply_build_metadata(entity_properties: Dictionary, node: Node) -> void:
	if not "classname" in entity_properties:
		# this should never happen if the node was generated by func_godot
		push_warning("FuncGodotLightpass: entity properties for ",
		node, " do not contain a classname key")

	if "_tb_group" in entity_properties:
		node.set_meta(&"_fgl_tb_group", entity_properties["_tb_group"])
	if "_tb_protected_properties" in entity_properties:
		node.set_meta(&"_fgl_tb_protected_properties", entity_properties["_tb_protected_properties"])
	if "_tb_layer" in entity_properties:
		node.set_meta(&"_fgl_tb_layer", entity_properties["_tb_layer"])

	node.set_meta(&"_godot_to_quake_uuid", entity_properties.get("_godot_to_quake_uuid", 0))
	entity_properties.erase("_godot_to_quake_uuid")
	node.set_meta(&"_fgl_classname", entity_properties["classname"])

static func apply_classname_metadata(classname: String, node: Node) -> void:
	node.set_meta(&"_fgl_classname", classname)

## Go through property_list, taking the "name" entry from each dictionary.
## if that property name is in entity_properties, store the entity_properties
## value into the object's property of that name.
static func apply_entity_properties_as_object_properties(
	object: Object,
	entity_properties: Dictionary,
	property_list: Array[Dictionary]) -> void:
	for property in property_list:
		var propname: String = property["name"]
		var classname: StringName = property["class_name"]
		var type: Variant.Type = property["type"]
		# NOTE: cant check if object.get(propname) is null here, because it
		# could just be that the property is null by default.
		var new_name: String = property.get("external_name", "") # renamed props
		var name_to_check: String = propname if new_name.is_empty() else new_name
		if not name_to_check in entity_properties:
			continue
		var value = entity_properties[name_to_check]

		if type == Variant.Type.TYPE_OBJECT and value is String and value != "":
			# resource_type is a special value for FuncGodotLightpass determined
			# by behavior in serialize_variant_to_map
			var resource_type: String = value.get_slice("::", 0)
			# resource class is just the .get_class() of the value
			var resource_class: String = value.get_slice("::", 1)
			var resource_path: String = value.substr(resource_type.length() + resource_class.length() + 4)

			if resource_path.is_empty() or resource_type.is_empty() or resource_class.is_empty():
				push_error("FuncGodotLightpass: got TYPE_OBJECT for property ",
				property, " on ", object, " but it does not seem to be a ",
				"valid serialized resource. This is possibly an internal ",
				"FuncGodotLightpass error.")
				continue

			# TODO: check if resource_class matches classname, probably

			if not ResourceLoader.exists(resource_path):
				push_error("FuncGodotLightpass: Attempt to load a resource ",
				"from path ", resource_path, " but found nothing. Did the ",
				"referenced resource get moved around in the project files?")
				continue

			value = ResourceLoader.load(resource_path, resource_class)

		object.set(propname, value)

## Given a func_godot map node, find all the lights under it and write those to
## its local map file.
static func export_entities_to_map_file(map_node: FuncGodotMap) -> void:
	var map_settings := map_node.map_settings
	var map_file := map_node.global_map_file if map_node.global_map_file != "" else map_node.local_map_file
	if not map_file or map_file.is_empty():
		push_error("FuncGodotLightpass: attempt to export lights under a ",
		"FuncGodotMap with no set map file.")
		return

	var cstream := FuncGodotLightpassCharStream.new(map_file)
	if not cstream.is_good(): return

	var data: FuncGodotLightpassParseData = _parse(cstream)
	cstream.close()
	if not data: return

	var exportable_classnames := _build_godot_exportable_classnames(
		map_settings.entity_fgd)

	# returns the nodes in scene hierarchy order
	var exportables := _gather_exportable_nodes(map_node)

	# fix 0 or duplicate uuids
	var used_uuids := data.uuids_to_point_entities_buckets.duplicate()
	# keep buckets for what the uuids originally were- that way we can
	# correspond the first instance of duplication in the map to the first
	# instance of duplication in the nodes. this will lead to some weird git
	# diffs due to the position of some nodes being swapped when
	# use_trenchbroom_groups_hierarchy is enabled- and a node is duplicated and
	# then removed from a group in trenchbroom, but should usually be good
	var uuids_to_nodes_buckets := {}
	for node in exportables:
		var uuid: int = node.get_meta(&"_godot_to_quake_uuid", 0)

		if uuid == 0:
			# resolve later after duplicates are resolved
			continue
		elif uuid < 0:
			push_error("FuncGodotLightpass: Found light with negative ",
			"uuid, refusing to serialize as some code relies on uuids ",
			"being positive")
			return

		var default: Array[Node] = []
		var bucket: Array[Node] = uuids_to_nodes_buckets.get(uuid, default)

		# resolve duplicates
		if not bucket.is_empty():
			push_warning("FuncGodotLightpass: duplicate uuid ", uuid,
			" from node ", node, " and ", bucket.back(),
			". This can happen if you copy nodes in godot or trenchbroom, and ",
			"is harmless in that case.")
			var new_uuid = _gen_uuid(used_uuids)
			node.set_meta(&"_godot_to_quake_uuid", new_uuid)

		# often there will already be an entry under this uuid- when the node
		# was imported from the map file and has the same uuid as its
		# corresponding entity
		if not uuid in used_uuids:
			used_uuids[uuid] = true

		bucket.append(node)
		uuids_to_nodes_buckets[uuid] = bucket

	# resolve nodes with 0 uuids. usually should happen, but maybe possible
	# if the user defined their own serializable script
	for node in exportables:
		var uuid: int = node.get_meta(&"_godot_to_quake_uuid", 0)
		if uuid == 0:
			var new_uuid: int = _gen_uuid(used_uuids)
			assert(not new_uuid in uuids_to_nodes_buckets)
			node.set_meta(&"_godot_to_quake_uuid", new_uuid)
			used_uuids[new_uuid] = true
			var bucket: Array[Node] = [node]
			uuids_to_nodes_buckets[new_uuid] = bucket
	
	if map_settings.use_trenchbroom_groups_hierarchy:
		_fix_trenchbroom_group_metadata(exportables, map_node)

	var tokens: Array[String] = []
	var serialized_uuids := {}

	# replace all modified entities with their new serialized versions
	for token_idx in data.tokens.size():
		if not token_idx in data.token_index_to_entity_index:
			tokens.append(data.tokens[token_idx])
			continue

		var entity: Dictionary = data.point_entities[data.token_index_to_entity_index[token_idx]]

		if not entity.get("classname", "") in exportable_classnames:
			tokens.append(data.tokens[token_idx])
			continue

		var uuid := _get_point_entity_uuid(entity)

		# fix bad uuids
		if uuid < 0:
			# try to find an entity at this same position, maybe that is
			# generated node
			uuid = _resolve_entity_with_no_uuid(entity, exportables, map_settings)
			if uuid == -1:
				return
			elif uuid < 0:
				# delete entity
				continue

		# delete entity if it has no matching node in the scene
		if not uuid in uuids_to_nodes_buckets:
			continue

		var node_bucket: Array[Node] = uuids_to_nodes_buckets[uuid]
		var entity_bucket: Array[Dictionary] = data.uuids_to_point_entities_buckets[uuid]
		var idx := entity_bucket.find(entity)
		assert(idx != -1)

		if idx < node_bucket.size(): # if greater, nodes were deleted
			var node := node_bucket[idx]
			var actual_uuid: int = node.get_meta(&"_godot_to_quake_uuid", -1)
			assert(actual_uuid > 0)
			var serialized := _serialize_fgl_node_to_map(
				node, map_node)
			if serialized.is_empty():
				return # could also just not change this node?
			tokens.append(serialized)
			assert(not actual_uuid in serialized_uuids, "uuid already serialized")
			serialized_uuids[actual_uuid] = true
		else:
			# delete entity by not adding it
			pass

	# remove the EOF newline since we're appending with newlines already
	if tokens.back() == "\n":
		tokens.pop_back()

	# append any new entities
	for node in exportables:
		var uuid: int = node.get_meta(&"_godot_to_quake_uuid", -1)
		assert(uuid > 0, "zero uuid found")
		if not uuid in serialized_uuids:
			var serialized := _serialize_fgl_node_to_map(node, map_node)
			if serialized.is_empty():
				return
			tokens.append(serialized)

	# erase the whole file!! if closed here data could be lost
	var map: FileAccess = FileAccess.open(map_file, FileAccess.READ_WRITE)
	if map == null:
		# ctrl-click on get_open_error here to see docs for what codes mean
		push_error("FuncGodotLightpass: Unable to open file (", map_file,
		") with READ_WRITE permissions, for exporting. Error code: ",
		FileAccess.get_open_error())
		return
	map.resize(0)
	for token in tokens:
		map.store_string(token)
	map.close()
	print("FuncGodotLightpass: export to .map file completed.")

## Generates a random int which is not already a key in used_uuids. Does not
## insert it into the dictionary
static func _gen_uuid(used_uuids: Dictionary) -> int:
	var uuid: int = -1
	while uuid <= 0 or uuid in used_uuids:
		uuid = randi()
	return uuid

static func _fix_trenchbroom_group_metadata(exportables: Array[Node], map_node: FuncGodotMap) -> void:
	for node in exportables:
		node.remove_meta(&"_fgl_tb_layer")
		node.remove_meta(&"_fgl_tb_group")
		var parent := node.get_parent()
		while parent != map_node:
			if not is_instance_valid(parent):
				# internal error, basically an assert
				push_warning("FuncGodotLightpass: exportable outside tree")
				break
			if parent.name.begins_with("group_"):
				var groupnum: String = parent.name.get_slice("_", 1)
				if not groupnum.is_valid_int():
					push_warning("FuncGodotLightpass: bad group node name", parent)
				else:
					node.set_meta(&"_fgl_tb_group", groupnum.to_int())
					node.remove_meta(&"_fgl_tb_layer")
					break
			elif parent.name.begins_with("layer_"):
				var layernum: String = parent.name.get_slice("_", 1)
				if not layernum.is_valid_int():
					push_warning("FuncGodotLightpass: bad layer node name", parent)
				else:
					node.set_meta(&"_fgl_tb_layer", layernum.to_int())

			parent = parent.get_parent()

## Returns -2 on unable to find uuid of matching node, and -1 on unrecoverable
## error. Otherwise it returns the uuid of the corresponding node to this item.
static func _resolve_entity_with_no_uuid(
	entity: Dictionary,
	exportables: Array[Node],
	map_settings: FuncGodotMapSettings) -> int:
	var ERRMSG := str("FuncGodotLightpass: entity with no uuid found ",
	"(something placed from trenchbroom, probably), and unable to resolve it ",
	"with a generated node. Removing it now.")

	if not "origin" in entity:
		push_warning(ERRMSG)
		# our only heuristic for finding matching nodes is by origin/position
		return -2

	var entity_position_according_to_map: Vector3 = _get_position_from_origin_string(
		entity["origin"], map_settings.inverse_scale_factor)

	var found := false
	for node in exportables:
		if not node is Node3D:
			continue
		if node.position.distance_squared_to(entity_position_according_to_map) < FP_EPSILON:
			var uuid = node.get_meta(&"_godot_to_quake_uuid", -1)
			if uuid == -1:
				# not sure how this would even happen
				push_error("FuncGodotLightpass: unrecoverable")
			return uuid

	push_warning(ERRMSG)
	return -2

static func _parse(cstream: FuncGodotLightpassCharStream) -> FuncGodotLightpassParseData:
	var scopes_count: int = 0
	var data := FuncGodotLightpassParseData.new()
	var has_brushes := false
	var current_entity := {}
	var current_property_key := ""
	var current_property_value := ""
	var entity_string: String
	var comment_string: String
	var parse_step: int = -1
	var comment: bool = false
	const MAX_PARSE_STEP: int = 2 # parse key, middle, then parse value (0 1 2)
	const PARSE_STEP_KEY: int = 0
	const PARSE_STEP_VALUE: int = 2

	while not cstream.is_eof_reached():
		var char := cstream.getchar()
		if char.is_empty():
			return null

		if char == "\n":
			# what to do if a comment is ending
			if comment:
				if scopes_count >= 1:
					entity_string += comment_string
				else:
					data.tokens.push_back(comment_string)
				comment_string = ""

			# what do do with the newline itself
			if scopes_count >= 1:
				entity_string += char
			elif data.tokens.is_empty():
				data.tokens.append(char)
			else:
				data.tokens.push_back(data.tokens.pop_back() + char)
			comment = false
			continue

		if comment:
			comment_string += char
			continue

		var start: int = cstream.get_last_char_position()

		# guaranteed to not be inside a comment at this point
		# this match deals with delimiters that change state
		match char:
			"/":
				if parse_step < 0 and cstream.line_lookahead() == "/":
					comment = true
					cstream.getchar() # eat the second /
					comment_string += "//"
					continue
			"{":
				if parse_step < 0: # allow { in property name
					if scopes_count == 1:
						entity_string += char
						has_brushes = true
					elif scopes_count == 0:
						has_brushes = false
						entity_string = char
						current_entity = {}
					scopes_count += 1
					continue
			"}":
				if parse_step < 0:
					if scopes_count <= 0:
						push_error("FuncGodotLightpass: mismatched braces in map")
						return null
					else:
						entity_string += char

					# leaving entity scope
					if scopes_count == 1:
						if not has_brushes:
							if not _insert_point_entity(data, current_entity):
								return null
						data.tokens.append(entity_string)
					scopes_count -= 1
					continue
			"\"":
				if scopes_count == 1:
					entity_string += char
					parse_step += 1
					if parse_step > MAX_PARSE_STEP:
						# submit parsed KVP
						current_entity[current_property_key] = current_property_value
						current_property_key = ""
						current_property_value = ""
						parse_step = -1 # not parsing
					continue
				parse_step = -1

		# state is decided, now append to tokens
		if scopes_count >= 1:
			entity_string += char

			if scopes_count == 1:
				match parse_step:
					PARSE_STEP_KEY:
						current_property_key += char
					PARSE_STEP_VALUE:
						current_property_value += char

			continue

		# file scope, just directly send characters out
		data.tokens.append(char)

	return data

## Return a dictionary of keys being string classnames mapped to boolean true
## values. These classnames are the entity classnames which should be considered
## as handled by FuncGodotLightpass
static func _build_godot_exportable_classnames(fgd: FuncGodotFGDFile) -> Dictionary:
	var out := {}
	var basefiles := fgd.base_fgd_files.duplicate()
	basefiles.reverse()
	# NOTE: reversed so that FGD at the top gets highest priority
	for base: FuncGodotFGDFile in basefiles:
		out.merge(_build_godot_exportable_classnames(base))
	for def: FuncGodotFGDEntityClass in fgd.entity_definitions:
		if _is_entity_def_godot_exportable(def):
			out[def.classname] = true
	return out

static func _is_entity_def_godot_exportable(def: FuncGodotFGDEntityClass) -> bool:
	if "_godot_to_quake_uuid" in def.class_properties:
		return true
	for base: FuncGodotFGDEntityClass in def.base_classes:
		if _is_entity_def_godot_exportable(base):
			return true
	return false

static func _get_position_from_origin_string(origin: String, inverse_scale_factor: float) -> Vector3:
	var nums: PackedFloat64Array = origin.split_floats(" ", false)
	return Vector3(nums[1], nums[2], nums[0]) / inverse_scale_factor

static func _gather_exportable_nodes(map: FuncGodotMap) -> Array[Node]:
	var nodes: Array[Node] = map.get_tree().get_nodes_in_group(&"godot_to_quake_exportable")
	var out: Array[Node] = []
	for node in nodes:
		var parent := node.get_parent()
		while parent:
			if parent is FuncGodotMap:
				break
			parent = parent.get_parent()
		if not parent or parent != map:
			# this light is outside the FuncGodotMap
			continue
		out.append(node)
	return out

static func _get_point_entity_uuid(entity: Dictionary) -> int:
	if not "_godot_to_quake_uuid" in entity:
		return -1

	var uuid_string: String = entity["_godot_to_quake_uuid"]

	if not uuid_string.is_valid_int():
		push_warning("FuncGodotLightpass: found entity with non-integer ",
		"_godot_to_quake_uuid ", uuid_string)
		return -1

	return uuid_string.to_int()

# return true if good or recoverable error, false if unrecoverable error and
# we should abort before writing to and potentially messing up the file
static func _insert_point_entity(data: FuncGodotLightpassParseData, entity: Dictionary) -> bool:
	if data.tokens.size() in data.token_index_to_entity_index:
		# this should be an assert, but whether or not the calling functions
		# finish or continue on called function failure should be explicit
		push_error("FuncGodotLightpass: duplicate token index for entities, refusing to overwrite and aborting")
		return false
	data.token_index_to_entity_index[data.tokens.size()] = data.point_entities.size()
	data.point_entities.append(entity)

	var uuid := _get_point_entity_uuid(entity)
	if uuid < 0:
		return true

	if uuid != 0:
		var default: Array[Dictionary] = []
		var arr = data.uuids_to_point_entities_buckets.get(uuid, default)
		if not arr.is_empty():
			push_warning("FuncGodotLightpass: entities with duplicate UUID of ", uuid, " found. This may happen if you duplicate lights in trenchbroom.")
		arr.append(entity)
		data.uuids_to_point_entities_buckets[uuid] = arr
	return true

static func _filter_property_list_for_func_godot(object: Object, plist: Array[Dictionary]) -> void:
	const PropertyFilterMode = ObjectSerializer.PropertyFilterMode
	const REMOVE := { mode = PropertyFilterMode.REMOVE }

	# only @export type variables allowed
	ObjectSerializer.filter_properties_without_all_usage_flags(PROPERTY_USAGE_STORAGE, plist)
	ObjectSerializer.filter_properties_with_any_usage_flags(PROPERTY_USAGE_INTERNAL, plist)
	ObjectSerializer.filter_metadata_properties(plist)
	# export_all_exportable_nodes is used by our fgl_node.gd script, just a
	# button
	ObjectSerializer.filter_properties_custom(plist, func(prop: Dictionary) -> bool:
		var name := prop.get("name", "")
		return name == "export_all_exportable_nodes" or name == "script")

	if object is Node:
		ObjectSerializer.filter_properties({
			name = REMOVE,
			owner = REMOVE,
			scene_file_path = REMOVE,
		}, plist)
	if object is Node3D:
		ObjectSerializer.filter_properties({
			basis = REMOVE,
			global_basis = REMOVE,
			global_position = REMOVE,
			global_rotation = REMOVE,
			global_rotation_degrees = REMOVE,
			global_transform = REMOVE,
			position = REMOVE,
			quaternion = REMOVE,
			rotation = REMOVE,
			rotation_degrees = REMOVE,
			transform = REMOVE,
			# TODO: support nodepaths?
			visibility_parent = REMOVE,
		}, plist)
	if object is Light3D:
		ObjectSerializer.filter_properties({
			light_color = { mode = PropertyFilterMode.RENAME, new_name = "color" },
			light_temperature = REMOVE,
		}, plist)

## Returns empty string if the node could not be serialized
static func _serialize_fgl_node_to_map(node: Node, map_node: FuncGodotMap) -> String:
	var is_exportable := node.is_in_group(&"godot_to_quake_exportable")
	if not is_exportable:
		push_error("FuncGodotLightpass: attempt to serialize node ", node,
		" which is not exportable")
		return ""

	var classname: String = node.get_meta(&"_fgl_classname", "")
	if classname.is_empty():
		push_error("FuncGodotLightpass: attempt to serialize node ", node,
		" with no _fgl_classname meta value- does it call ",
		"FuncGodotLightpass.apply_build_metadata in its ",
		"_func_godot_apply_properties function?")
		return ""

	# classname
	var out := "{\n\"classname\" \"" + classname + "\"\n"

	if node is Node3D:
		var transform_relative_to_map: Transform3D = map_node.global_transform.inverse() * node.global_transform
		transform_relative_to_map = transform_relative_to_map.orthonormalized()
		var eulers := transform_relative_to_map.basis.get_euler()
		var degrees := Vector3(rad_to_deg(eulers.x), rad_to_deg(eulers.y), rad_to_deg(eulers.z))

		out += FuncGodotLightpass.serialize_position_to_map(
			map_node.map_settings.inverse_scale_factor,
			transform_relative_to_map.origin)
		out += "\n"
		out += FuncGodotLightpass.serialize_rotation_degrees_to_map(degrees)
		out += "\n"

	# uuid
	var uuid: int = node.get_meta(&"_godot_to_quake_uuid", 0)
	if uuid == 0:
		push_error("FuncGodotLightpass: serializing node with uuid 0, it ",
		"needs to have uuid generated before its serialized to avoid generating",
		" duplicate nodes")
		return ""
	out += str("\"_godot_to_quake_uuid\" \"", uuid, "\"\n")

	# trenchbroom-specific metadata
	if node.has_meta(&"_fgl_tb_group"):
		out += str("\"_tb_group\" ",
		serialize_variant_to_map(node.get_meta(&"_fgl_tb_group")), "\n")
	if node.has_meta(&"_fgl_tb_layer"):
		out += str("\"_tb_layer\" ",
		serialize_variant_to_map(node.get_meta(&"_fgl_tb_layer")), "\n")
	if node.has_meta(&"_fgl_tb_protected_properties"):
		out += str("\"_tb_protected_properties\" ",
		serialize_variant_to_map(
			node.get_meta(&"_fgl_tb_protected_properties")), "\n")

	# all other properties
	var property_list := ObjectSerializer.get_object_properties(node, map_node.map_settings)
	_filter_property_list_for_func_godot(node, property_list)

	var defaults = DEFAULTS_SCRIPT.get_default_values_for_class(node.get_class())
	if defaults.is_empty():
		return ""

	for property in property_list:
		var propname: StringName = property["name"]
		var value: Variant = node.get(propname)
		if value == null:
			# potentially bad property written here. but we can't push a warning
			# because it could also just be a null texture in a decal or
			# something. TODO: try "propname in node" and print warning
			continue

		if "ignore_if" in property or propname in defaults:
			# skip stuff that is default anyways
			var default = property.get("ignore_if", defaults[propname])
			# special case for fp innaccurracies
			if default is float and value is float and absf(value - default) < FP_EPSILON:
				continue
			elif value == defaults[propname]:
				continue

		var outname := property.get("external_name", propname)

		out += "\"" + outname + "\"" + " "
		var serialized := FuncGodotLightpass.serialize_variant_to_map(value)
		if serialized.is_empty():
			return ""
		out += serialized
		out += "\n"

	out += "}\n"
	return out

static func serialize_position_to_map(inverse_scale_factor: float, position: Vector3) -> String:
	# this is the reverse of:
	# origin_vec = Vector3(origin_comps[1], origin_comps[2], origin_comps[0])
	# node.position = origin_vec / map_settings.inverse_scale_factor
	var scaled := position * inverse_scale_factor
	return str("\"origin\" ", "\"", scaled.z, " ", scaled.x, " ", scaled.y,"\"")

static func serialize_rotation_degrees_to_map(rotation_degrees: Vector3) -> String:
	# this function is the reverse of this:
	# angles = Vector3(-angles_raw[0], angles_raw[1], -angles_raw[2])
	# angles.y += 180
	var rounded := Vector3(-rotation_degrees.x, fmod(rotation_degrees.y - 180, 360), rotation_degrees.z)

	# prevent un-rotated nodes getting long, near-zero decimals as angles
	# technically this causes slightttly rotated nodes to be stored
	# differently
	if absf(rounded.x - 360) < FP_EPSILON or absf(rounded.x + 360) < FP_EPSILON or absf(rounded.x) < FP_EPSILON:
		rounded.x = 0
	if absf(rounded.y - 360) < FP_EPSILON or absf(rounded.y + 360) < FP_EPSILON or absf(rounded.y) < FP_EPSILON:
		rounded.y = 0
	if absf(rounded.z - 360) < FP_EPSILON or absf(rounded.z + 360) < FP_EPSILON or absf(rounded.z) < FP_EPSILON:
		rounded.z = 0

	return str("\"angles\" ", "\"", rounded.x, " ", rounded.y, " ", rounded.z,"\"")

## Returns empty string on error
static func serialize_variant_to_map(variant: Variant) -> String:
	match typeof(variant):
		Variant.Type.TYPE_NIL:
			push_error("FuncGodotLightpass: attempt to serialize null value to map file")
			return ""
		Variant.Type.TYPE_BOOL:
			return "\"0\"" if variant == false else "\"1\""
		Variant.Type.TYPE_INT:
			return "\"" + str(int(variant)) + "\""
		Variant.Type.TYPE_FLOAT:
			return "\"" + str(float(variant)) + "\""
		Variant.Type.TYPE_STRING:
			return "\"" + variant + "\""
		Variant.Type.TYPE_STRING_NAME:
			return "\"" + variant + "\""
		Variant.Type.TYPE_COLOR:
			var color: Color = variant
			if color.a != 1.0:
				push_warning("FuncGodotLightpass: serializing color with alpha channel info, discarding that info")
			if color.r > 1 or color.g > 1 or color.b > 1:
				push_warning("FuncGodotLightpass: serializing HDR color, this is untested")
			return "\"" + str(color.r8, " ", color.g8, " ", color.b8) + "\""
		Variant.Type.TYPE_VECTOR2:
			return "\"" + str(float(variant.x), " ", float(variant.y)) + "\""
		Variant.Type.TYPE_VECTOR3:
			return "\"" + str(float(variant.x), " ", float(variant.y), " ", float(variant.z)) + "\""
		Variant.Type.TYPE_OBJECT:
			if variant is Resource:
				var path: String = variant.resource_path
				if path.is_empty():
					push_error("FuncGodotLightpass: attempting to serialize ",
					"resource ", variant,
					" which has no path. Is the scene saved to disk?")
					return ""
				if path.get_slice_count("::") >= 2:
					push_warning("FuncGodotLightpass: Serializing resource ",
					variant, " to a .map file, but it seems to be stored ",
					"within the scene file itself. It could potentially be ",
					"lost or have its UID regenerated, causing loading ",
					"errors. Please save the resource to a permanent file ",
					"location to fix this.")
				var restype: String = "Resource"
				var cls: String = (variant as Object).get_class()
				if variant is Texture:
					restype = "Texture"
				elif variant is Environment:
					restype = "Environment"
				elif variant is CameraAttributes:
					restype = "CameraAttributes"
				elif variant is Compositor:
					restype = "Compositor"
				const DELIMITER := "::"
				return str("\"", restype, DELIMITER, cls, DELIMITER, path, "\"")
	push_error("unable to serialize ", variant)
	return ""
