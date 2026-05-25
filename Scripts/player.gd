extends CharacterBody2D

@export var speed: float = 250.0

func _physics_process(_delta: float) -> void:
	# Automatically maps WASD / Arrows and normalizes diagonal speeds
	var direction := Input.get_vector("left", "right", "up", "down")
	
	if direction != Vector2.ZERO:
		velocity = direction * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)

	move_and_slide()
