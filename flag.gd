extends Area2D

## Collectable goal flag. When the player touches it, the level is complete and
## the game moves on to `next_level`. Leave `next_level` empty to replay this
## level (useful while there is only one level).
@export_file("*.tscn") var next_level: String = ""

## How long the little "collected" pop lasts before the level changes.
const COLLECT_TIME := 0.3

var _collected := false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _collected or not (body is CharacterBody2D):
		return
	_collected = true
	# Stop it firing again while the collection animation plays. (Setting this
	# directly inside a signal callback is blocked, so defer it.)
	set_deferred("monitoring", false)

	var tween := create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, COLLECT_TIME)
	tween.parallel().tween_property(_sprite, "position:y", _sprite.position.y - 14.0, COLLECT_TIME)
	tween.tween_callback(_advance_level)


func _advance_level() -> void:
	if next_level.is_empty():
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file(next_level)
