# ################
# verfolt effekt, ami akkor es ott jelenik meg, ahol meghal a player vagy egy enemy
# one-shot animacio, utolso frame ott marad
# ################
extends AnimatedSprite2D


# animacio elinditasa amint letre van hozva
func _ready() -> void:
	play("bloodstain")


# animacio megallitasaha, ha lejar a timer
func _on_duration_timer_timeout() -> void:
	stop()
