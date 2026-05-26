extends CharacterBody2D

@export var speed: float = 250.0

# Reference to your animation player node
@onready var animated_sprite: AnimatedSprite2D = $Sprite2D

# Tracks the last direction the player moved ("down", "up", or "right")
var last_direction: String = "down"

func _physics_process(_delta: float) -> void:
	# Automatically maps WASD / Arrows and normalizes diagonal speeds
	var direction := Input.get_vector("left", "right", "up", "down")
	
	if direction != Vector2.ZERO:
		velocity = direction * speed
		update_facing_direction(direction)
		play_animation("walk")
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		play_animation("idle")

	move_and_slide()

# Determines which direction string to use and handles horizontal mirroring
func update_facing_direction(dir: Vector2) -> void:
	if abs(dir.x) >= abs(dir.y):
		last_direction = "right" # Both left and right movement will point to the "right" animations
		if dir.x > 0:
			animated_sprite.flip_h = false # Facing right normally
		else:
			animated_sprite.flip_h = true  # Mirror the sprite to face left
	else:
		last_direction = "down" if dir.y > 0 else "up"
		# Optional: Turn off mirroring when moving strictly up or down so character isn't flipped weirdly
		animated_sprite.flip_h = false 

# Combines the state with our updated direction parameters
func play_animation(state: String) -> void:
	var anim_name = state + "_" + last_direction
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)
