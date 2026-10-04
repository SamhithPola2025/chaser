extends CharacterBody2D

# Breakable ground (crumbles under the player) and an optional permanent layer.
@onready var tile_map: TileMapLayer = get_node_or_null("../TileMapLayer")
@onready var solid_map: TileMapLayer = get_node_or_null("../SolidGround")
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@onready var grass_sound: AudioStreamPlayer2D = $GrassStreamPlayer2D
@onready var gravel_sound: AudioStreamPlayer2D = $GravelStreamPlayer2D2
@onready var dirt_sound: AudioStreamPlayer2D = $DirtStreamPlayer2D3

const SPEED_DEFAULT := 300.0
const JUMP_VELOCITY := -400.0
const TILE_BREAK_TIME := 1.0

# Sentinel for "not standing on any tile".
const NO_TILE := Vector2i(-999, -999)

var SPEED := SPEED_DEFAULT

# The tile the player is currently standing on, and how long they've stood on it.
var _stood_tile: Vector2i = NO_TILE
var _stand_time := 0.0

func _physics_process(delta: float) -> void:
	# Manual reset: R reloads the current level from the start.
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()
		return

	# Gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Horizontal movement.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	_handle_ground_tile(delta)


# Applies surface effects, crumbles the tile left behind, and breaks the tile
# the player has been standing on for too long.
func _handle_ground_tile(delta: float) -> void:
	var ground := _get_ground_tile()
	if ground.is_empty():
		# Off the ground: pause the stand timer. The trail tile is kept so it
		# still crumbles if we touch down on a different tile.
		_stand_time = 0.0
		return

	var cell: Vector2i = ground["cell"]
	var tile_data: TileData = ground["data"]

	# Existing surface effects (footstep sounds + speed changes).
	if tile_data:
		var surface: String = tile_data.get_custom_data("surface_type")
		if surface:
			_handle_surface_effects(surface)

	# Permanent ground never breaks. It is the safe fallback path, so stepping
	# off a breakable tile onto it still crumbles the tile left behind.
	if not ground["breakable"]:
		if _stood_tile != NO_TILE:
			tile_map.erase_cell(_stood_tile)
		_stood_tile = NO_TILE
		_stand_time = 0.0
		return

	# Stepped onto a new tile: the one we just left crumbles behind us.
	if cell != _stood_tile:
		if _stood_tile != NO_TILE:
			tile_map.erase_cell(_stood_tile)
		_stood_tile = cell
		_stand_time = 0.0
		return

	# Stood on the same tile for too long: it breaks under our feet.
	_stand_time += delta
	if _stand_time >= TILE_BREAK_TIME:
		tile_map.erase_cell(_stood_tile)
		_stood_tile = NO_TILE
		_stand_time = 0.0


# Returns the tile directly under the player's feet, or an empty dictionary.
func _get_ground_tile() -> Dictionary:
	if not is_on_floor():
		return {}
	# Look the cell up from the player's position rather than from slide
	# collisions: a resting body frequently reports no collision for the floor
	# it's standing on, so collisions can't be trusted to find the ground tile.
	# Use whichever ground layer exists to convert the feet position to a cell.
	var mapper: TileMapLayer = tile_map if tile_map else solid_map
	if mapper == null:
		return {}
	var cell: Vector2i = mapper.local_to_map(mapper.to_local(_feet_position()))
	# Breakable ground takes priority; otherwise fall back to permanent ground.
	if tile_map and tile_map.get_cell_source_id(cell) != -1:
		return {"cell": cell, "data": tile_map.get_cell_tile_data(cell), "breakable": true}
	if solid_map and solid_map.get_cell_source_id(cell) != -1:
		return {"cell": cell, "data": solid_map.get_cell_tile_data(cell), "breakable": false}
	return {}


# World position of the point just below the bottom of the player's collider.
func _feet_position() -> Vector2:
	var half_height := 0.0
	var rect := collision_shape.shape as RectangleShape2D
	if rect:
		half_height = rect.size.y * 0.5
	return global_position + Vector2(0, collision_shape.position.y + half_height + 1.0)

func _handle_surface_effects(surface_name: String) -> void:
	match surface_name:
		"grass":
			if not grass_sound.playing:
				grass_sound.play()
			SPEED = 300
		"gravel":
			if not gravel_sound.playing:
				gravel_sound.play()
			SPEED = 150
		"dirt":
			if not dirt_sound.playing:
				dirt_sound.play()
			SPEED = 250
		_:
			print("Unknown surface: ", surface_name)
			SPEED = 300
