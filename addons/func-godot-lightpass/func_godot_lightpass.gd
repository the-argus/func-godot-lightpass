@tool
class_name FuncGodotLightpass
extends EditorPlugin

const CUSTOM_NODE_FGD_CLASSNAMES := [
	"lite_omni",
	"lite_spot",
	"lite_directional",
]
const CUSTOM_NODE_NAMES := [
	"FGLOmniLight",
	"FGLSpotLight",
	"FGLDirectionalLight",
]
const CUSTOM_NODE_SCRIPTS := [
	preload("./lights/scripts/fglight_omni.gd"),
	preload("./lights/scripts/fglight_spot.gd"),
	preload("./lights/scripts/fglight_directional.gd"),
]
const CUSTOM_NODE_INHERITANCE := [
	"OmniLight3D",
	"SpotLight3D",
	"DirectionalLight3D",
]
const LIGHT_ICON = preload("./icon/omni.png")

func _enter_tree() -> void:
	for idx in CUSTOM_NODE_NAMES.size():
		add_custom_type(
			CUSTOM_NODE_NAMES[idx],
			CUSTOM_NODE_INHERITANCE[idx],
			CUSTOM_NODE_SCRIPTS[idx],
			LIGHT_ICON)

func _exit_tree() -> void:
	for nodename in CUSTOM_NODE_NAMES:
		remove_custom_type(nodename)

class FuncGodotLightpassParseData:
	var tokens: Array[String] = []
	var point_entities: Array[Dictionary] = []
	var token_index_to_entity_index := {}
	var uuids_to_point_entities := {}
	var point_entities_with_zero_uuid: Array[Dictionary] = []

## Given a func_godot map node, find all the lights under it and write those to
## its local map file.
static func update_mapfile_with_lightpass_lights(node: FuncGodotMap) -> void:
	var map_settings := node.map_settings
	var map_file := node.global_map_file if node.global_map_file != "" else node.local_map_file
	if not map_file or map_file.is_empty():
		push_error("FuncGodotLightpass: attempt to export lights under a ",
		"FuncGodotMap with no set map file.")
		return

	var cstream := FuncGodotLightpassCharStream.new(map_file)
	if not cstream.is_good(): return

	var data: FuncGodotLightpassParseData = _parse(cstream)
	if not data: return

	var lights := _gather_light_nodes(node)
	# generate uuids for lights that that have uuid zero
	var used_uuids := data.uuids_to_point_entities.duplicate()
	var uuids_to_lights := {}
	var gen_uuid := func() -> int:
		var uuid: int = -1
		while uuid <= 0 or uuid in used_uuids:
			uuid = randi()
		return uuid
	# in case the user assigned a uuid somehow
	for light in lights:
		var uuid: int = light._fgl_get_uuid()

		if uuid == 0:
			continue
		if uuid < 0:
			push_error("FuncGodotLightpass: Found light with negative ",
			"uuid, refusing to serialize as some code relies on uuids ",
			"being positive")
			return

		if not used_uuids.has(uuid):
			used_uuids[uuid] = true

		if uuid in uuids_to_lights:
			push_warning("FuncGodotLightpass: duplicate uuid ", uuid,
			" from node ", light, " and ", uuids_to_lights[uuid],
			". This can happen if you copy nodes in godot, and is ",
			"harmless in that case.")
			uuid = gen_uuid.call()
			light._fgl_set_uuid(uuid)
			used_uuids[uuid] = true
		uuids_to_lights[uuid] = light

	for light in lights:
		if light._fgl_get_uuid() == 0:
			var uuid: int = gen_uuid.call()
			light._fgl_set_uuid(uuid)
			used_uuids[uuid] = true
			uuids_to_lights[uuid] = light

	var tokens: Array[String] = []
	var serialized_uuids := {}

	# replace all modified entities with their new serialized versions
	for token_idx in data.tokens.size():
		if token_idx in data.token_index_to_entity_index:
			var entity: Dictionary = data.point_entities[data.token_index_to_entity_index[token_idx]]
			var uuid := _get_point_entity_uuid(entity)
			if uuid >= 0: # this is some godot exportable entity
				# this has a uuid, now check if its in the map and replace it
				# with the updated version
				if uuid in uuids_to_lights:
					var light: FuncGodotLightpassBaseLight = uuids_to_lights[uuid]
					var serialized := _serialize_fgl_node_to_map(
						light, map_settings)
					if serialized.is_empty():
						return # could also just not change this node?
					tokens.append(serialized)
					assert(not uuid in serialized_uuids)
					serialized_uuids[uuid] = true
					continue
				# this entity no longer exists in the map (there is not
				# a corresponding light node) so dont append it back to
				# the map file
				continue
		tokens.append(data.tokens[token_idx])

	# remove the EOF newline since we're appending with newlines already
	if tokens.back() == "\n":
		tokens.pop_back()
	
	# append any new entities
	for light in lights:
		var uuid: int = light._fgl_get_uuid()
		if not uuid in serialized_uuids:
			var serialized := _serialize_fgl_node_to_map(light, map_settings)
			if serialized.is_empty():
				return
			tokens.append(serialized)

	# erase the whole file!! if closed here data could be lost
	var map: FileAccess = FileAccess.open(map_file, FileAccess.READ_WRITE)
	map.resize(0)
	for token in tokens:
		map.store_string(token)
	map.close()
	print("FuncGodotLightpass: export to .map file completed.")

static func _parse(cstream: FuncGodotLightpassCharStream) -> FuncGodotLightpassParseData:
	var scopes_count: int = 0
	var data := FuncGodotLightpassParseData.new()
	var has_brushes := false
	var current_entity := {}
	var current_property_key := ""
	var current_property_value := ""
	var entity_string: String
	var comment_string: String
	var slashcount: int = 0
	var parse_step: int = -1
	const MAX_PARSE_STEP: int = 2 # parse key, middle, then parse value (0 1 2)
	const PARSE_STEP_KEY: int = 0
	const PARSE_STEP_VALUE: int = 2

	while not cstream.is_eof_reached():
		var char := cstream.getchar()
		if char.is_empty():
			return null

		if char == "\n":
			# what to do if a comment is ending
			if slashcount >= 2:
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
			slashcount = 0
			continue

		if slashcount >= 2:
			comment_string += char
			continue
		if slashcount == 1 and char != "/": # slashes must be consecutive
			# make up for the skipped /
			if scopes_count >= 1:
				entity_string += "/"
			else:
				data.tokens.append("/")
			slashcount = 0

		var start: int = cstream.get_last_char_position()

		# guaranteed to not be inside a comment at this point
		# this match deals with delimiters that change state
		match char:
			"/":
				if slashcount == 1:
					comment_string = "//"
				slashcount += 1
				continue
			"{":
				if scopes_count == 1:
					entity_string += char
					# NOTE: not allowing { or } to be in property names
					has_brushes = true
				elif scopes_count == 0:
					has_brushes = false
					entity_string = char
					current_entity = {}
				scopes_count += 1
				continue
			"}":
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

static func _gather_light_nodes(map: FuncGodotMap) -> Array[FuncGodotLightpassBaseLight]:
	var nodes: Array[Node] = map.get_tree().get_nodes_in_group(&"func_godot_lightpass_light")
	var out: Array[FuncGodotLightpassBaseLight] = []
	for node in nodes:
		if not node is FuncGodotLightpassBaseLight:
			continue
		var parent := node.get_parent()
		while parent:
			if parent is FuncGodotMap:
				break
			parent = parent.get_parent()
		if not parent or parent != map:
			# this light is outside the FuncGodotMap
			continue
		else:
			# reparent all the lights to be directly below the func godot map,
			# so its local transform accounts for all of its offset
			# (when we serialize we only store local position)
			node.reparent(map, true)
		out.append(node as FuncGodotLightpassBaseLight)
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
		# this should basically be an assert, but those seeem to be useless in
		# tool scripts, so propagate up return value errors instead
		push_error("FuncGodotLightpass: duplicate token index for entities, refusing to overwrite and aborting")
		return false
	data.token_index_to_entity_index[data.tokens.size()] = data.point_entities.size()
	data.point_entities.append(entity)

	var uuid := _get_point_entity_uuid(entity)
	if uuid < 0:
		return true

	if uuid == 0:
		data.point_entities_with_zero_uuid.append(entity)
	else:
		if uuid in data.uuids_to_point_entities:
			push_error("FuncGodotLightpass: entities with duplicate UUIDs ",
			"found. No recovery for this is currently implemented.")
			return false
		data.uuids_to_point_entities[uuid] = entity
	return true

static func _verify_node_is_fgl_node(node: Node3D) -> bool:
	var has_classname := node.has_method("_fgl_get_classname")
	var has_get_uuid := node.has_method("_fgl_get_uuid")
	var has_set_uuid := node.has_method("_fgl_set_uuid")
	var is_func_godot_node := node.has_method("_func_godot_apply_properties")
	var is_exportable := node.is_in_group(&"godot_to_quake_exportable")
	return is_exportable and has_classname and has_get_uuid and has_set_uuid and is_func_godot_node

## Returns empty string if the node could not be serialized
static func _serialize_fgl_node_to_map(node: Node3D, map_settings: FuncGodotMapSettings) -> String:
	if not _verify_node_is_fgl_node(node):
		push_error("FuncGodotLightpass: attempt to serialize node ", node,
		" to map file, but it does not implement all the needed functions")
		return ""
	if (node._fgl_get_classname as Callable).get_argument_count() > 0 or not node._fgl_get_classname() is String:
		push_error("FuncGodotLightpass: node ", node,
		"has _fgl_get_classname() function but it does not take 0 parameters ",
		"and return a string.")
		return ""
	if (node._fgl_get_uuid as Callable).get_argument_count() > 0 or not node._fgl_get_uuid() is int:
		push_error("FuncGodotLightpass: node ", node,
		"has _fgl_get_uuid() function but it does not take 0 parameters ",
		"and return an int.")
		return ""

	var classname: String = node._fgl_get_classname() as String
	if classname.is_empty():
		push_error("FuncGodotLightpass: attempt to serialize node ", node,
		" with no fgd_classname")
		return ""
	# classname
	var out := "{\n\"classname\" \"" + classname + "\"\n"
	# origin
	out += FuncGodotLightpass.serialize_position_to_map(map_settings.inverse_scale_factor, node.position)
	out += "\n"
	# angles
	out += FuncGodotLightpass.serialize_rotation_degrees_to_map(node.rotation_degrees)
	out += "\n"
		# uuid
	var uuid: int = node._fgl_get_uuid()
	if uuid == 0:
		push_error("FuncGodotLightpass: serializing node with uuid 0, it ",
		"needs to have uuid generated before its serialized to avoid generating",
		" duplicate nodes")
		return ""
	out += str("\"_godot_to_quake_uuid\" \"", uuid, "\"\n") 
	# all other properties
	if node.has_method("_fgl_get_properties_string"):
		var getprops: Callable = node._fgl_get_properties_string
		if getprops.get_argument_count() == 0:
			var out_variant = node._fgl_get_properties_string()
			if out_variant is String:
				# TODO: probably parse the output here to verify we are
				# returning valid .map file content
				out += out_variant
			else:
				push_warning("FuncGodotLightpass: node ", node,
				" returned something other than a string from ",
				"_fgl_get_properties_string, ignoring")
		else:
			push_warning("FuncGodotLightpass: node ", node, " implements ",
			"_fgl_get_properties_string but it does not take zero arguments, ",
			"ignoring.")
	out += "}\n"
	return out

static func serialize_position_to_map(inverse_scale_factor: float, position: Vector3) -> String:
	# this is the reverse of:
	# origin_vec = Vector3(origin_comps[1], origin_comps[2], origin_comps[0])
	# node.position = origin_vec / map_settings.inverse_scale_factor
	var scaled := position * inverse_scale_factor
	return str("\"origin\" ", "\"", scaled.z, " ", scaled.x, " ", scaled.y,"\"")

static func serialize_rotation_degrees_to_map(rotation_degrees: Vector3) -> String:
	# this is the reverse of this:
	# angles = Vector3(-angles_raw[0], angles_raw[1], -angles_raw[2])
	# angles.y += 180
	return str("\"angles\" ", "\"", -rotation_degrees.x, " ", rotation_degrees.y - 180, " ", -rotation_degrees.z,"\"")

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
			return "\"" + str(variant) + "\""
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
		_:
			push_error("unable to serialize ", variant)
	return ""
