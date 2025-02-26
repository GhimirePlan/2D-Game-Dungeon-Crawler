extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	if body.is_in_group('player'):
		body.current_health = clamp(body.current_health+0.2*body.max_health, body.current_health,body.max_health)
		body.health_changed.emit(body.current_health)
		queue_free()
