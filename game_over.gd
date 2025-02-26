extends Control


func _ready():
	$VBoxContainer/RestartButton.pressed.connect(_on_restart_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_restart_pressed():
	BuffManager.reset_buffs()
	get_tree().change_scene_to_file("res://main.tscn")

func _on_quit_pressed():
	get_tree().quit()
