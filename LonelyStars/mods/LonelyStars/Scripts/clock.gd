extends Node

onready var LSTAPI: Node = get_node_or_null("/root/LSTAPI")
onready var LS: Node = get_node("/root/LonelyStars")
onready var pd: Node = get_node("/root/PlayerData")

onready var minute_label: Label = get_node("digital_clock/clock_container/min")
onready var hour_label: Label = get_node("digital_clock/clock_container/hour")
onready var ampm_label: Label = get_node("digital_clock/clock_container/ampm")

onready var second_hand: Control = get_node("clock/second_hand")
onready var minute_hand: Control = get_node("clock/minute_hand")
onready var hour_hand: Control = get_node("clock/hour_hand")

onready var config: Dictionary = LS.config
var time: Dictionary

func _ready():
	if LSTAPI != null:
		time = LSTAPI.check_time()
		LSTAPI.connect("second_has_passed", self, "_set_second")
		LSTAPI.connect("minute_has_passed", self, "_set_minute")
		LSTAPI.connect("hour_has_passed", self, "_set_hour")
		LSTAPI.connect("time_has_jumped", self, "_resync")
		_startup()
	pd.connect("_hide_hud_toggle", self, "_toggle_clock")

func _startup():
	match config["digital_clock"]:
		false:
			get_node("clock").visible = true
			_calulate_hand_positions(time)
		true:
			get_node("digital_clock").visible = true
			_set_minute(time)
			_set_hour(time)

func _calulate_hand_positions(time):
		var second_starting_rotation = 0
		for s in time["second"]:
			second_starting_rotation = second_starting_rotation + 6
		var minute_starting_rotation = 0
		for m in time["minute"]:
			minute_starting_rotation = minute_starting_rotation + 6
		var hour_starting_rotation = 0
		for h in time["hour"]:
			hour_starting_rotation = hour_starting_rotation + 30

		second_hand.set("rect_rotation", second_starting_rotation)
		minute_hand.set("rect_rotation", minute_starting_rotation)
		hour_hand.set("rect_rotation", hour_starting_rotation)

func _set_second(time):
	if config["digital_clock"] == true:
		return
	second_hand.set("rect_rotation", second_hand.get("rect_rotation") + 6)

func _set_minute(time):
	match config["digital_clock"]:
		false:
			minute_hand.set("rect_rotation", minute_hand.get("rect_rotation") + 6)
		true:
			match time["minute"]:
				0, 1, 2, 3, 4, 5, 6, 7, 8, 9:
					minute_label.set("text", str(0) + str(time["minute"]))
				_:
					minute_label.set("text", str(time["minute"]))

func _set_hour(time):
	match config["digital_clock"]:
		false:
			hour_hand.set("rect_rotation", hour_hand.get("rect_rotation") + 30)
		true:
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
	match config["digital_clock"]:
		false:
			_calulate_hand_positions(time)
		true:
			_set_hour(time)
			_set_minute(time)

func _toggle_clock(hidden):
	if hidden: set("visible", false)
	else: set("visible", true)
