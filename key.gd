extends Area2D

## Collectable key. Touching it unlocks every door in the level, then the key
## pops and disappears.


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return
	# Setting monitoring directly inside a signal callback is blocked.
	set_deferred("monitoring", false)
	# Unlock every door in this level.
	get_tree().call_group("doors", "unlock")

	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 24.0, 0.25)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)