# ################
# projectile manager script
# bullet es rocket projectile-ok letrehozasa es kezelese
# bullet-ek, rocket-ek es explosion-ok spawnolasa
# ################
extends Node

# node reference-ek
@onready var projectile_container = $"../../ProjectileContainer"
@onready var game_manager = $"../GameManager"

# bullet, rocket es explosion scene-ek preload-olasa
var bullet_scene = preload("res://1_scenes/4_projectiles/bullet.tscn")
var rocket_scene = preload("res://1_scenes/4_projectiles/rocket.tscn")
var explosion_scene = preload("res://1_scenes/4_projectiles/explosion.tscn")


# bullet projectile letrehozasa a meghatarozott pozicioban, meghatarozott iranyba
func spawn_bullet(spawn_position: Vector2, direction: Vector2, shooter: Node) -> Node:
	var bullet = bullet_scene.instantiate()
	projectile_container.add_child(bullet)
	bullet.global_position = spawn_position
	bullet.set_direction(direction)
	bullet.set_shooter(shooter)
	return bullet


# rocket projectile letrehozasa a meghatarozott pozicioban, meghatarozott iranyba
func spawn_rocket(spawn_position: Vector2, direction: Vector2, shooter: Node) -> Node:
	var rocket = rocket_scene.instantiate()
	projectile_container.add_child(rocket)
	rocket.global_position = spawn_position
	rocket.set_direction(direction)
	rocket.set_shooter(shooter)
	return rocket


# explosion letrehozasa a meghatarozott pozicioban
func spawn_explosion(position: Vector2, shooter_group: String = "player", damage: int = 70) -> Node:
	var explosion = explosion_scene.instantiate()
	projectile_container.add_child(explosion)
	explosion.global_position = position
	explosion.shooter_group = shooter_group
	explosion.damage = damage
	return explosion


# minden jelen levo projectile eltuntetese a scene-bol
func clear_projectiles():
	for child in projectile_container.get_children():
		child.queue_free()
