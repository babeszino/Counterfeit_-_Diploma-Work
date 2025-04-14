# ################
# enemy spawn-olas es kezeles
# spawn-olas es tracking kezelese, illetve cleanup a palyakon
# ################
extends Node

# node reference-ek
@onready var enemy_container = $"../../EnemyContainer" 
@onready var level_container = $"../../LevelContainer"
@onready var game_manager = $"../GameManager"
@onready var weapon_manager = $"../WeaponManager"
@onready var level_manager = $"../LevelManager"

# enemy scene preload
var enemy_scene = preload("res://1_scenes/3_enemy/enemy.tscn")

# enemy tracking
var active_enemies = []
var current_map_sequence = 0


# signal-ok osszekotese
func _ready():
	# a game_manager script game_started signal-janak osszekotese a clear_enemies fuggvennyel
	if game_manager:
		game_manager.connect("game_started", Callable(self, "clear_enemies"))
	
	# a level_manager script map_ready signal-janak osszekotese az _on_map_ready fuggvennyel
	if level_manager:
		level_manager.connect("map_ready", Callable(self, "_on_map_ready"))


# minden aktiv enemy eltavolitasa
func clear_enemies() -> void:
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	var all_enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in all_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	active_enemies.clear()


# enemy halal kezelese
func _on_enemy_died() -> void:
	
	# signal a game manager script-nek
	if game_manager and game_manager.has_method("on_enemy_died"):
		game_manager.on_enemy_died()
	
	# aktiv enemy-k szamontartasa
	var valid_enemies = []
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			valid_enemies.append(enemy)
	active_enemies = valid_enemies


# uj map betoltesenek kezelese
func _on_map_ready(map_instance, sequence_position) -> void:
	current_map_sequence = sequence_position
	
	spawn_enemies_on_map(map_instance)


# enemy-k spawn-olasa az aktualis palyan
func spawn_enemies_on_map(map_instance):
	clear_enemies()
	
	if not map_instance:
		return
		
	var spawn_points = map_instance.get_node_or_null("SpawnPoints")
	if not spawn_points:
		return
	
	# enemy spawnpoint-ok feldolgozasa
	for child in spawn_points.get_children():
		if "EnemySpawn" in child.name:
			var enemy = enemy_scene.instantiate()
			enemy_container.add_child(enemy)
			enemy.global_position = child.global_position
			
			# enemy_died signal osszekotese - (finish door kinyilasahoz)
			if not enemy.is_connected("enemy_died", Callable(self, "_on_enemy_died")):
				enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))
			
			# megfelelo fegyver az enemy-nek
			if enemy.has_method("equip_weapon"):
				if weapon_manager:
					var weapon = null
					
					# level 5 -> enemy-nek ismet M4 fegyvernek
					if current_map_sequence == 4:
						weapon = weapon_manager.get_weapon_instance("M4")
					
					else:
						weapon = weapon_manager.get_weapon_for_level(current_map_sequence)
					
					if weapon:
						enemy.equip_weapon(weapon)
			
			# register a game manager-ben
			if game_manager and game_manager.has_method("register_enemy"):
				game_manager.register_enemy()
			
			active_enemies.append(enemy)
