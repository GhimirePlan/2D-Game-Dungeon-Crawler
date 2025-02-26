extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK }

@export var speed: float = 60
@export var patrol_points: Array[Vector2]
@export var detection_radius: float = 125
@export var attack_range: float = 25
@export var obstacle_check_rays: int = 8
@export var avoidance_strength: float = 5.0
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 400
@export var health_drop: PackedScene
@export var max_health: int = 100
var current_health: int = max_health

@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var patrol_timer: Timer = $PatrolTimer
@onready var attack_area: Area2D = $AttackArea

var attack_damage: int = 10
var attack_knockback: float = 200

var current_state: State = State.PATROL
var target: Node2D = null
var current_patrol_index: int = 0
var can_attack: bool = true

func _ready():
	var shape = CircleShape2D.new()
	shape.radius = detection_radius
	detection_area.get_node("CollisionShape2D").shape = shape
	
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	patrol_timer.timeout.connect(_update_patrol_target)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	if patrol_points.size() > 0:
		_update_patrol_target()

func _physics_process(delta):
	match current_state:
		State.PATROL:
			_patrol_state()
		State.CHASE:
			_chase_state()
		State.ATTACK:
			_attack_state()
	
	move_and_slide()

func _patrol_state():
	if patrol_points.is_empty():
		return
	
	var target_point = patrol_points[current_patrol_index]
	var to_target = target_point - global_position
	
	if to_target.length() < 5:
		patrol_timer.start(1.0)
		return
	
	var move_dir = to_target.normalized()
	velocity = _apply_obstacle_avoidance(move_dir) * speed
	move_and_slide()

func _chase_state():
	if not target:
		current_state = State.PATROL
		return
	
	var to_target = target.global_position - global_position
	var distance = to_target.length()
	
	if distance <= attack_range:
		current_state = State.ATTACK
		return
	
	var base_dir = to_target.normalized()
	var final_dir = _apply_obstacle_avoidance(base_dir)
	velocity = final_dir * speed

func _attack_state():
	velocity = lerp(velocity, Vector2.ZERO, 0.2)
	if not target or global_position.distance_to(target.global_position) > attack_range:
		current_state = State.CHASE
		return
	
	if can_attack:
		_perform_attack()
		can_attack = false
		attack_timer.start(1.0)
	move_and_slide()

func _apply_obstacle_avoidance(base_direction: Vector2) -> Vector2:
	var adjusted_direction = base_direction
	var space_state = get_world_2d().direct_space_state
	
	for i in obstacle_check_rays:
		var angle = lerp(-PI/4, PI/4, float(i) / obstacle_check_rays)
		var check_dir = base_direction.rotated(angle)
		var params = PhysicsRayQueryParameters2D.new()
		params.from = global_position
		params.to = global_position + check_dir * 10
		params.exclude = [self]
		
		var result = space_state.intersect_ray(params)
		if result:
			var avoid_dir = -check_dir
			var weight = 1.0 - (result.position.distance_to(global_position) / 50)
			adjusted_direction += avoid_dir * weight * avoidance_strength
	
	return adjusted_direction.normalized()

func _perform_attack():
	if target and can_attack:
		print("ATTACKING")
		var distance = global_position.distance_to(target.global_position)
		if distance <= attack_range:
			if target.has_method("take_damage"):
				target.take_damage(attack_damage)
			
			var dir = (target.global_position - global_position).normalized()
			target.apply_knockback(dir * attack_knockback)
		
		if target and can_attack and projectile_scene:
			var projectile = projectile_scene.instantiate()
			get_parent().add_child(projectile)
			
			var target_pos = target.global_position
			var direction = (target_pos - global_position).normalized()
			
			projectile.global_position = global_position + direction * 20
			projectile.rotation = direction.angle()
			projectile.velocity = direction * projectile_speed
			
			can_attack = false
			$AttackTimer.start()

func _update_patrol_target():
	current_patrol_index = (current_patrol_index + 1) % patrol_points.size()

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		target = body
		current_state = State.CHASE

func _on_body_exited(body: Node2D):
	if body == target:
		target = null
		current_state = State.PATROL

func _on_attack_timer_timeout():
	print("CAN ATTACi")
	can_attack = true


func take_damage(amount: int) -> void:
	current_health -= amount
	print("Enemy took ", amount, " damage. Health left: ", current_health)
	if current_health <= 0:
		die()

func die() -> void:
	print("Enemy died!")
	var r = randi_range(1,100)
	if(r<=20):
		var health_drop_node = health_drop.instantiate()
		health_drop_node.global_position = global_position
		get_tree().current_scene.add_child(health_drop_node)
	BuffManager.add_enemy_kill()
	queue_free() 
