extends CharacterBody2D

@export var speed: float = 150.0
var direction := Vector2.ZERO

@onready var sprite = $AnimatedSprite2D
@onready var anim = $AnimationPlayer
@onready var weapon = $Weapon
@onready var weapon_scale = weapon.scale
var right = true
func _process(_delta):
	handle_movement()
	play_animation()

func handle_movement():
	direction = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	
	direction = direction.normalized()
	velocity = direction * speed
	move_and_slide()

func play_animation():
	if Input.is_action_just_pressed("attack"):
		if right:
			anim.play('attack_r')
		else:
			anim.play('attack_l')
	elif direction != Vector2.ZERO:
		sprite.play("walk")
	else:
		sprite.play("idle")
	
	if direction.x != 0:
		weapon.scale.x = sign(direction.x) * weapon_scale.x
		sprite.flip_h = direction.x < 0
		right = direction.x > 0
