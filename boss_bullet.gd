extends Area2D

@export var speed: float = 500.0
@export var damage: int = 35
@export var lifetime: float = 2.0
var direction: Vector2 = Vector2.ZERO

func _ready():
	body_entered.connect(_on_Bullet_body_entered)

func _process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_Bullet_body_entered(body: Node) -> void:
	if !body.is_in_group('enemy'):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
