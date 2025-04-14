# ################
# UI Manager - kozponti controller, ami kezeli az osszes UI-hoz kotheto elemet
# menu valtasok, in-game HUD, death kepernyo, pause menu es befejezo kepernyok kezelese
# ################
extends Node

# node reference-ek
@onready var ui_container = $"../../UIContainer"
@onready var main_menu = $"../../UIContainer/MainMenu" 
@onready var hud = $"../../UIContainer/HUD"
@onready var pause_menu = $"../../UIContainer/PauseMenu"
@onready var game_manager = $"../GameManager"

# player reference-nek -> a ui frissitesehez a player allapota alapjan
var player = null


# UI manager inicializalasa es a signal-ok osszekapcsolasa
func _ready() -> void:
	# main menu signal-ok
	if main_menu:
		if not main_menu.is_connected("start_game_pressed", Callable(self, "_on_start_game_pressed")):
			main_menu.connect("start_game_pressed", Callable(self, "_on_start_game_pressed"))
	
	# pause menu signal-ok
	if pause_menu:
		if pause_menu.has_signal("resume_requested"):
			pause_menu.connect("resume_requested", Callable(self, "_on_resume_requested"))
		if pause_menu.has_signal("main_menu_requested"):
			pause_menu.connect("main_menu_requested", Callable(self, "_on_main_menu_requested"))
		if pause_menu.has_signal("quit_requested"):
			pause_menu.connect("quit_requested", Callable(self, "_on_quit_requested"))
	
	# game manager signal-ok
	if game_manager:
		if not game_manager.is_connected("game_started", Callable(self, "show_game_ui")):
			game_manager.connect("game_started", Callable(self, "show_game_ui"))
		if not game_manager.is_connected("game_paused", Callable(self, "show_pause_menu")):
			game_manager.connect("game_paused", Callable(self, "show_pause_menu"))
		if not game_manager.is_connected("game_resumed", Callable(self, "hide_pause_menu")):
			game_manager.connect("game_resumed", Callable(self, "hide_pause_menu"))
		
		pause_menu.visible = false
	
	if hud:
		hud.visible = false


# start game gomb megnyomasanak kezelese
func _on_start_game_pressed() -> void:
	if game_manager:
		game_manager.start_game()


# player node reference beallitasa
func set_player(player_node) -> void:
	player = player_node
	if hud:
		hud.set_player(player)


# ---- Main menu (fomenu) funkcionalitas ----


# main menu megjelenitese
func show_main_menu() -> void:
	if main_menu:
		main_menu.visible = true
		
		# kovetkezo frame megvarasa, hogy a UI biztosan frissuljon
		await get_tree().process_frame
		
		# focus a start gombra
		var start_button = main_menu.get_node_or_null("VBoxContainer/StartButton")
		if start_button:
			start_button.grab_focus()


# main menu eltuntetese
func hide_main_menu() -> void:
	if main_menu:
		main_menu.visible = false


# ---- HUD funkcionalitas ----


# HUD megjelenitese
func show_hud() -> void:
	if hud:
		hud.visible = true


# HUD eltuntetese
func hide_hud() -> void:
	if hud:
		hud.visible = false


# ---- Pause Menu funkcionalitas ----


# pause menu megjelenitese
func show_pause_menu() -> void:
	if pause_menu:
		pause_menu.visible = true


# pause menu eltuntetese
func hide_pause_menu() -> void:
	if pause_menu:
		pause_menu.visible = false


# ---- Screen (kepernyo) funckionalitas ----


# death screen (kepernyo) megjelenitese, ha meghal a player
func show_death_screen() -> void:
	var death_screen = load("res://1_scenes/6_ui/2_screens/death_screen.tscn").instantiate()
	ui_container.add_child(death_screen)
	death_screen.name = "DeathScreen"


# level completion screen (kepernyo) megjelenitese statisztikaval
func show_level_completed_screen(completion_time: float, multiplier: float, multiplied_score: int) -> void:
	var level_completed = load("res://1_scenes/6_ui/2_screens/level_completed_screen.tscn").instantiate()
	ui_container.add_child(level_completed)
	level_completed.name = "LevelCompletedScreen"
	
	if level_completed.has_method("setup"):
		level_completed.setup(completion_time, multiplier, multiplied_score)
	
	# csatlakozas a level manager-hez (continue gombert)
	var level_manager = get_node_or_null("/root/Main/Managers/LevelManager")
	if level_manager and level_completed.has_signal("continue_pressed"):
		level_completed.connect("continue_pressed", Callable(level_manager, "_on_completion_screen_continue"))


# game completion screen (kepernyo) megjelenitese az osszesitett statisztikaval
func show_game_completed_screen(final_score: int, total_time: float) -> void:
	var game_completed = load("res://1_scenes/6_ui/2_screens/game_completed_screen.tscn").instantiate()
	ui_container.add_child(game_completed)
	game_completed.name = "GameCompletedScreen"
	if game_completed.has_method("setup_statistics"):
		game_completed.setup_statistics(final_score, total_time)


# atvezeto animaciok megjelenitese
func show_transition_animation(animation_name: String) -> void:
	var transition = load("res://1_scenes/6_ui/2_screens/transition_animation.tscn").instantiate()
	ui_container.add_child(transition)
	transition.name = "TransitionAnimation"
	
	# megfelelo animacio beallitasa (mid_game vagy end_game animacio)
	if transition.has_method("set_animation"):
		transition.set_animation(animation_name)
	
	# Connect to level manager for animation completion
	# csatlakozas a level manager-hez (animacio befejezese miatt)
	var level_manager = get_node_or_null("/root/Main/Managers/LevelManager")
	if level_manager and transition.has_signal("animation_completed"):
		transition.connect("animation_completed", Callable(level_manager, "_on_transition_animation_completed"))


# ---- UI-al kapcsolatos fuggvenyek ----


# minden kepernyo eltuntetese a main menu, HUD es pause menu kivetelevel
func clear_overlay_screens() -> void:
	for child in ui_container.get_children():
		if child != main_menu and child != hud and child != pause_menu:
			child.queue_free()


# minden UI elem eltuntetese
func hide_all_game_ui() -> void:
	hide_main_menu()
	hide_hud()
	hide_pause_menu()
	clear_overlay_screens()


# HUD megjelenitese
func show_game_ui() -> void:
	hide_main_menu()
	if hud:
		hud.visible = true
		hud.show_game_ui()


# ---- Pause Menu signal kezelok ----


# pause menu resume (folytatas) gomb megnyomasanak kezelese
func _on_resume_requested() -> void:
	if game_manager:
		game_manager.resume_game()


# pause menu main menu gomb (fomenu) megnyomasanak kezelese
func _on_main_menu_requested() -> void:
	if game_manager:
		game_manager.return_to_main_menu()


# pause menu quit (kilepes) gomb megnyomasanak kezelese
func _on_quit_requested() -> void:
	if game_manager:
		game_manager.quit_game()
