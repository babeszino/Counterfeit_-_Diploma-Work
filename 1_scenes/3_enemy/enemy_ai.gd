# ################
# enemy ai controller
# enemy state-ek (guard, attack), targeting kezelese
# ################
extends Node2D

# enemy viselkedes state-ek
enum State { GUARD, ATTACK }

# node reference-ek
@onready var player_detection_zone = $PlayerDetectionZone
@onready var bullet_detection_zone = $BulletDetectionZone
@onready var line_of_sight = $LineOfSightRay

# reference valtozok
var player : CharacterBody2D = null
var weapon = null
var enemy : CharacterBody2D = null

# state valtozo
var current_state : int = State.GUARD # default state - guard


# ai inicializasa
func _ready() -> void:
	await get_tree().process_frame # wait for parent to load
	current_state = State.GUARD
	
	if line_of_sight:
		line_of_sight.enabled = true
	
	# player node megkeresese a scene-ben
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0:
		player = player_nodes[0]


# enemy viselkedes feldolgozasa jelenlegi helyzet alapjan
func _physics_process(delta: float) -> void:
	update_line_of_sight()
	process_current_state(delta)


# a line of sight raycast player-re mutatasa
func update_line_of_sight() -> void:
	var tracked_player = find_player()
	if tracked_player != null and enemy != null and line_of_sight != null:
		var global_direction = (tracked_player.global_position - enemy.global_position).normalized()
		var local_direction = global_direction.rotated(-enemy.rotation)
		
		line_of_sight.target_position = local_direction * 5000
		line_of_sight.force_raycast_update()


# player megkeresese a scene-ben
func find_player() -> CharacterBody2D:
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0:
		return player_nodes[0]
	return null


# enemy viselkedesenek feldolgozasa a jelenlegi state alapjan
func process_current_state(delta: float) -> void:
	match current_state:
		State.GUARD:
			process_guard_state(delta)
			
		State.ATTACK:
			process_attack_state(delta)
			
		_:
			printerr("something went very wrong, it should either be GUARD or ATTACK")


# enemy viselkedese guard state-ben
func process_guard_state(_delta: float) -> void:
	var enemy_movement = enemy.get_node_or_null("EnemyMovement")
	if enemy_movement:
		enemy_movement.patrol()
	else:
		if enemy:
			enemy.velocity = Vector2.ZERO


# enemy viselkedese attack state-ben
func process_attack_state(_delta: float) -> void:
	if player != null and weapon != null and enemy != null:
		var direction = enemy.global_position.direction_to(player.global_position)
		enemy.rotation = lerp_angle(enemy.rotation, direction.angle(), 0.1)
		
		if has_line_of_sight_to_player():
			if weapon.get("auto_fire") == true:
				if weapon.has_method("can_shoot") and weapon.can_shoot():
					weapon.shoot(direction)
			
			else:
				weapon.shoot(direction)


# enemy es weapon node reference-ek inicializalasa
func initialize(enemy_node, weapon_node):
	self.enemy = enemy_node
	self.weapon = weapon_node
	
	if line_of_sight:
		line_of_sight.enabled = true


# enemy state valtoztatasa
func set_state(new_state: int):
	if new_state == current_state:
		return
	
	current_state = new_state
	
	# navigation update-elese, ha attack state-be kerul az enemy
	if new_state == State.ATTACK and enemy != null and enemy.has_method("update_path"):
		enemy.update_path()


# ellenorzes, hogy a jatekosra tisztan ralat-e az enemy (van-e tiszta line of sight)
func has_line_of_sight_to_player() -> bool:
	if player == null or enemy == null or line_of_sight == null:
		return false
	
	var global_direction = (player.global_position - enemy.global_position).normalized()
	var distance = enemy.global_position.distance_to(player.global_position)
	
	var local_direction = global_direction.rotated(-enemy.rotation)
	
	# ray iranyitasa a player pozicioja fele
	line_of_sight.target_position = local_direction * distance
	line_of_sight.force_raycast_update()
	
	if line_of_sight.is_colliding():
		var collider = line_of_sight.get_collider()
		
		# true, ha a raycast collide-ol a player-rel
		if collider == player or collider.is_in_group("player"):
			return true
	
	return true


# player erzekelese, ha a detection zone-ba lep
func _on_player_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and enemy != null:
		var potential_player = body
		
		# ellenorzes, hogy a jatekosra tisztan ralat-e az enemy (van-e tiszta line of sight)
		var global_direction = (potential_player.global_position - enemy.global_position).normalized()
		var local_direction = global_direction.rotated(-enemy.rotation)
		
		line_of_sight.target_position = local_direction * 5000
		line_of_sight.force_raycast_update()
		
		if line_of_sight.is_colliding():
			var collider = line_of_sight.get_collider()
			if collider == potential_player or collider.is_in_group("player"):
				player = potential_player
				set_state(State.ATTACK)


# bullet-ek es rocket-ek erzekelese, ha belepnek a detection zone-ba
func _on_bullet_detection_zone_area_entered(area: Area2D) -> void:
	if (area.is_in_group("bullet") or area.is_in_group("rocket")) and area.shooter_group == "player":
		var player_nodes = get_tree().get_nodes_in_group("player")
		if player_nodes.size() > 0:
			player = player_nodes[0]
			set_state(State.ATTACK)
