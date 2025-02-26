extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, RAGE, DEATH }
enum AttackType { PROJECTILE, SPREAD_SHOT, MELEE, CHARGE, ENRAGED_SPREAD_SHOT }

@export var speed: float = 80
@export var detection_radius: float = 300
@export var attack_range: float = 35
@export var charge_range: float =500
@export var max_health: int = 14000
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 300

@onready var health_bar: TextureProgressBar = $CanvasLayer/TextureProgressBar
@onready var attack_timer: Timer = $AttackTimer
@onready var charge_timer: Timer = $ChargeTimer
@onready var DetectionArea : Area2D = $DetectionRange
@onready var ExitDetectionArea : Area2D = $ExitDetectionRange
var sizex
var sizey
var inPos : Vector2
var current_health: int
var attack = false
var player: Node2D = null
var current_state: State = State.IDLE
var enraged: bool = false
var player_pos
var charge_ = false

func _ready():
	set_process(false)
	DetectionArea.get_node("CollisionShape2D").shape.size.x = sizex * 16 / scale.x
	DetectionArea.get_node("CollisionShape2D").shape.size.y = sizey * 16 / scale.y
	ExitDetectionArea.get_node("CollisionShape2D").shape.size.x = sizex * 16 * 1.5 /scale.x
	ExitDetectionArea.get_node("CollisionShape2D").shape.size.y = sizey * 16 * 1.5 / scale.y
	current_health = max_health
	health_bar.max_value = max_health
	health_bar.value = current_health
	attack_timer.timeout.connect(_perform_attack)
	charge_timer.timeout.connect(charge)
	DetectionArea.body_entered.connect(player_detected)
	ExitDetectionArea.body_exited.connect(player_exited)
	player = get_tree().get_nodes_in_group('player')[0]
	inPos = global_position

func player_detected(body):
	if body.is_in_group('player') && !body.is_in_group('enemy'):
		$CanvasLayer.visible = true
		if current_health >0:
			set_process(true)
func player_exited(body):
	if body.is_in_group('player') && !body.is_in_group('enemy'):
		$CanvasLayer.visible = false
		global_position = inPos
		current_health = max_health
		set_process(false)

func _process(_delta):
	if player:
		var distance = global_position.distance_to(player.global_position)
		
		if enraged and distance <= charge_range:
			current_state = State.RAGE
		else:
			current_state = State.CHASE

	match current_state:
		State.CHASE:
			if attack_timer.is_stopped():
				attack_timer.start(2.0)
			_chase_player() 
		State.RAGE:
			if attack_timer.is_stopped():
				attack_timer.start(0.5)
			
			if charge_timer.is_stopped():
				charge_timer.start(2)
			_charge_attack()
		State.DEATH:
			pass

func _chase_player():
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

func _perform_attack():
	if not player:
		return
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	var attack_choice = randi() % (4 if enraged else 3)  
	
	match attack_choice:
		AttackType.PROJECTILE:
			_shoot_projectile()
		AttackType.SPREAD_SHOT:
			if(enraged):
				_spread_shot(20)
			else:
				_spread_shot(8)
		AttackType.MELEE:
			_melee_attack()

	attack_timer.start(1.5)  

func _shoot_projectile():
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	projectile.direction = (player.global_position - global_position).normalized()
	print("Boss uses projectile attack!")

func _spread_shot(number):
	print("Boss uses spread shot attack!")
	var angl = 2* PI / number
	var directions = [
	]
	for i in range(number):
		var dir:Vector2 =  Vector2(cos((i+1)*angl),sin((i+1)*angl))
		directions.append(dir)
	for dir in directions:
		var projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position
		projectile.direction = dir 

func _melee_attack():
	print("Boss uses melee attack!")
	if player.global_position.distance_to(global_position) <= attack_range:
		player.take_damage(60)  
func charge():
	if player:
		player_pos = player.global_position
	attack = true
	var charge_direction = (player_pos - global_position).normalized()
	velocity = charge_direction * (speed * 4)

func _charge_attack():
	if player:
		print("Boss uses charge attack!")
		velocity = lerp(velocity, Vector2.ZERO, 0.02)
		move_and_slide()
		print("Boss uses melee attack!")
		if player.global_position.distance_to(global_position) <= attack_range && attack:
			player.take_damage(30)  
			attack = false

func take_damage(amount: int):
	current_health -= amount
	health_bar.value = current_health
	if current_health <= max_health * 0.5 and !enraged:
		_enter_rage_mode()
	if current_health <= 0:
		die()

func _enter_rage_mode():
	enraged = true
	speed *= 1.5
	attack_timer.wait_time *= 0.7  
	attack_range *= 1.45
	scale *= 2
	print("Boss is enraged!")

func die():
	print("Boss defeated!")
	$CollisionShape2D.disabled = true
	attack_timer.stop()
	
	current_state = State.DEATH
	$DeathSound.play()
	set_process(false)
	await get_tree().create_timer(8).timeout
	visible = false
	await get_tree().create_timer(1).timeout
	get_tree().change_scene_to_file("res://game_win.tscn")
	queue_free()
