extends TextureProgressBar

var player_node 

func _ready():
	var color = lerp(Color.RED, Color.GREEN, 1)
	modulate = color
	player_node = get_tree().get_nodes_in_group('player')[0]
	max_value = player_node.max_health
	value = player_node.current_health
	player_node.health_changed.connect(update_health)
	player_node.max_health_changed.connect(update_max_health)

func update_health(new_value: float):
	create_tween().tween_property(self, "value", new_value, 0.3)
	
	var color = lerp(Color.RED, Color.GREEN, new_value / max_value)
	modulate = color

func update_max_health(new_value: float):
	max_value = player_node.max_health
	update_health(player_node.current_health)
