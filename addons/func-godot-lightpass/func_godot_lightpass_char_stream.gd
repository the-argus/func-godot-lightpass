## Opens an ascii file and then generates characters one at a time.
class_name FuncGodotLightpassCharStream
extends RefCounted

var _readhead: int = 0

var _is_file: bool
var _fileline: String
var _file_line_offset: int = 0
var _file: FileAccess = null
var _content: String
var _is_good: bool = false

func is_good() -> bool:
	return _is_good

func _init(path: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)

	if file == null:
		# if this fires, check the godot docs on the @GlobalScope Error enum
		# to translate the error code into something comprehensible. just
		# ctrl + click on get_open_error() here, if you're in the builtin editor
		push_error("FuncGodotLightpass: failed to open file (",
		path, ") with READ permission, error code: ",
		FileAccess.get_open_error())
		return

	var lines: PackedStringArray = []

	if path.ends_with(".import"):
		while not file.eof_reached():
			var line: String = file.get_line()
			if line.begins_with("path"):
				file.close()
				line = line.replace("path=", "");
				line = line.replace('"', '')
				var map_data: String = (load(line) as QuakeMapFile).map_data
				if map_data.is_empty():
					printerr("FuncGodotLightpass: failed to open map file (" + line + ")")
					return
				_content = map_data
				_is_file = false # not _file, use _content instead
				break
	else:
		_file = file
		_fileline = _file.get_line()
		_is_file = true
	_is_good = true

func close() -> void:
	if _is_file:
		_file.close()

func is_eof_reached() -> bool:
	if _is_file:
		return _file.eof_reached() and _file_line_offset >= _fileline.length()
	else:
		return _readhead >= _content.length()

func get_last_char_position() -> int:
	return _readhead - 1

## Allows looking ahead on character on the current line. If looking ahead over
## a line break or past EOF, returns empty string.
func line_lookahead() -> String:
	if is_eof_reached():
		return ""
	if _is_file:
		if _file_line_offset + 1 >= _fileline.length():
			return ""
		else:
			return _fileline[_file_line_offset + 1]
	else:
		if _readhead + 1 >= _content.length(): return ""
		return _content[_readhead + 1]

func getchar() -> String:
	if is_eof_reached():
		push_error("FuncGodotLightpass: getchar called but EOF reached")
		return ""
	var out: String
	if _is_file:
		if _file_line_offset >= _fileline.length():
			_fileline = _file.get_line()
			_file_line_offset = 0
			out = "\n"
		else:
			out = _fileline[_file_line_offset]
			_file_line_offset += 1
	else:
		out = _content[_readhead]
	_readhead += 1
	if not out.length() == 1:
		push_error("FuncGodotLightpass: bad getchar result")
		return ""
	return out
