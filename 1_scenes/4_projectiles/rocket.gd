# ################
# rocket projectile - egyenes iranyban halad, collision-kor (utkozeskor), illetve a timer lejarasakor felrobban
# robbanas effektet hoz letre - kozvetlen es teruleti sebzese is van
# ################
extends Area2D

# node reference-ek
@onready var despawn_timer = $DespawnTimer
@onready var animation = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

var bullet_direction := Vector2.ZERO
var bullet_shooter : Node = null
var shooter_group : String = "player"
var explosion_scene = preload("res://1_scenes/4_projectiles/explosion.tscn")
var exploded : bool = false # tobb robbanas elkerulesehez

var speed : int = 450
var damage : int = 50 # kozvetlen talalati sebzes
var explosive_damage : int = 70 # teruleti sebzes


# animacio es timer elinditasas
func _ready() -> void:
	despawn_timer.start()
	if animation:
		animation.play("flying")


# rocket mozgatasa megfelelo iranyba, megfelelo gyorsasaggal
func _process(delta: float) -> void:
	if bullet_direction != Vector2.ZERO:
		var velocity = bullet_direction * speed * delta
		global_position += velocity


# rocket iranyanak beallitasa es forgatas
func set_direction(direction: Vector2) -> void:
	bullet_direction = direction
	rotation += direction.angle()
 

# rocket beallitasa az alapjan, hogy ki lotte -> csak player lehet -> self-damage megakadalyozasa
func set_shooter(shooter: Node) -> void:
	bullet_shooter = shooter
	shooter_group = "player"


# ha lejar a despawn timer, rocket robbanas
func _on_despawn_timer_timeout() -> void:
	explode()


# collision-ok (utkozesek) kezelese
func _on_body_entered(body: Node2D) -> void:
	if body == bullet_shooter:
		return
	
	if body.has_method("handle_hit") and body != bullet_shooter:
		body.handle_hit(damage)
	
	call_deferred("explode") # physics error elkerulese


# robbanas effekt letrehozasa es rocket torlese
func explode() -> void:
	if exploded:
		return
	exploded = true
	
	var projectile_manager = get_tree().root.get_node_or_null("Main/Managers/ProjectileManager")
	if projectile_manager:
		projectile_manager.spawn_explosion(global_position, shooter_group, explosive_damage)
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	queue_free()
