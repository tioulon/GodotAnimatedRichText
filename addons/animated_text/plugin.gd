@tool
extends EditorPlugin

## AnimatedRichLabel and all animation resources register themselves via their
## `class_name` declarations, so they appear in the Create Node / New Resource
## dialogs automatically. We deliberately do NOT call add_custom_type() here:
## doing so would register a SECOND type with the same name as the class_name,
## which collides and can corrupt the node (e.g. the script's doc text leaking
## into the RichTextLabel as BBCode). This plugin script exists mainly so the
## addon can be toggled in Project Settings > Plugins.

func _enter_tree() -> void:
	pass

func _exit_tree() -> void:
	pass
