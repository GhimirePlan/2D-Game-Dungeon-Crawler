extends Camera2D
@export var target_path :NodePath
var shake_duration: float = 0.0
var shake_magnitude: float = 0.0
var target 
func _ready():
	RandomNumberGenerator.new().randomize()
	target = get_node(target_path) 
	if target: 
		position = target.position

func apply_shake(duration: float, magnitude: float) -> void:
	shake_duration = duration
	shake_magnitude = magnitude
func _process(delta):
	if !target:
		return 
	if shake_duration > 0.0:
		shake_duration -= delta
		var offset_x = randf_range(-shake_magnitude, shake_magnitude)
		var offset_y = randf_range(-shake_magnitude, shake_magnitude)
		offset = Vector2(offset_x, offset_y)
	else:
		offset = Vector2.ZERO
	position = lerp(position, target.position,0.2)
