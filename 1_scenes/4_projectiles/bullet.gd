# ################
# bullet projectile - egyenes iranyban halad, a bullet "tulajdonosatol" fuggoen sebzi a player-t/enemy-t
# collision-ok (utkozesek) kezelese, mozgas es sebzes kiosztasa
# ################
extends Area2D

# timer node reference
@onready var despawn_timer = $DespawnTimer

var bullet_direction := Vector2.ZERO
var bullet_shooter : Node = null
var shooter_group : String = ""

var speed : int = 650
var damage : int = 25 # default


# despawn timer elinditasa amint letre van hozva
func _ready() -> void:
	despawn_timer.start()


# bullet mozgatasa megfelelo iranyba, megfelelo gyorsasaggal
func _process(delta: float) -> void:
	if bullet_direction != Vector2.ZERO:
		var velocity = bullet_direction * speed * delta
		global_position += velocity


# bullet iranyanak beallitasa es forgatas
func set_direction(direction: Vector2) -> void:
	bullet_direction = direction
	rotation += direction.angle()
 

# bullet beallitasa az alapjan, hogy ki lotte -> damage es collision beallitasa
func set_shooter(shooter: Node) -> void:
	bullet_shooter = shooter
	
	var weapon = null
	for child in shooter.get_children():
		if child.has_method("get_damage"):
			weapon = child
			break
	
	if weapon and weapon.has_method("get_damage"):
		damage = weapon.get_damage()
	
	if shooter.is_in_group("player"):
		shooter_group = "player"
		set_collision_mask_value(2, false) # 2 - player - FALSE
		set_collision_mask_value(3, true) # 3 - walls - TRUE
		set_collision_mask_value(4, true) # 4 - enemies - TRUE
	
	elif shooter.is_in_group("enemy"):
		shooter_group = "enemy"
		set_collision_mask_value(2, true) # 2 - player - TRUE
		set_collision_mask_value(3, true) # 3 - walls - TRUE
		set_collision_mask_value(4, false) # 4 - enemy - FALSE


# ha lejar a despawn timer, akkor bullet despawn-olasa (torlese)
func _on_despawn_timer_timeout() -> void:
	queue_free()


# collision-ok (utkozesek) kezelese
func _on_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		queue_free()
		return
	
	if body == bullet_shooter:
		return
	
	if body.has_method("handle_hit"):
		body.handle_hit(damage)
		queue_free()
