# ################
# pause menu controller
# ################
extends Control

# node reference-ek
@onready var resume_button = $Panel/VBoxContainer/ResumeButton
@onready var main_menu_button = $Panel/VBoxContainer/MainMenuButton
@onready var quit_button = $Panel/VBoxContainer/QuitButton

# signalok a gombokhoz
signal resume_requested
signal main_menu_requested
signal quit_requested


# gombok feliratanak valtoztatasa focus allapot alapjan
func _process(_delta: float) -> void:
	if resume_button.has_focus():
		resume_button.text = ">Resume<"
	else:
		resume_button.text = "Resume"
	
	if main_menu_button.has_focus():
		main_menu_button.text = ">Return to main menu<"
	else:
		main_menu_button.text = "Return to main menu"
	
	if quit_button.has_focus():
		quit_button.text = ">Quit<"
	else:
		quit_button.text = "Quit"


# pause menu megjelenesekor focus a resume (folytatas) gombra
func _on_visibility_changed() -> void:
	if visible:
		resume_button.grab_focus()


# resume gomb megnyomasanak kezelese
func _on_resume_button_pressed() -> void:
	emit_signal("resume_requested")


# main menu gomb megnyomasanak kezelese
func _on_main_menu_button_pressed() -> void:
	emit_signal("main_menu_requested")


# quit megnyomasanak kezelese
func _on_quit_button_pressed() -> void:
	emit_signal("quit_requested")
