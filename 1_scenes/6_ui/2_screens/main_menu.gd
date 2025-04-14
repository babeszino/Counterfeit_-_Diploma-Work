# ################
# fomenu controller
# ################
extends Control

# signal -> start gomb megnyomasa
signal start_game_pressed

# node reference-ek
@onready var start_button = $VBoxContainer/StartButton
@onready var quit_button = $VBoxContainer/QuitButton


# focus a start gombra
func _ready() -> void:
	start_button.grab_focus()


# gombok feliratanak valtoztatasa focus allapot alapjan
func _process(_delta: float) -> void:
	if start_button.has_focus():
		start_button.text = ">Start<"
	else:
		start_button.text = "Start"
	
	if quit_button.has_focus():
		quit_button.text = ">Quit<"
	else:
		quit_button.text = "Quit"


# start gomb megnyomasanak kezelese
func _on_start_button_pressed() -> void:
	emit_signal("start_game_pressed")
	visible = false


# quit gomb megnyomasanak kezelese
func _on_quit_button_pressed() -> void:
	get_tree().quit()
