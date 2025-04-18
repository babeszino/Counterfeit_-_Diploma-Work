# ################
# glock18 felautomata pisztoly
# ################
extends Node2D

class_name Glock18

signal reload_started

# node reference-ek
@onready var player_animation = $PlayerAnimation
@onready var enemy_animation = $EnemyAnimation
@onready var end_of_gun = $EndOfGun
@onready var attack_cooldown = $AttackCooldown
@onready var reload_timer = $ReloadTimer

# fegyver balance valtozok
var player_damage : int = 50
var enemy_damage : int = 6
var player_cooldown : float = 0.1
var enemy_cooldown : float = 0.7

# fegyver property-k
var bullet_scene
var max_ammo : int = 18
var current_ammo : int = 18
var is_reloading : bool = false
var auto_fire : bool = false

# animacio allapot valtozok
var current_animation : String = "idle"
var is_shooting : bool = false
var owner_moving : bool = false
var active_animation = null


# fegyver inicializalasa
func _ready() -> void:
	current_ammo = max_ammo
	bullet_scene = load("res://1_scenes/4_projectiles/bullet.tscn")
	
	setup_weapon_owner()
	
	if active_animation:
		active_animation.play("idle")
		current_animation = "idle"


# feyver beallitasa az owner alapjan (player vagy enemy)
func setup_weapon_owner() -> void:
	var parent = get_parent()
	
	# ha a parent a player
	if parent and parent.is_in_group("player"):
		player_animation.visible = true
		enemy_animation.visible = false
		active_animation = player_animation
		attack_cooldown.wait_time = player_cooldown
	
	# ha a parent egy enemy
	elif parent and parent.is_in_group("enemy"):
		player_animation.visible = false
		enemy_animation.visible = true
		active_animation = enemy_animation
		attack_cooldown.wait_time = enemy_cooldown


# loves es toltes allapotok feldolgozasa
func _process(_delta: float) -> void:
	if current_ammo <= 0 and !is_reloading:
		reload()
	
	if Input.is_action_just_pressed("reload") and !is_reloading and current_ammo < max_ammo:
		reload()
	
	if is_shooting and attack_cooldown.is_stopped():
		is_shooting = false
		update_animation_state()


# loves, ha a feltetelek engedik
# target_direction parameter az enemy ai lovesi iranyahoz (ha meg van adva)
# ha ZERO marad a target_direction parameter, akkor a kurzor pozicioja lesz a player lovesi iranya
# visszateresi ertek -> sikeres volt-e a loves
func shoot(target_direction: Vector2 = Vector2.ZERO) -> bool:
	if current_ammo <= 0:
		reload()
		return false
	
	if is_reloading:
		return false
	
	if !attack_cooldown.is_stopped():
		return false
	
	# lovesi irany kiszamitasa a player szamara
	if target_direction == Vector2.ZERO:
		var mouse_direction = (get_global_mouse_position() - global_position).normalized()
		var gun_forward = Vector2.RIGHT.rotated(global_rotation)
		var angle_diff = abs(gun_forward.angle_to(mouse_direction))
		
		if angle_diff > PI/2:
			target_direction = gun_forward
		
		else:
			target_direction = mouse_direction
	
	var projectile_manager = get_tree().root.get_node_or_null("Main/Managers/ProjectileManager")
	if projectile_manager:
		projectile_manager.spawn_bullet(end_of_gun.global_position, target_direction, get_parent())
	
	current_ammo -= 1
	attack_cooldown.start()
	is_shooting = true
	
	if active_animation and current_animation != "shoot":
		active_animation.play("shoot")
		current_animation = "shoot"
	
	if current_ammo <= 0:
		reload()
	
	return true


# fegyver ujratoltes
func reload() -> void:
	if !is_reloading and current_ammo < max_ammo:
		is_reloading = true
		reload_timer.start()
		emit_signal("reload_started", reload_timer.wait_time)


# tud-e loni a fegyver
func can_shoot() -> bool:
	return attack_cooldown.is_stopped() and current_ammo > 0 and !is_reloading


# timer az ujratoltes vegenek meghatarozasahoz
func _on_reload_timer_timeout() -> void:
	current_ammo = max_ammo
	is_reloading = false


# ammo display text
func get_ammo_display() -> String:
	return str(current_ammo) + " / " + str(max_ammo)


# player es enemy animacio mozgasi allapotanak frissitese
func set_owner_moving(moving: bool) -> void:
	owner_moving = moving
	update_animation_state()


# helyes animacio beallitasa a fegyver allapota alapjan - idle, shoot, walk animaciok
func update_animation_state() -> void:
	if not active_animation:
		return
	
	if is_shooting:
		if current_animation != "shoot":
			active_animation.play("shoot")
			current_animation = "shoot"
	
	elif owner_moving:
		if current_animation != "walk":
			active_animation.play("walk")
			current_animation = "walk"
	
	else:
		if current_animation != "idle":
			if current_animation != "idle":
				active_animation.play("idle")
				current_animation = "idle"


# "fire" gomb megnyomasanak kezelese (loves)
func fire_pressed() -> void:
	shoot()


# konzisztencia - mas fegyverek miatt
func fire_released() -> void:
	pass


# helyes damage ertekek visszaadasa owner alapjan (player vagy enemy)
func get_damage() -> int:
	var parent = get_parent()
	if parent and parent.is_in_group("player"):
		return player_damage
	
	elif parent and parent.is_in_group("enemy"):
		return enemy_damage
	
	else:
		return player_damage #default
