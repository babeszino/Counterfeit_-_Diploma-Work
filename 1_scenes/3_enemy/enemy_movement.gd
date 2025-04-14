# ################
# enemy PATROL state - enemy vertikalis jarorozesenek kezelese
# az enemy ebben az allapotban van, amig nem valt ATTACk state-be (engage-el a player-el)
# ################
extends Node2D

# enemy (parent) node reference
var enemy : CharacterBody2D = null

# patrol pozicio valtozok
var default_position : Vector2 = Vector2.ZERO
var patrol_top_point : Vector2 = Vector2.ZERO
var patrol_bottom_point : Vector2 = Vector2.ZERO

# patrol konfiguracios valtozok
var patrol_distance : float = 100.0
var patrol_speed : float = 30.0

# patrol allapot valtozok
var moving_to_bottom : bool = true
var should_patrol : bool = false
var patrol_timer : float = 0.0


# default ertekek inicializalasa
func _ready() -> void:
	patrol_timer = 0.5
	should_patrol = false


# patrol timer kezelese es a patrol point-ok beallitasa
func _physics_process(delta: float) -> void:
	if patrol_timer > 0:
		patrol_timer -= delta
		
		# patrol point-ok beallitasa
		if enemy != null and !should_patrol:
			setup_patrol_points()
		
		# patrol kezdese ha lejar a timer
		if patrol_timer <= 0:
			should_patrol = true
			
			if enemy != null:
				setup_patrol_points()

# patrol point-ok beallitasa az enemy jelenlegi pozicioja alapjan (EnemySpawn Marker2D node alapjan lenyegeben)
func setup_patrol_points() -> void:
	default_position = enemy.global_position
	patrol_top_point = default_position - Vector2(0, patrol_distance/2)
	patrol_bottom_point = default_position + Vector2(0, patrol_distance/2)


# enemy reference inicializalasa es a patrol state ujraalitasa
func initialize(enemy_node) -> void:
	self.enemy = enemy_node
	should_patrol = false
	patrol_timer = 0.5
	
	if enemy != null:
		setup_patrol_points()
		enemy.velocity = Vector2.ZERO


# patrol state movement pattern megvalositasa
func patrol() -> void:
	if enemy == null or !should_patrol:
		return
		
	var target : Vector2 = Vector2.ZERO
	if moving_to_bottom:
		target = patrol_bottom_point
	else:
		target = patrol_top_point
	
	# iranyvaltoztatas, ha eleg kozel van az enemy a target-hez
	var distance_to_target = enemy.global_position.distance_to(target)
	if distance_to_target < 20.0:
		moving_to_bottom = !moving_to_bottom
	
	var direction = Vector2.ZERO
	if moving_to_bottom:
		direction = Vector2(0, 1) # felfele
	else:
		direction = Vector2(0, -1) # lefele
	
	# enemy megfelelo iranyba forgatasa
	if direction != Vector2.ZERO:
		var target_angle = direction.angle() + PI*2
		enemy.rotation = lerp_angle(enemy.rotation, target_angle, 0.1)
	
	# velocity megadasa es a fegyver allapot frissitese
	enemy.velocity = direction * patrol_speed
	var weapon = enemy.get_node_or_null("Weapon")
	if weapon and weapon.has_method("set_player_moving"):
		weapon.set_player_moving(direction != Vector2.ZERO)
	
	enemy.move_and_slide()
	enemy.update_animation()
