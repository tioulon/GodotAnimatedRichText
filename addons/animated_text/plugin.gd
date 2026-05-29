@tool
extends EditorPlugin

var _base_dir: String

func _enter_tree() -> void:
	_base_dir = get_script().resource_path.get_base_dir()
	var label_script = load(_base_dir + "/animated_rich_label.gd")
	if label_script:
		add_custom_type("AnimatedRichLabel", "RichTextLabel", label_script, null)
	print("[AnimatedText] Plugin loaded from: ", _base_dir)

func _exit_tree() -> void:
	remove_custom_type("AnimatedRichLabel")
