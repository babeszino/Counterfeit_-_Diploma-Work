# ################
# score display script - pontszam es killstreak megjelenitese
# kezeli az animaciokat es a lathatosagot
# ################
extends MarginContainer

# node reference-ek
@onready var score_display = $VBoxContainer/ScoreDisplay
@onready var killstreak_display = $VBoxContainer/KillstreakDisplay

var killstreak_timer: Timer


# timer inicializalasa, signal-ok osszekapcsolasa
func _ready():
	killstreak_timer = Timer.new()
	killstreak_timer.wait_time = 2.0
	killstreak_timer.one_shot = true
	killstreak_timer.timeout.connect(_on_killstreak_timer_timeout)
	add_child(killstreak_timer)
	
	killstreak_display.visible = false
	
	var score_system = get_node_or_null("/root/Main/Managers/ScoreSystem")
	if score_system:
		score_system.connect("score_changed", Callable(self, "update_score"))
		score_system.connect("killstreak_updated", Callable(self, "update_killstreak"))


# pontszam frissitese
func update_score(new_score: int) -> void:
	score_display.text = str(new_score)


# megfelelo killstreak felirat megjelenitese es timer-jenek elinditasa
func update_killstreak(streak_type: int) -> void:
	match streak_type:
		0:
			killstreak_display.visible = false
			killstreak_timer.stop()
		1:
			killstreak_display.text = "Single kill!"
			killstreak_display.visible = true
			killstreak_timer.start()
		2:
			killstreak_display.text = "Double Kill!"
			killstreak_display.visible = true
			killstreak_timer.start()
		3:
			killstreak_display.text = "Triple Kill!"
			killstreak_display.visible = true
			killstreak_timer.start()
		4:
			killstreak_display.text = "MULTI KILL!"
			killstreak_display.visible = true
			killstreak_timer.start()
	
	# killstreak animacio
	var tween = create_tween()
	tween.tween_property(killstreak_display, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(killstreak_display, "scale", Vector2(1.0, 1.0), 0.1)


# killstreak eltuntetese, ha lejar a killstreak timer
func _on_killstreak_timer_timeout() -> void:
	killstreak_display.visible = false
