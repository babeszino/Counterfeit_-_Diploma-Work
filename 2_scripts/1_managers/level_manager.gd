# ################
# lev el controller script - palyabetoltes, atvezetesek, tovabbhaladas
# kezeli a palyakat, a player pozicionalasat es egy palya befejezeset
# ################
extends Node

# map ready signal - emit, ha egy uj palya betolt es ready
signal map_ready(map_instance, sequence_position)

# node reference-ek
@onready var level_container = $"../../LevelContainer"
@onready var player_container = $"../../PlayerContainer"
@onready var game_manager = $"../GameManager"
@onready var enemy_manager = $"../EnemyManager"

# palyakezelo valtozok
var current_map_index : int = 0
var current_map_sequence_position : int = 0
var maps : Array = []
var maps_path : String = "res://1_scenes/7_maps/1_layouts/"
var randomized_map_indexes : Array = []

# palya timer valtozok
var level_start_time : float = 0.0
var level_completion_time : float = 0.0
var total_time : float = 0.0

# teljesitesi ido threshold-ok (kuszobok) szorzohoz
var very_fast_times : Array = [16.0, 19.0, 16.0, 17.0, 18.0] # x1.5 times
var fast_times : Array = [20.0, 23.0, 20.0, 21.0, 22.0] # x1.25 times

# jelenlegi palya reference-ek
var current_map_instance = null
var finish_door_container = null


# palyak keresesenek elinditasa
func _ready() -> void:
	find_existing_maps()


#  palyak kigyujtese a mappajukbol
func find_existing_maps() -> void:
	var dir = DirAccess.open(maps_path)
	dir.list_dir_begin()
	
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.begins_with("map_layout") and file_name.ends_with(".tscn"):
			maps.append(maps_path + file_name)
		file_name = dir.get_next()
		
	maps.sort()


# randomizalt sorozat letrehozasa a palyaknak
func randomize_map_order() -> void:
	randomized_map_indexes = []
	for i in range(maps.size()):
		randomized_map_indexes.append(i)
	
	randomized_map_indexes.shuffle()


# a palyasorozat inditasa
func start_sequence() -> void:
	randomize_map_order()
	current_map_sequence_position = 0
	switch_to_map(randomized_map_indexes[current_map_sequence_position])


# palyavaltas - palya betoltese es beallitasa
func switch_to_map(map_index) -> void:
	if map_index < 0 or map_index >= maps.size():
		return
	
	current_map_index = map_index
	
	cleanup_current_map()
	
	if game_manager:
		game_manager.enemy_count = 0
	
	var map_scene = load(maps[map_index])
	if map_scene:
		current_map_instance = map_scene.instantiate()
		current_map_instance.name = "current_map"
		level_container.add_child(current_map_instance)
		
		await get_tree().process_frame
		
		position_player_on_map()
		reset_player_stats()
		assign_weapon()
		
		emit_signal("map_ready", current_map_instance, current_map_sequence_position)
		
		start_level_timer()
		
		find_door()


# jelenlegi palya befejezesenek feldolgozasa es kovetkezo palya betoltese
func load_next_map() -> void:
	var multiplier = calculate_score_multiplier()
	
	var score_system = $"../ScoreSystem"
	var current_score = 0
	var multiplied_score = 0
	
	if score_system:
		current_score = score_system.score
		multiplied_score = int(current_score * multiplier)
	
	total_time += level_completion_time
	
	if current_map_sequence_position + 1 >= randomized_map_indexes.size():
		get_tree().paused = true
		show_game_completed_screen()
		return
	
	get_tree().paused = true
	
	var ui_manager = get_node_or_null("/root/Main/Managers/UIManager") 
	if ui_manager and ui_manager.has_method("show_level_completed_screen"):
		ui_manager.show_level_completed_screen(level_completion_time, multiplier, multiplied_score)


# folytatas a kovetkezo palyara, ha a jatekos continue-t nyom
func _on_completion_screen_continue(multiplier: float) -> void:
	get_tree().paused = false
	
	var score_system = $"../ScoreSystem"
	if score_system:
		score_system.apply_multiplier(multiplier)
	
	current_map_sequence_position += 1
	
	# atvezeto animaciok megjelenitese a masodik es a negyedik palya befejezese utan
	if current_map_sequence_position == 2 or current_map_sequence_position == 4:
		var ui_manager = get_node_or_null("/root/Main/Managers/UIManager")
		if ui_manager and ui_manager.has_method("show_transition_animation"):
			var animation_to_play = "mid_game"
			if current_map_sequence_position == 4:
				animation_to_play = "end_game"
			
			ui_manager.show_transition_animation(animation_to_play)
			return
	
	if current_map_sequence_position >= randomized_map_indexes.size():
		show_game_completed_screen()
		return
	
	var next_map_index = randomized_map_indexes[current_map_sequence_position]
	switch_to_map(next_map_index)


# ha vege az atvezeto animacionak
func _on_transition_animation_completed() -> void:
	if current_map_sequence_position >= randomized_map_indexes.size():
		show_game_completed_screen()
		return
	
	var next_map_index = randomized_map_indexes[current_map_sequence_position]
	switch_to_map(next_map_index)


# a player elhelyezese a PlayerSpawn Marker2D node poziciojaba
func position_player_on_map() -> void:
	var player = game_manager.player if game_manager else null
	
	if !player or !current_map_instance:
		return
	
	var spawn_point = current_map_instance.get_node_or_null("SpawnPoints/PlayerSpawn")
	if spawn_point:
		player.global_position = spawn_point.global_position


# a finish door megkeresese az aktualis palyan
func find_door() -> void:
	if !current_map_instance:
		return
	
	finish_door_container = current_map_instance.get_node_or_null("FinishDoorContainer")


# a player eleterejenek es fegyverenek (ujratoltes) reset-elese 
func reset_player_stats() -> void:
	var player = game_manager.player if game_manager else null
	
	if !player:
		return
		
	player.hp = 100
	
	var weapon = player.get_node_or_null("Weapon")
	if weapon != null:
		if weapon.get("max_ammo") != null and weapon.get("current_ammo") != null:
			weapon.current_ammo = weapon.max_ammo
		
		if weapon.get("is_reloading") != null:
			weapon.is_reloading = false


# aktualis palya cleanup-olasa (takaritasa) -> bloodstain effektek eltuntetese
func cleanup_current_map() -> void:
	if current_map_instance:
		current_map_instance.queue_free()
		current_map_instance = null
	
	var bloodstains = get_tree().get_nodes_in_group("bloodstain")
	for bloodstain in bloodstains:
		bloodstain.queue_free()


# jatek befejezo kepernyo megjelenitese
# vegso statisztikak megjelenitese - osszesitett pontszam, osszesitett teljesitesi ido
func show_game_completed_screen() -> void:
	if game_manager:
		game_manager.cleanup_entities()
	
	if current_map_instance:
		current_map_instance.queue_free()
		current_map_instance = null
	
	var score_system = $"../ScoreSystem"
	var final_score = 0
	
	if score_system:
		final_score = score_system.score
	
	var ui_manager = get_node_or_null("/root/Main/Managers/UIManager")
	if ui_manager and ui_manager.has_method("show_game_completed_screen"):
		ui_manager.show_game_completed_screen(final_score, total_time)
	
	current_map_sequence_position = 0


# helyes fegyveradas a player-nek a az aktualis palyasorozat szama alapjan
func assign_weapon() -> void:
	var player = game_manager.player if game_manager else null
	
	if !player:
		return
	
	var weapon_manager = $"../WeaponManager"
	if weapon_manager:
		var weapon = weapon_manager.get_weapon_for_level(current_map_sequence_position)
		if weapon and player.has_method("equip_weapon"):
			player.equip_weapon(weapon)


# palya timer elinditasa
func start_level_timer() -> void:
	level_start_time = Time.get_ticks_msec() / 1000.0


# palya vegi szorzo meghatarozasa az aktualis palya threshold-jai alapjan
func calculate_score_multiplier() -> float:
	level_completion_time = (Time.get_ticks_msec() / 1000) - level_start_time
	
	var very_fast_threshold : float
	var fast_threshold : float
	
	if current_map_sequence_position < randomized_map_indexes.size():
		var map_index = randomized_map_indexes[current_map_sequence_position]
		
		if map_index < very_fast_times.size():
			fast_threshold = fast_times[map_index]
	
	if level_completion_time <= very_fast_threshold:
		return 1.5
	
	elif level_completion_time <= fast_threshold:
		return 1.25
	
	else:
		return 1.0
