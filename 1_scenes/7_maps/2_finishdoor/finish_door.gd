# ################
# palya befejezesi ajto, ami akkor nyilik ki, ha minden enemy halott az aktualis palyan
# ha a player bemegy az ajton, akkor trigger-elodik az atvezeto animacio
# ################
extends Node2D

# node reference-ek
@onready var door_animation = $FinishDoor/FinishDoorAnimation
@onready var door_collision = $DoorBody/CollisionShape2D

var door_is_open : bool = false


# ajto kinyitasa
func open():
	if door_is_open:
		return
	else:
		door_is_open = true
	
	if door_animation:
		door_animation.play("open")
		await door_animation.animation_finished
	
	door_collision.disabled = true


# atvezeto animacio trigger-elese, ha a player bemegy az ajton
func _on_body_entered(body):
	if body.is_in_group("player"):
		var level_manager = get_node_or_null("/root/Main/Managers/LevelManager")
		if level_manager:
			level_manager.call_deferred("load_next_map")
