# ################
# jatekos jelenlegi ammo-janak, illetve az ujratoltes progress bar-nak a frissitese
# ################
extends Label

# node reference a progress bar-ra
@onready var reload_progress : ProgressBar = $ReloadProgress

# reload progress bar-hoz
var reload_tween : Tween


# ammo display text frissites
func update_ammo(ammo_text: String) -> void:
	text = ammo_text


# reload progress bar animacio elinditasa
func start_reload_progress(duration: float) -> void:
	if reload_tween and reload_tween.is_valid():
		reload_tween.kill()
	
	reload_progress.value = 0
	reload_progress.visible = true
	
	reload_tween = create_tween()
	reload_tween.tween_property(reload_progress, "value", 100, duration)
	reload_tween.tween_callback(Callable(self, "_on_reload_complete"))


# ha veget er a reload progress bar animation
func _on_reload_complete() -> void:
	reload_progress.visible = false
