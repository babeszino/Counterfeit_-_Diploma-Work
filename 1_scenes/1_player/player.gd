# ################
# Player karakter
# mozgas, fegyverek, animaciok es eletero kezelese
# ################
extends CharacterBody2D

class_name Player

# node reference-ek
@onready var player_collision : CollisionShape2D = $CollisionShape2D
@onready var player_animation : AnimatedSprite2D = $AnimatedSprite2D

# effect scene-ek preload-olasa
var bleeding_effect_scene = preload("res://1_scenes/5_effects/bleed_effect.tscn")
var bloodstain_scene = preload("res://1_scenes/5_effects/bloodstain.tscn")

var hp : int = 100:
	set = set_hp

var speed : float = 200.0

# allapot valtozok
var weapon = null
var current_animation : String = "idle"
var is_dying : bool = false
var is_active : bool = false

# knockback (visszalokes) valtozok
var knockback_velocity : Vector2 = Vector2.ZERO
var knockback_fadeout : float = 0.8 # visszalokes "enyhulese" (0.8 -> 20% frame-enkent)


# inicializalas
func _ready() -> void:
	hp = 100
	player_animation.play("idle")
	current_animation = "idle"
	
	deactivate()


# player mozgasanak, forgatasanak es knockback-jenek (visszalokesenek) kezelese
func _physics_process(_delta: float) -> void:
	# input iranyok
	var direction := Vector2.ZERO
	
	if Input.is_action_pressed("up"):
		direction.y -= 1
	
	if Input.is_action_pressed("down"):
		direction.y += 1
	
	if Input.is_action_pressed("left"):
		direction.x -= 1
	
	if Input.is_action_pressed("right"):
		direction.x += 1
	
	direction = direction.normalized()
	
	# velocity szamitas knockback-el (visszalokessel)
	var movement_velocity = direction * speed
	knockback_velocity *= knockback_fadeout
	velocity = movement_velocity + knockback_velocity
	
	move_and_slide()
	
	# a player kurzor fele forgatasa
	look_at(get_global_mouse_position())
	
	# fegyver animacio valtoztatasa mozgas alapjan
	if weapon and weapon.has_method("set_owner_moving"):
		weapon.set_owner_moving(direction != Vector2.ZERO)
	
	update_animation(direction)


# knockback (visszalokes) kezelese a rocket launcher fegyvertol
func apply_knockback(knockback_direction: Vector2, force: float) -> void:
	knockback_velocity += knockback_direction * force


# lovesi bemenetek kezelese
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fire"):
		if weapon.has_method("fire_pressed"):
			weapon.fire_pressed()
		elif weapon.has_method("can_shoot") and weapon.can_shoot():
			weapon.shoot()
	
	if event.is_action_released("fire") and weapon.has_method("fire_released"):
		weapon.fire_released()


# player animaciojanak frissitese a mozgasi irany alapjan, a nezesi iranyhoz relativan
# (ha peldaul a W-t nyomjuk, de balra nezunk, akkor ne az elore setalo animacio jatszodjon le)
func update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		player_animation.play("idle")
		return
	
	var facing_direction = (get_global_mouse_position() - global_position).normalized()
	var angle = abs(facing_direction.angle_to(direction))
	
	if angle < PI/4 or angle > 3*PI/4:
		player_animation.play("walk")
	else:
		player_animation.play("walk_sideways")


# sebzodes feldolgozasa
func handle_hit(damage_amount: int = 1) -> void:
	if is_dying:
		return
	
	hp -= damage_amount
	spawn_bleeding_effect()
	
	if hp <= 0:
		is_dying = true
		
		spawn_bloodstain()
		
		var ui_manager = get_node_or_null("/root/Main/Managers/UIManager")
		if ui_manager and ui_manager.has_method("show_death_screen"):
			ui_manager.show_death_screen()
		
		get_tree().paused = true
		visible = false
		player_collision.set_deferred("disabled", true)


# fegyver beallitasa (az elozo fegyver eltavolitasaval, ha van)
func equip_weapon(weapon_scene_instance) -> void:
	if weapon:
		weapon.queue_free()
	
	var weapon_instance = null
	
	if weapon_scene_instance is Node:
		weapon_instance = weapon_scene_instance
	
	if weapon_instance:
		weapon = weapon_instance
		weapon.name = "Weapon"
		add_child(weapon)


# bleeding effect letrehozasa, ha sebzodik a player
func spawn_bleeding_effect() -> void:
	var effect = bleeding_effect_scene.instantiate()
	get_tree().root.add_child(effect)
	effect.global_position = global_position
	effect.initialize(self, scale)


# bloodstain effekt letrehozasa, ha meghal a player
func spawn_bloodstain() -> void:
	var bloodstain = bloodstain_scene.instantiate()
	get_tree().root.add_child(bloodstain)
	bloodstain.global_position = global_position


# player "aktivalasa" - spawn_position-re
func activate(spawn_position = null) -> void:
	is_active = true
	if spawn_position:
		global_position = spawn_position
	
	visible = true
	set_process(true)
	set_physics_process(true)
	player_collision.set_deferred("disabled", false)
	
	if has_node("Camera2D"):
		$Camera2D.enabled = true
	
	hp = 100
	is_dying = false


# player "deaktivalasa" - amikor nem kell a player
func deactivate() -> void:
	is_active = false
	visible = false
	set_process(false)
	set_physics_process(false)
	player_collision.set_deferred("disabled", true)
	
	if has_node("Camera2D"):
		$Camera2D.enabled = false
	
	# fegyver eltavolitasa deaktivalaskor
	if weapon:
		weapon.queue_free()
		weapon = null


# hp setter
func set_hp(new_hp: int):
	hp = clamp(new_hp, 0, 100)
