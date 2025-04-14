# ################
# score system - kezeli a player pontszamat es figyeli a killstreak-et
# pontszam szamolas, szorzok es killstreak bonuszok kezelese
# ################
extends Node

# signalok
signal score_changed(new_score)
signal killstreak_updated(streak_type)

# node reference a game manager script-hez
@onready var game_manager = $"../GameManager"

# killstreak tipusok
enum KillstreakType {
	NONE,
	SINGLE_KILL,
	DOUBLE_KILL,
	TRIPLE_KILL,
	MULTI_KILL
}

# jelenlegi score es killstreak valtozok
var score : int = 0
var current_killstreak : int = 0

# killstreak timer-ek
var double_kill_timer : Timer
var triple_kill_timer : Timer 
var multi_kill_timer : Timer


# timer-ek inicializalasa es csatlakoztatasa a game manager-hez
func _ready() -> void:
	double_kill_timer = Timer.new()
	double_kill_timer.name = "DoubleKillTimer"
	double_kill_timer.wait_time = 3.0
	double_kill_timer.one_shot = true
	double_kill_timer.timeout.connect(_on_double_kill_timer_timeout)
	add_child(double_kill_timer)
	
	triple_kill_timer = Timer.new()
	triple_kill_timer.name = "TripleKillTimer"
	triple_kill_timer.wait_time = 2.0
	triple_kill_timer.one_shot = true
	triple_kill_timer.timeout.connect(_on_triple_kill_timer_timeout)
	add_child(triple_kill_timer)
	
	multi_kill_timer = Timer.new()
	multi_kill_timer.name = "MultiKillTimer"
	multi_kill_timer.wait_time = 1.5
	multi_kill_timer.one_shot = true
	multi_kill_timer.timeout.connect(_on_multi_kill_timer_timeout)
	add_child(multi_kill_timer)
	
	await get_tree().process_frame
	
	# enemy_killed signal osszekotese a game manager-rel
	if game_manager:
		if !game_manager.is_connected("enemy_killed", Callable(self, "register_kill")):
			game_manager.connect("enemy_killed", Callable(self, "register_kill"))


# egy kill (oles) feldolgozasa - pontszam es killstreak frissitese
func register_kill() -> void:
	add_score(100)
	
	current_killstreak += 1
	
	if current_killstreak == 1:
		double_kill_timer.start()
		emit_signal("killstreak_updated", KillstreakType.SINGLE_KILL)
	
	elif current_killstreak == 2:
		double_kill_timer.stop()
		triple_kill_timer.start()
		emit_signal("killstreak_updated", KillstreakType.DOUBLE_KILL)
	
	elif current_killstreak == 3:
		triple_kill_timer.stop()
		multi_kill_timer.start()
		emit_signal("killstreak_updated", KillstreakType.TRIPLE_KILL)
	
	elif current_killstreak >= 4:
		emit_signal("killstreak_updated", KillstreakType.MULTI_KILL)
		multi_kill_timer.stop()
		multi_kill_timer.start()


# megszerzett pontok hozzaadasa a pontszamhoz
func add_score(points: int) -> void:
	score += points
	emit_signal("score_changed", score)


# killstreak visszaallitasa ha a player nem szerez masodik kill-t (olest) idoben
func _on_double_kill_timer_timeout() -> void:
	if current_killstreak == 1:
		current_killstreak = 0
		emit_signal("killstreak_updated", KillstreakType.NONE)


# dupla kill bonusz hozzaadasa es killstreak visszaallitasa, 
# ha a player nem szerez harmadik kill-t idoben
func _on_triple_kill_timer_timeout() -> void:
	if current_killstreak == 2:
		add_score(25)
		current_killstreak = 0
		emit_signal("killstreak_updated", KillstreakType.NONE)


# tripla/multi kill bonusz hozzaadasa es killstreak visszaallitasa, 
# ha lejar a timer
func _on_multi_kill_timer_timeout() -> void:
	if current_killstreak >= 3:
		if current_killstreak == 3:
			add_score(50)
		
		elif current_killstreak >= 4:
			add_score(100)
		
		current_killstreak = 0
		emit_signal("killstreak_updated", KillstreakType.NONE)


# pontszam es killstreak visszaallitasa (nullazasa
func reset_score() -> void:
	score = 0
	current_killstreak = 0
	
	double_kill_timer.stop()
	triple_kill_timer.stop()
	multi_kill_timer.stop()
	
	emit_signal("score_changed", score)
	emit_signal("killstreak_updated", KillstreakType.NONE)


# szorzo a palya befejezesekor a teljesitesi ido alapjan
func apply_multiplier(multiplier: float) -> void:
	score = int(score * multiplier)
	emit_signal("score_changed", score)
