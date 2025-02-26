extends Panel

@onready var buff_label: Label = $BuffLabel
@onready var hide_timer: Timer = $HideTimer
var count = 0
func _ready() -> void:
	BuffManager.buffs_updated.connect(_on_buffs_updated)
	buff_label.visible = false
	hide_timer.timeout.connect(_on_HideTimer_timeout)

func _on_buffs_updated() -> void:
	count+=1
	update()

func update():
	for i in range(count):
		var msg: String = ""
		visible = true
		$AnimationPlayer.play('fade_in')
		if BuffManager.laser_enabled:
			msg = "Laser Enabled!"
		elif BuffManager.enemy_kills >= 3:
			msg = "Buff Activated:\nSpeed +" + str(int((BuffManager.speed_multiplier - 1) * 100)) + "%" +\
				  " | Damage +" + str(int((BuffManager.damage_multiplier - 1) * 100)) + "%" +\
				  " | Health +" + str(int((BuffManager.health_multiplier - 1) * 100)) + "%"
		elif BuffManager.enemy_kills >= 2:
			msg = "Buff Activated:\nSpeed +" + str(int((BuffManager.speed_multiplier - 1) * 100)) + "%" +\
				  " | Damage +" + str(int((BuffManager.damage_multiplier - 1) * 100)) + "%" +\
				  " | Health +" + str(int((BuffManager.health_multiplier - 1) * 100)) + "%"
		elif BuffManager.enemy_kills >= 1:
			msg = "Buff Activated:\nSpeed +" + str(int((BuffManager.speed_multiplier - 1) * 100)) + "%" +\
				  " | Damage +" + str(int((BuffManager.damage_multiplier - 1) * 100)) + "%" +\
				  " | Health +" + str(int((BuffManager.health_multiplier - 1) * 100)) + "%"
		
		if msg != "":
			buff_label.text = msg
			buff_label.visible = true
			hide_timer.start()

func _on_HideTimer_timeout() -> void:
	$AnimationPlayer.play('fade_out')
