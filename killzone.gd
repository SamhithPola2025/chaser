extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Checks if the object falling into the zone is the player
	if body is CharacterBody2D:
		# Reloads the current level
		get_tree().reload_current_scene()
