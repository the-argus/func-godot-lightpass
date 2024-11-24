class_name ObjectSerializer

enum PropertyFilterMode {
	REMOVE,
	RENAME,
}

static func get_object_properties(object: Object, context: Variant) -> Array[Dictionary]:
	var has_custom_getter := object.has_method(&"_get_property_list_with_context")
	if has_custom_getter and object.get_method_argument_count(&"_get_property_list_with_context") != 1:
		has_custom_getter = false
		push_warning("Attempt to serialize object ", object,
		" with _get_property_list_with_context() method, but it does not take",
		" exactly one argument. Using get_property_list() instead.")

	return object._get_property_list_with_context(context) if has_custom_getter else object.get_property_list()

static func filter_properties_custom(plist: Array[Dictionary], predicate: Callable) -> void:
	var removal_queue: PackedInt32Array = []
	for idx in plist.size():
		if predicate.call(plist[idx]):
			removal_queue.append(idx)
	removal_queue.reverse()
	for idx in removal_queue:
		plist.remove_at(idx)

## If any of the usage flags given are present in a property, it is removed
static func filter_properties_with_any_usage_flags(usage: PropertyUsageFlags, plist: Array[Dictionary]) -> void:
	filter_properties_custom(plist, func(prop: Dictionary) -> bool: return prop["usage"] & usage)

## if not all of the usage flags given are present in a property, it is removed
static func filter_properties_without_all_usage_flags(usage: PropertyUsageFlags, plist: Array[Dictionary]) -> void:
	filter_properties_custom(plist, func(prop: Dictionary) -> bool: return prop["usage"] & usage == 0)

static func filter_metadata_properties(plist: Array[Dictionary]) -> void:
	filter_properties_custom(plist, func(prop: Dictionary) -> bool: return (prop["name"] as String).begins_with("metadata/"))

## Accepts list of filters to determine how to modify plist
## the remove filter is { mode = PropertyFilterMode.REMOVE }
## the rename filter is { mode = PropertyFilterMode.RENAME, new_name = "some_other_name" }
##   note that the rename filter just embed metadata into the property list, and
##   has to be respected by the consumer of the list
static func filter_properties(filters: Dictionary, plist: Array[Dictionary]) -> void:
	var idx := 0
	while idx < plist.size():
		var property: Dictionary = plist[idx]
		var name: String = property["name"]
		if not name in filters:
			idx += 1
			continue

		var filter: Dictionary = filters[name]
		var mode: PropertyFilterMode = filter.get("mode", PropertyFilterMode.REMOVE)
		match mode:
			PropertyFilterMode.REMOVE:
				plist.remove_at(idx)
			PropertyFilterMode.RENAME:
				var new_name: String = filter["new_name"]
				plist[idx]["external_name"] = new_name
				idx += 1
