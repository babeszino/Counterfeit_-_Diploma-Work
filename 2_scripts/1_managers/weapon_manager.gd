# ################
# Weapon manager - fegyverek letrehozasanak es kiosztasanak kezelese
# fegyver instance-ek kezelese a palyakon valo haladas alapjan
# ################
extends Node

# node reference a weapon container node-ra
@onready var weapons_container = $"../../WeaponsContainer"

# palya indexelessel egyezo indexeles a fegyvereknek
var weapon_map = {
	0: "BaseballBat",
	1: "Glock18",
	2: "DoubleBarrel",
	3: "M4",
	4: "RocketLauncher"
}

# fegyver scene fajlok eleresi utjai
const WEAPON_PATHS = {
	"BaseballBat": "res://1_scenes/2_weapons/baseball_bat.tscn",
	"Glock18": "res://1_scenes/2_weapons/glock18.tscn",
	"DoubleBarrel": "res://1_scenes/2_weapons/double_barrel_shotgun.tscn",
	"M4": "res://1_scenes/2_weapons/m4.tscn",
	"RocketLauncher": "res://1_scenes/2_weapons/rocket_launcher.tscn"
}


# fegyver node elerese a weapons container node-bol nev alapjan
func get_weapon(weapon_name: String) -> Node:
	return weapons_container.get_node_or_null(weapon_name)


# fegyver instance leterehozasa nev alapjan
func get_weapon_instance(weapon_type: String) -> Node:
	if WEAPON_PATHS.has(weapon_type):
		var weapon_scene = load(WEAPON_PATHS[weapon_type])
		if weapon_scene:
			return weapon_scene.instantiate()
	
	return null


# helyes fegyver kivalasztasa az aktualis palya szerint
func get_weapon_for_level(level_index: int) -> Node:
	if level_index == 4:  # rocket launcher time!
		return get_weapon_instance("RocketLauncher")
	
	# fegyver elerese a palya index segitsegevel a weapon_map-bol
	if weapon_map.has(level_index):
		return get_weapon_instance(weapon_map[level_index])
	
	# hiba eseten fallback - baseball bat fegyverre
	return get_weapon_instance("BaseballBat")
