extends Node

onready var LSTAPI: Node = get_node_or_null("/root/LSTAPI")
onready var pd: Node = get_node("/root/PlayerData")
onready var hour_label: Label = get_node("clock/clock_container/hour")
onready var minute_label: Label = get_node("clock/clock_container/min")
onready var ampm_label: Label = get_node("clock/clock_container/ampm")
var time: Dictionary

func _ready():
	if LSTAPI != null:
		time = LSTAPI.check_time()
		LSTAPI.connect("minute_has_passed", self, "_set_minute_label")
		LSTAPI.connect("hour_has_passed", self, "_set_hour_label")
		LSTAPI.connect("time_has_jumped", self, "_resync")
		_startup()
	pd.connect("_hide_hud_toggle", self, "_toggle_clock")

func _startup():
	_set_minute_label(time)
	_set_hour_label(time)

func _set_minute_label(time):
	match time["minute"]:
		0, 1, 2, 3, 4, 5, 6, 7, 8, 9:
			minute_label.set("text", str(0) + str(time["minute"]))
		_:
			minute_label.set("text", str(time["minute"]))

func _set_hour_label(time):
	match time["hour"]:
		1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11:
			hour_label.set("text", str(time["hour"]))
		13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23:
			hour_label.set("text", str(time["hour"] - 12))
		0, 12:
			hour_label.set("text", str(12))
	if time["hour"] >= 12:
		ampm_label.set("text", "PM")
	else:
		ampm_label.set("text", "AM")

func _resync(time):
	_set_hour_label(time)
	_set_minute_label(time)

func _toggle_clock(hidden):
	if hidden: set("visible", false)
	else: set("visible", true)
