extends CharacterBody2D

signal health_changed(new_value)
signal max_health_changed(new_value)

@export var base_speed: float = 150.0
@export var no_bullets: int = 1
var current_speed: float
var direction := Vector2.ZERO
var max_health: int = 100
var current_health: int = 100


@onready var sprite = $AnimatedSprite2D
@onready var anim = $AnimationPlayer
@onready var weapon = $Weapon
@onready var weapon_scale = weapon.scale
var right = true

@export var enable_laser: bool = false
@export var enable_bullet: bool = true

@export var LaserBeamScene: PackedScene
@export var BulletScene: PackedScene

func _ready():
	BuffManager.buffs_updated.connect(buffed)
	BuffManager.ground_buffs_updated.connect(ground_buff)
	current_speed = base_speed

func buffed():
	max_health = BuffManager.health_multiplier * max_health
	current_health = BuffManager.health_multiplier * current_health
	current_speed = base_speed * BuffManager.speed_multiplier
	print('current health')
	print(current_health)
	max_health_changed.emit(max_health)
	
func ground_buff(text, value, amount):
	match value:
		BuffManager.Buffs.BULLETS:
			no_bullets += amount
		BuffManager.Buffs.HEALTH:
			max_health *= BuffManager.health_multiplier
			current_health *= BuffManager.health_multiplier
			health_changed.emit(current_health)
			max_health_changed.emit(max_health)
		BuffManager.Buffs.SPEED:
			current_speed = base_speed * BuffManager.speed_multiplier

func _process(_delta: float) -> void:
	enable_laser = BuffManager.laser_enabled
	handle_movement()
	play_animation()
	
	if Input.is_action_just_pressed("attack"):
		if enable_laser && LaserBeamScene:
			shoot_laser()
		if enable_bullet && BulletScene:
			shoot_bullet()

func handle_movement() -> void:
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
	if abs(direction.x) > 0 or abs(direction.y) > 0:
		velocity = direction * current_speed
	else:
		velocity = lerp(velocity, Vector2.ZERO, 0.25)
	move_and_slide()

func play_animation() -> void:
	if Input.is_action_just_pressed("attack"):
		if right:
			anim.play("attack_r")
		else:
			anim.play("attack_l")
	elif direction != Vector2.ZERO:
		sprite.play("walk")
	else:
		sprite.play("idle")
	
	if direction.x != 0:
		weapon.scale.x = sign(direction.x) * weapon_scale.x
		sprite.flip_h = direction.x < 0
		right = direction.x > 0

func shoot_laser() -> void:
	var laser = LaserBeamScene.instantiate()
	laser.position = weapon.global_position
	var target_dir = (get_global_mouse_position() - weapon.global_position).normalized()
	laser.direction = target_dir
	laser.rotation = target_dir.angle() + PI/2
	get_tree().current_scene.add_child(laser)

func shoot_bullet() -> void:
	for i in range(no_bullets):
		var bullet = BulletScene.instantiate()
		var target_dir : Vector2 = (get_global_mouse_position() - weapon.global_position).normalized()
		bullet.position = global_position + target_dir * 20
		if (i>0):
			if i%2==0:
				bullet.position = bullet.position + target_dir.rotated(PI/2) * 10 * i
			if i%2!=0:
				bullet.position = bullet.position - target_dir.rotated(PI/2) * 10 * i
		bullet.direction = target_dir
		bullet.rotation = target_dir.angle()
		get_tree().current_scene.add_child(bullet)

func take_damage(amount: int) -> void:
	current_health = clamp(current_health - amount, 0, max_health)
	health_changed.emit(current_health)
	
	if current_health <= 0:
		die()
	$HurtSound.play()
	anim.play("hurt_flash")
	if get_viewport():
		get_viewport().get_camera_2d().apply_shake(0.15, 2)

func die() -> void:
	print("dead")
	
	get_tree().change_scene_to_file("res://game_over.tscn")
func apply_knockback(force: Vector2) -> void:
	velocity += force
	move_and_slide()
