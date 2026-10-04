extends Control

## Simple win screen shown after the final level.

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://node_2d.tscn")