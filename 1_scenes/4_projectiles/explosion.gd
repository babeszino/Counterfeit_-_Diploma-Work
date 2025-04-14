# ################
# explosion (robbanas) effekt kezelese, damage kiosztasa
# ################
extends Area2D

# node reference-ek
@onready var animation = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var damage_timer = $DamageTimer

var shooter_group : String = "player" # self-damage megakadalyozasara
var damaged_targets = [] # egy enemy csak egyszer sebzodjon egy explosion-tol
var damage : int = 70


# explosion letrehozasa inicializalaskor
func _ready() -> void:
	animation.play("explosion")
	damage_timer.start()
	damage_targets_in_area()


# target-ek keresese, ha lejar a timer (vege az explosion-nek)
func _on_damage_timer_timeout() -> void:
	damage_targets_in_area()


# enemy-k sebzese az explosion teruleten belul
func damage_targets_in_area() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var explosion_radius
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if collision_shape:
			explosion_radius = collision_shape.shape.radius
		
		if distance <= explosion_radius and not enemy in damaged_targets:
			if enemy.has_method("handle_hit"):
				enemy.handle_hit()
				damaged_targets.append(enemy)
	
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body in damaged_targets:
			continue
		
		if shooter_group == "player" and body.is_in_group("player"):
			continue
		
		if body.has_method("handle_hit"):
			body.handle_hit()
			damaged_targets.append(body)


# explosion animacio torlese, ha vege az animacionak
func _on_animation_finished() -> void:
	queue_free()


# uj body-k kezelese, amik az explosion area-ban vannak (elso ellenorzes utan)
# igy egy rocket-tel kozvetlenul eltalalt enemy kozvetlen sebzest es teruleti sebzest is kap
func _on_body_entered(body: Node2D) -> void:
	if body in damaged_targets:
		return
	
	if shooter_group == "player" and body.is_in_group("player"):
		return
	
	if body.has_method("handle_hit"):
		body.handle_hit(damage)
		damaged_targets.append(body)
