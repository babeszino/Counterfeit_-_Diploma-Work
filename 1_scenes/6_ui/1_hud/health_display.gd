# ################
# health bar (eletero jelzo) kezelo, a player eleterejet jelzi
# kulonbozo health bar texturat jelenit a player eleterejetol fuggoen (5, 4, 3, 2, 1 bar)
# ################
extends Control

# node reference-ek (health bar texturak)
@onready var health_bar1 : TextureRect = $HealthBar1
@onready var health_bar2 : TextureRect = $HealthBar2
@onready var health_bar3 : TextureRect = $HealthBar3
@onready var health_bar4 : TextureRect = $HealthBar4
@onready var health_bar5 : TextureRect = $HealthBar5


# health bar frissitese a player eletereje alapjan
func update_health_bar(health: int) -> void:
	hide_all_health_bars()
	
	if health <= 0:
		return
	elif health <= 20:
		health_bar1.show()
	elif health <= 40:
		health_bar2.show()
	elif health <= 60:
		health_bar3.show()
	elif health <= 80:
		health_bar4.show()
	else:
		health_bar5.show()


# health bar texturak eltuntetese
func hide_all_health_bars() -> void:
	health_bar1.hide()
	health_bar2.hide()
	health_bar3.hide()
	health_bar4.hide()
	health_bar5.hide()
