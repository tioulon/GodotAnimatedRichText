extends Control

@export var animated_rich_label: AnimatedRichLabel
@export var label: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(1).timeout
	animated_rich_label.play_in()
	label.text = "indo"
	pass # Replace with function body.
