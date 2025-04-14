# ################
# player falugras kepesseg
# lehetove teszi, hogy a player atugorjon ugrofalakon (JumpWall tilemap layer-eken)
# ################
extends Node2D

# node reference-ek
@onready var wall_jump_ray = $WallJumpRay
@onready var player = get_parent()
@onready var player_animation = $"../AnimatedSprite2D"

# falugras konfiguracios valtozok
var detection_radius : float = 130.0
var jump_through_distance : float = 50.0
var jump_cooldown : float = 0.5

# valtozok az ugras allapotanak kovetesehez
var can_jump : bool = true
var cooldown_timer : float = 0.0
var nearest_wall_position : Vector2 = Vector2.ZERO


# cooldown timer frissitese es a legkozelebbi fal keresese
func _physics_process(delta):
	if !can_jump:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			can_jump = true
	
	find_and_point_to_nearest_wall()


# ugras input kezelese, es ugras (ha lehetseges)
func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("jump") and can_jump:
		attempt_wall_jump()


# legkozelebbi ugrofal megkeresese -> raycast ramutatasa
func find_and_point_to_nearest_wall():
	# tilemap-ek megkeresese a scene-ben
	var all_tilemaps = []
	find_all_nodes_of_type(player.get_tree().root, "TileMapLayer", all_tilemaps)
	
	# a JumpWalls tilemap layer megkeresese
	var jump_walls_layer = null
	for tilemap in all_tilemaps:
		if "jumpwalls" in tilemap.name.to_lower():
			jump_walls_layer = tilemap
			break
	
	# visszateres ha nem talalhato jumpwalls layer
	if not jump_walls_layer:
		nearest_wall_position = Vector2.ZERO
		return
	
	var nearest_distance = detection_radius + 1
	nearest_wall_position = Vector2.ZERO
	
	# player pozicio tilemap koordinataba konvertalasa
	var player_tile_position = jump_walls_layer.local_to_map(jump_walls_layer.to_local(player.global_position))
	var search_area_size = Vector2i(10, 10) #Vector2i tilemap miatt
	var search_start_tile = player_tile_position - search_area_size / 2
	
	# ugrofalak keresese player koruli teruleten
	for x in range(search_start_tile.x, search_start_tile.x + search_area_size.x):
		for y in range(search_start_tile.y, search_start_tile.y + search_area_size.y):
			var current_tile_position = Vector2i(x, y)
			var tile_id = jump_walls_layer.get_cell_source_id(current_tile_position)
			
			if tile_id != -1:  # nem -1, tehat ugrofal (valid id-ja van)
				var wall_pos = jump_walls_layer.to_global(jump_walls_layer.map_to_local(current_tile_position))
				var distance = player.global_position.distance_to(wall_pos)
				
				# legkozelebbi fal track-elese
				if distance < nearest_distance:
					nearest_distance = distance
					nearest_wall_position = wall_pos
	
	# a raycast legkozelebbi falra valo mutatasa (ha talalhato)
	if nearest_wall_position:
		var global_direction = (nearest_wall_position - player.global_position).normalized()
		var local_direction = global_direction.rotated(-global_rotation)
		
		wall_jump_ray.target_position = local_direction * detection_radius
		wall_jump_ray.force_raycast_update()
		
	else:
		wall_jump_ray.target_position = Vector2.ZERO


# falugras megprobalasa
func attempt_wall_jump():
	wall_jump_ray.force_raycast_update()
	
	# ellenorizzuk, hogy a raycast falba utkozott e, illetve milyen messze van a legkozelebbi ugrofal pozicio
	if wall_jump_ray.is_colliding() and nearest_wall_position:
		var hit_pos = wall_jump_ray.get_collision_point()
		var hit_distance = player.global_position.distance_to(hit_pos)
		
		# falugras csak akkor, ha a hatotavon belul vagyunk
		if hit_distance <= detection_radius:
			var direction = (hit_pos - player.global_position).normalized()
			
			# falugras utani pozicio kiszamolasa (erkezesi pozicio)
			var jump_distance = jump_through_distance
			var destination_pos = player.global_position + direction * jump_distance
			
			# ellenorizzuk, hogy akadalymentes-e az erkezesi pozicio
			var space_state = player.get_world_2d().direct_space_state
			var obstacle_query = PhysicsRayQueryParameters2D.create(hit_pos + direction * 5.0, destination_pos)
			obstacle_query.collision_mask = 1 # 1 - falak
			var obstacle_check = space_state.intersect_ray(obstacle_query)
			
			# falugras, ha akadalymentes az erkezesi pozicio
			if not obstacle_check:
				player.global_position = destination_pos
				
				# falugras cooldown elinditasa
				can_jump = false
				cooldown_timer = jump_cooldown
				
				# player flash animacio falugraskor
				if player_animation and player_animation.visible:
					var original_modulate = player_animation.modulate
					player_animation.modulate = Color(1.5, 1.5, 1.5)
					
					# eredeti kinezet visszaallitasa flash animacio utan
					var timer = player.get_tree().create_timer(0.1)
					await timer.timeout
					player_animation.modulate = original_modulate


# node kereso fuggveny - TileMapLayer node-ok megtalalasahoz a find_and_point_to_nearest_wall fuggvenyben
func find_all_nodes_of_type(node, type_name, result_array):
	if node.get_class() == type_name:
		result_array.append(node)
	
	for child in node.get_children():
		find_all_nodes_of_type(child, type_name, result_array)
