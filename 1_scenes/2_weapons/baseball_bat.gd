# ################
# baseball bat kozelharci fegyver
# ################
extends Node2D

class_name BaseballBat

# node reference-ek
@onready var attack_cooldown = $AttackCooldown
@onready var player_animation = $PlayerAnimation
@onready var enemy_animation = $EnemyAnimation
@onready var attack_area = $AttackArea
@onready var damage_zone = $AttackArea/DamageZone
@onready var attack_duration = $AttackDuration

# fegyver balance valtozok
var player_damage : int = 100
var enemy_damage : int = 10
var player_cooldown : float = 0.33
var enemy_cooldown : float = 1

# fegyver allapot valtozok
var is_attacking : bool = false
var owner_moving : bool = false
var current_animation : String = "idle"
var active_animation = null
var is_enemy : bool = false
var hit_targets = []


# fegyver inicializalasa
func _ready() -> void:
	setup_weapon_owner()
	
	if active_animation:
		active_animation.play("idle")
		current_animation = "idle"
	
	# hit detection kikapcsolasa az elejen
	damage_zone.disabled = true
	attack_area.monitoring = false


# feyver beallitasa az owner alapjan (player vagy enemy)
func setup_weapon_owner() -> void:
	var parent = get_parent()
	
	if parent and parent.is_in_group("player"):
		player_animation.visible = true
		enemy_animation.visible = false
		active_animation = player_animation
		is_enemy = false
		attack_area.collision_mask = 4 # 4 - enemies
		attack_cooldown.wait_time = player_cooldown
		
	elif parent and parent.is_in_group("enemy"):
		player_animation.visible = false
		enemy_animation.visible = true
		active_animation = enemy_animation
		is_enemy = true
		attack_area.collision_mask = 2 # 2 - player
		attack_cooldown.wait_time = enemy_cooldown


# hit detection feldolgozasa tamadas kozben
func _physics_process(_delta: float) -> void:
	if is_attacking:
		var overlapping_bodies = attack_area.get_overlapping_bodies()
		for body in overlapping_bodies:
			if not body in hit_targets:
				_handle_hit(body)


# tamadas, ha nincs/letelt a cooldown
# visszateresi ertek -> sikeres volt-e a tamadas
func attack() -> bool:
	if !attack_cooldown.is_stopped():
		return false
	
	is_attacking = true
	
	# urites uj tamadas hit track-elesere
	hit_targets.clear()
	
	# hit detection bekapcsolasa tamadaskor
	damage_zone.disabled = false
	attack_area.monitoring = true
	
	if active_animation and current_animation != "attack":
		active_animation.play("attack")
		current_animation = "attack"
	
	attack_cooldown.start()
	attack_duration.start()
	return true


# timer a tamadas vegenek meghatarozasahoz
func _on_attack_duration_timeout() -> void:
	end_attack_state()


# animacio vege signal - player es enemy animacionak
func _on_animation_finished() -> void:
	if current_animation == "attack":
		end_attack_state()


# reset/clean up egy tamadas vegen
func end_attack_state() -> void:
	if is_attacking:
		is_attacking = false
		damage_zone.disabled = true
		attack_area.monitoring = false
		hit_targets.clear()
		update_animation_state()


# lehet-e tamadni a fegyverrel
func can_attack() -> bool:
	return attack_cooldown.is_stopped()


# ammo display text baseball bat-nel
func get_ammo_display() -> String:
	return "MELEE"


# player es enemy animacio mozgasi allapotanak frissitese
func set_owner_moving(moving: bool) -> void:
	owner_moving = moving
	update_animation_state()


# helyes animacio beallitasa a fegyver allapota alapjan - idle, attack, walk animaciok
func update_animation_state() -> void:
	if not active_animation:
		return
	
	if is_attacking:
		if current_animation != "attack":
			active_animation.play("attack")
			current_animation = "attack"
	
	elif owner_moving:
		if current_animation != "walk":
			active_animation.play("walk")
			current_animation = "walk"
	
	else:
		if current_animation != "idle":
			active_animation.play("idle")
			current_animation = "idle"


# konzisztencia - mas fegyverek miatt
func fire_pressed() -> void:
	attack()


# konzisztencia - mas fegyverek miatt
func fire_released() -> void:
	pass


# konzisztencia - mas fegyverek miatt
func reload() -> void:
	pass


# ha valamilyen body az attack area-ba kerul
func _on_attack_area_body_entered(body: Node2D) -> void:
	if is_attacking and not body in hit_targets:
		_handle_hit(body)


# hit process, ha valid a target
func _handle_hit(body: Node2D) -> void:
	if !is_attacking:
		return
		
	if body == get_parent():
		return
	
	hit_targets.append(body)
	
	if is_enemy and body.is_in_group("player"):
		if body.has_method("handle_hit"):
			body.handle_hit(enemy_damage)
	elif !is_enemy and body.is_in_group("enemy"):
		if body.has_method("handle_hit"):
			body.handle_hit(player_damage)


# konzisztencia - mas fegyverek miatt
func shoot(_target_direction: Vector2 = Vector2.ZERO) -> bool:
	return attack()


# cleanup, ha a fegyver torlodik
func cleanup() -> void:
	if attack_cooldown and attack_cooldown.is_inside_tree():
		attack_cooldown.stop()
	
	if attack_duration and attack_duration.is_inside_tree():
		attack_duration.stop()
	
	is_attacking = false
	owner_moving = false
	hit_targets.clear()
	
	if damage_zone:
		damage_zone.disabled = true
	if attack_area:
		attack_area.monitoring = false
	
	if active_animation and active_animation.is_inside_tree():
		active_animation.stop()
