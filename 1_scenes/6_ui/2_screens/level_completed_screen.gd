# ################
# level completion screen - palyak befejezesekor megjeleno kepernyo
# continue button lehetove teszi a tovabbhaladast a kovetkezo palyara
# megjeleniti a palya teljesitesi idejet, az idovel elert pontszam szorzot es az aktualis pontszamot
# ################
extends CanvasLayer

signal continue_pressed

# node reference-ek
@onready var completion_time_label = $Panel/VBoxContainer/CompletionTime
@onready var multiplier_label = $Panel/VBoxContainer/Multiplier
@onready var score_label = $Panel/VBoxContainer/Score
@onready var continue_button = $Panel/VBoxContainer/ContinueButton

# szorzo a palya teljesitesi ideje szerint
var multiplier : float = 1.0 # default


# focus a continue button-re
func _ready():
	continue_button.grab_focus()


# a gomb feliratanak valtoztatasa focus allapot alapjan
func _process(_delta: float) -> void:
	if continue_button.has_focus():
		continue_button.text = ">Continue to next level<"


# level completed screen beallitasa a statisztikaval
func setup(completion_time: float, multiplier_value: float, multiplied_score: int):
	multiplier = multiplier_value
	completion_time_label.text = "Time: " + format_time(completion_time)
	multiplier_label.text = "Speed Multiplier: x" + str(multiplier)
	score_label.text = "Score: " + str(multiplied_score)


# MM:SS formatum masodpercekbol
func format_time(seconds: float) -> String:
	var minutes = int(seconds) / 60
	var remaining_seconds = int(seconds) % 60
	return str(minutes) + ":" + str(remaining_seconds).pad_zeros(2)


# folytatas gomb megnyomasa -> continue_pressed signal
func _on_continue_button_pressed():
	emit_signal("continue_pressed", multiplier)
	queue_free()
