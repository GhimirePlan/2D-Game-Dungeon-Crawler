extends Area2D

@export var speed: float = 600.0
@export var damage: int = 10
@export var lifetime: float = 1  
var direction: Vector2 = Vector2.ZERO

func _ready():
	body_entered.connect(_on_Laser_body_entered)

func _process(delta: float) -> void:
	lifetime -= delta
	$AnimationPlayer.play("beam")
	if lifetime <= 0:
		queue_free()

func _on_Laser_body_entered(body: Node) -> void:
	print(body)
	if !body.is_in_group('player') && !body.is_in_group('dungeon'):
		if body.has_method("take_damage") && body.current_health >0:
			body.take_damage(damage)
