# ################
# atvezeto animaciok
# atvezeto animacio lejatszasa, input prompt megjelenitese es input fogadasa
# ################
extends CanvasLayer

# signal -> ha az atvezeto animacionak vege es a player ad input-ot
signal animation_completed

# node reference-ek
@onready var animation = $Animation
@onready var animation_timer = $AnimationTimer
@onready var continue_label = $ContinueLabel

# atvezeto animacio allapot valtozok
var animation_name = "mid_game"
var waiting_for_input = false


# az atvezeto animacio es timer elinditasa
func _ready():
	# rovid varakozas az animation_name valtozo ertekenek beallitasara
	await get_tree().create_timer(0.05).timeout
	
	animation.play(animation_name)
	animation_timer.start()


# Continue (folytatas) prompt megjelenitese es input fogadasa, ha lejar az animation_timer
func _on_animation_timer_timeout():
	continue_label.visible = true
	waiting_for_input = true


# input fogadasa -> ha jon input, akkor animation_completed signal kuldese es az atvezeto animacio eltuntetese
func _input(event):
	if waiting_for_input and event is InputEventKey and event.pressed:
		emit_signal("animation_completed")
		queue_free()


# megfelelo animacio beallitasa (mid_game vagy end_game animaciok kozul)
func set_animation(anim_name):
	animation_name = anim_name
	
	if is_node_ready():
		animation.play(animation_name)
