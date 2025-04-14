# ################
# verzes effekt, ami koveti a player-t/enemy-t
# akkor jatszodik le, ha sebzodik a jatekos/enemy
# ################
extends AnimatedSprite2D

# timer node - animacio hossza
@onready var duration_timer = $DurationTimer
var character_to_follow = null


# animacio es timer elinditasa amint letre van hozva
func _ready():
	play("bleed")
	duration_timer.start()


# pozicio frissitese a player/enemy kovetesehez
func _process(_delta: float) -> void:
	if character_to_follow and is_instance_valid(character_to_follow):
		global_position = character_to_follow.global_position


# kovetendo karakter beallitasa es az effekt meretezese
func initialize(follow_character, scale_value: Vector2) -> void:
	character_to_follow = follow_character
	scale = scale_value * 5


# eltavolitas ha lejar a timer
func _on_duration_timer_timeout() -> void:
	queue_free()
