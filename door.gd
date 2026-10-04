extends StaticBody2D

## Locked door that blocks the player until a key unlocks it. Add it to the
## "doors" group (see the scene's group list) so keys can find it.

@onready var _sprite: Sprite2D = $Sprite2D


func unlock() -> void:
	# Stop blocking the player, then fade the door away.
	set_deferred("collision_layer", 0)
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.4)