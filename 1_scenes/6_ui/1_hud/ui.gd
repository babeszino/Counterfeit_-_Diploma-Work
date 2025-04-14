# ################
# UI controller script - kezeli az in-game interface-t
# health bar, ammo display, timer es score display kezelese
# ################
extends Control

# node reference-ek
@onready var health_display : Control = $TopContainer/HealthDisplay
@onready var ammo_display : Label = $BottomContainer/AmmoDisplay
@onready var timer_label : Label = $TimerContainer/TimerLabel
@onready var score_display : MarginContainer = $ScoreDisplay

# player reference-nek -> a ui frissitesehez a player allapota alapjan
var player = null


# UI elemek inicializalasa
func _ready() -> void:
	health_display.hide_all_health_bars()
	find_player()


# UI elemek frissitese frame-enkent
func _process(_delta: float) -> void:
	if get_tree().paused:
		return
	
	if player == null:
		find_player()
		return
	
	if !is_instance_valid(player):
		health_display.hide_all_health_bars()
		update_ammo_display("-- / --")
		return
	
	update_player_health()
	update_player_weapon_info()
	update_level_timer()


# player node megkeresese a scene tree-ben
func find_player() -> void:
	for node in get_tree().get_nodes_in_group("player"):
		set_player(node)
		return


# player reference beallitasa es signal-ok csatlakoztatasa
func set_player(player_node) -> void:
	if player != null:
		var old_weapon = player.get_node_or_null("Weapon")
		if old_weapon != null and old_weapon.has_signal("reload_started") and old_weapon.is_connected("reload_started", Callable(self, "_on_weapon_reload_started")):
			old_weapon.disconnect("reload_started", Callable(self, "_on_weapon_reload_started"))
	
	player = player_node


# fegyver ammo-janak (loszerenek) frissitese a megadott String-gel
func update_ammo_display(ammo_text: String) -> void:
	ammo_display.update_ammo(ammo_text)


# a player health display-jenek (eletero megjelenitesenek) frissitese
func update_player_health() -> void:
	if player.hp != null:
		health_display.update_health_bar(player.hp)
	else:
		health_display.hide_all_health_bars()


# player fegyverenek informacioinak megkeresese es frissitese
func update_player_weapon_info() -> void:
	var weapon = find_player_weapon()
	
	if weapon != null and weapon.has_method("get_ammo_display"):
		var ammo_text = weapon.get_ammo_display()
		update_ammo_display(ammo_text)
		
		# csatlakozas a reload signal-hoz
		if weapon.has_signal("reload_started") and !weapon.is_connected("reload_started", Callable(self, "_on_weapon_reload_started")):
			weapon.connect("reload_started", Callable(self, "_on_weapon_reload_started"))
	else:
		update_ammo_display("-- / --")


# player fegyver node-janak megkeresese
func find_player_weapon() -> Node:
	var weapon
	for child in player.get_children():
			if child.has_method("get_ammo_display"):
				weapon = child
				break
				
	return weapon


# aktualis palya timer-jenek frissitese (a UI-on, jobb felso sarok)
func update_level_timer() -> void:
	var level_manager = get_node_or_null("/root/Main/Managers/LevelManager")
	if level_manager and level_manager.level_start_time > 0:
		var current_time = Time.get_ticks_msec() / 1000.0
		var elapsed_time = current_time - level_manager.level_start_time
		update_timer(elapsed_time)


# a pause menu resume (folytatas) hivasanak kezelese
func _on_pause_menu_resume_requested() -> void:
	var game_manager = get_node_or_null("/root/Main/Managers/GameManager")
	if game_manager:
		game_manager.resume_game()


# a pause menu main menu (fomenu) hivasanak kezelese
func _on_pause_menu_main_menu_requested() -> void:
	var game_manager = get_node_or_null("/root/Main/Managers/GameManager")
	if game_manager:
		get_tree().paused = false
		game_manager.return_to_main_menu()


# a pause menu quit (kilepes) hivasanak kezelese
func _on_pause_menu_quit_requested() -> void:
	var game_manager = get_node_or_null("/root/Main/Managers/GameManager")
	if game_manager:
		game_manager.quit_game()


# aktualis palya timer-jenek (jobb felso sarok) formazasa (MM:SS) es frissitese
func update_timer(elapsed_seconds: float) -> void:
	var minutes = int(elapsed_seconds) / 60
	var seconds = int(elapsed_seconds) % 60
	timer_label.text = "Time: " + str(minutes) + ":" + str(seconds).pad_zeros(2)


# reload progress bar inditasa, frissitese
func _on_weapon_reload_started(duration: float) -> void:
	if ammo_display and ammo_display.has_method("start_reload_progress"):
		ammo_display.start_reload_progress(duration)


# UI elemek megjelenitese
func show_game_ui() -> void:
	$TopContainer.visible = true
	$BottomContainer.visible = true
	$TimerContainer.visible = true
	
	health_display.visible = true
	ammo_display.visible = true
	timer_label.visible = true
	score_display.visible = true


# UI elemek eltuntetese
func hide_game_ui() -> void:
	if health_display:
		health_display.visible = false
	if ammo_display:
		ammo_display.visible = false
	if timer_label:
		timer_label.visible = false
	if score_display:
		score_display.visible = false
	
	$TopContainer.visible = false
	$BottomContainer.visible = false
	$TimerContainer.visible = false
