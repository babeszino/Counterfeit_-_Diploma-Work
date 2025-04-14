# ################
# rocket launcher - raketaveto fegyver, melynek raketai utkozes soran felrobbannak
# a jatekos visszalokest kap a loves iranyaval ellentetes iranyba
# teruleti sebzes: 70, ellenfel kozvetlen eltalalasakor +50 (70 + 50 osszesen)
# ################
extends Node2D

class_name RocketLauncher

signal reload_started

# node reference-ek
@onready var end_of_gun = $EndOfGun
@onready var attack_cooldown = $AttackCooldown
@onready var reload_timer = $ReloadTimer
@onready var player_animation = $PlayerAnimation

# fegyver balance valtozok (csak player-nek lehet rocket launcher-e)
var player_damage : int = 50
var player_explosive_damage : int = 70

# visszalokes ereje
var knockback_force : float = 400

# fegyver property-k
var rocket_scene
var max_ammo : int = 2
var current_ammo : int = 2
var is_reloading : bool = false
var weapon_name : String = "Rocket Launcher"
var auto_fire : bool = false

# animacio allapot valtozok
var current_animation : String = "idle"
var is_shooting : bool = false
var owner_moving : bool = false


# fegyver inicializalasa
func _ready() -> void:
	current_ammo = max_ammo
	rocket_scene = load("res://1_scenes/4_projectiles/rocket.tscn")
	
	player_animation.play("idle")
	current_animation = "idle"


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
# target_direction-t rocket launcher eseteben nem kap a fuggveny parameterkent -> ZERO
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
	
	var firing_direction = target_direction
	if firing_direction == Vector2.ZERO:
		firing_direction = (get_global_mouse_position() - global_position).normalized()
	
	var projectile_manager = get_tree().root.get_node_or_null("Main/Managers/ProjectileManager")
	if projectile_manager:
		projectile_manager.spawn_rocket(end_of_gun.global_position, firing_direction, get_parent())
	
	# player visszalokese
	var parent = get_parent()
	if parent and parent.is_in_group("player"):
		if parent.has_method("apply_knockback"):
			parent.apply_knockback(-firing_direction, knockback_force)
	
	current_ammo -= 1
	
	attack_cooldown.start()
	
	is_shooting = true
	if current_animation != "shoot":
		player_animation.play("shoot")
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
	update_animation_state()


# ammo display text
func get_ammo_display() -> String:
	return str(current_ammo) + " / " + str(max_ammo)


# player animacio mozgasi allapotanak frissitese
func set_owner_moving(moving: bool) -> void:
	owner_moving = moving
	update_animation_state()


# helyes animacio beallitasa a fegyver allapota alapjan - idle, shoot, walk animaciok
func update_animation_state() -> void:
	if is_shooting:
		if current_animation != "shoot":
			player_animation.play("shoot")
			current_animation = "shoot"
	
	elif owner_moving:
		if current_animation != "walk":
			player_animation.play("walk")
			current_animation = "walk"
	
	else:
		if current_animation != "idle":
			player_animation.play("idle")
			current_animation = "idle"


# "fire" gomb megnyomasanak kezelese (loves) - automata loves "elinditasa"
func fire_pressed() -> void:
	shoot()


# konzisztencia - mas fegyverek miatt
func fire_released() -> void:
	pass


# kozvetlen talalati sebzes visszaadasa
func get_damage() -> int:
	return player_damage


# teruleti sebzes visszaadasa
func get_explosive_damage() -> int:
	return player_explosive_damage
