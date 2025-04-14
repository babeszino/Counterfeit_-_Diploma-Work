# ################
# Enemy karakter
# navigacios mozgas, fegyverek, animaciok es eletero kezelese
# ################
extends CharacterBody2D

signal enemy_died

# node reference-ek
@onready var nav_agent = $NavigationAgent2D
@onready var enemy_ai = $EnemyAI
@onready var enemy_movement = $EnemyMovement
@onready var enemy_animation = $AnimatedSprite2D

# effect scene-ek preload-olasa
var bleeding_effect_scene = preload("res://1_scenes/5_effects/bleed_effect.tscn")
var bloodstain_scene = preload("res://1_scenes/5_effects/bloodstain.tscn")

var hp : int = 100:
	set = set_hp

var speed : float = 75.0

# allapot valtozok
var weapon = null
var current_animation : String = "idle"
var last_velocity : Vector2 = Vector2.ZERO
var is_dying : bool = false


# inicializalas
func _ready() -> void:
	hp = 100
	
	if enemy_ai:
		enemy_ai.initialize(self, weapon)
	
	if enemy_movement:
		enemy_movement.initialize(self)
	
	enemy_animation.play("idle")
	
	enemy_animation.play("idle")
	current_animation = "idle"
	
	call_deferred("actor_setup") # call_deferred, hogy biztosan setup-olva legyen a navigation scene betoltesekor


# enemy mozgasanak es animaciojanak kezelese
func _physics_process(delta: float) -> void:
	# csak akkor navigaljon az enemy, ha ATTACK state-ben van
	if enemy_ai and enemy_ai.current_state == enemy_ai.State.ATTACK and enemy_ai.player:
		navigate_to_player(delta)
		move_and_slide()
		
		update_weapon_animation()
		update_animation()


# sebzodes feldolgozasa
func handle_hit(damage_amount: int = 50):
	if is_dying:
		return
	
	hp -= damage_amount
	spawn_bleeding_effect()
	
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0 and enemy_ai:
		enemy_ai.player = player_nodes[0]
		enemy_ai.set_state(enemy_ai.State.ATTACK)
		update_path()
	
	if hp <= 0:
		is_dying = true
		spawn_bloodstain()
		die()


# enemy halalanak feldolgozasa
func die() -> void:
	if !is_dying:
		return
	
	remove_from_group("enemy")
	emit_signal("enemy_died")
	queue_free()


# navigation setup-olasa physics inicializalasa utan
func actor_setup() -> void:
	await get_tree().physics_frame
	update_path()


# mozgas a jatekos fele navigation-t hasznalva (ATTACK state-ben)
func navigate_to_player(_delta: float) -> void:
	if enemy_ai == null or enemy_ai.player == null:
		return
	
	if nav_agent.is_navigation_finished():
		return
	
	update_path()
	
	var next_position = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)
	
	var attack_distance = 75.0
	if weapon is BaseballBat:
		attack_distance = 15.0
	
	var distance_to_player = global_position.distance_to(enemy_ai.player.global_position)
	if distance_to_player > attack_distance:
		velocity = direction * speed
		if weapon and weapon.has_method("set_owner_moving"):
			weapon.set_owner_moving(false)
	else:
		velocity = Vector2.ZERO


# navigation path (navigacios utvonal) frissitese a jatekos fele
func update_path() -> void:
	if enemy_ai and enemy_ai.player:
		nav_agent.target_position = enemy_ai.player.global_position


# enemy animaciojanak frissitese a mozgasi irany alapjan
func update_animation() -> void:
	if velocity.length() < 0.1:
		enemy_animation.play("idle")
		return
	
	var facing_direction = Vector2.RIGHT.rotated(rotation)
	var moving_direction = velocity.normalized()
	var angle = abs(facing_direction.angle_to(moving_direction))
	
	if angle < PI/4 or angle > 3*PI/4:
		enemy_animation.play("walk")
	else:
		enemy_animation.play("walk_sideways")


# fegyver animaciojanak frissitese mozgas alapjan
func update_weapon_animation() -> void:
	if weapon and weapon.has_method("set_owner_moving"):
		var is_moving = velocity.length() > 10.0
		weapon.set_owner_moving(is_moving)


# fegyver beallitasa (az elozo fegyver kicserelesevel)
func equip_weapon(weapon_scene_path_or_instance) -> void:
	if weapon:
		weapon.queue_free()
	
	var weapon_instance = null
	
	if weapon_scene_path_or_instance is Node:
		weapon_instance = weapon_scene_path_or_instance
	
	if weapon_instance:
		weapon = weapon_instance
		add_child(weapon)
	
	# ai frissitese az uj fegyver reference-el
	if enemy_ai:
		enemy_ai.initialize(self, weapon)


# bleeding effect letrehozasa, ha sebzodik az enemy
func spawn_bleeding_effect() -> void:
	var effect = bleeding_effect_scene.instantiate()
	get_tree().root.add_child(effect)
	effect.global_position = global_position
	effect.initialize(self, scale)


# bloodstain effekt letrehozasa, ha meghal az enemy
func spawn_bloodstain() -> void:
	var bloodstain = bloodstain_scene.instantiate()
	get_tree().root.add_child(bloodstain)
	bloodstain.global_position = global_position


# hp setter
func set_hp(new_hp: int):
	hp = clamp(new_hp, 0, 100)
