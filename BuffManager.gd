extends Node

var enemy_kills: int = 0

var speed_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var health_multiplier: float = 1.0
var laser_enabled: bool = false

signal buffs_updated()
signal max_health_changed()

func add_enemy_kill() -> void:
	enemy_kills += 1
	update_buffs()
	print("Total enemy kills: ", enemy_kills, " | Speed Buff: ", speed_multiplier, " Damage Buff: ", damage_multiplier, " Health Buff: ", health_multiplier)

func update_buffs() -> void:
	if enemy_kills > 20:
		return
	elif enemy_kills == 20:
		laser_enabled = true
		emit_signal("buffs_updated")
	elif enemy_kills == 15:
		speed_multiplier = 1.3
		damage_multiplier = 1.5
		health_multiplier = 1.4
		emit_signal("buffs_updated")
		emit_signal("max_health_changed")
	elif enemy_kills == 10:
		speed_multiplier = 1.2
		damage_multiplier = 1.3
		health_multiplier = 1.2
		emit_signal("buffs_updated")
		emit_signal("max_health_changed")
	elif enemy_kills == 5:
		speed_multiplier = 1.1
		damage_multiplier = 1.1
		health_multiplier = 1.1
		emit_signal("buffs_updated")
		emit_signal("max_health_changed")
	else:
		speed_multiplier = 1.0
		damage_multiplier = 1.0
		health_multiplier = 1.0

func reset_buffs() -> void:
	enemy_kills = 0
	update_buffs()
	emit_signal("buffs_updated")
