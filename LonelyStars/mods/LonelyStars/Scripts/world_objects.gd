extends Spatial

onready var LSTAPI = get_node_or_null("/root/LSTAPI")
onready var LS = get_node("/root/LonelyStars")
onready var tb = LS.tb
onready var time = LSTAPI.check_time()
var current_state = null
var new_state = null

var is_lighthouse = false

func _load():
	match time["hour"]:
		0, 1, 2, 3, 4, 20, 21, 22, 23:
			visible = true
		5, 6, 7:
			visible = false
		17, 18, 19:
			visible = true
		8, 9, 10, 11, 12, 13, 14, 15, 16:
			visible = false
	_set_visibility_by_time(LSTAPI.check_time())

func _set_visibility_by_time(time):
	if is_lighthouse: # Only show lighthouse at night
		match time["hour"]:
			20, 21, 22, 23, 0, 1, 2, 3, 4:
				new_state = "fade_in"
			5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19:
				new_state = "fade_out"
			_:
				print(LS.ID + ": Failed to get hour for World Object: " + str(self))
	else:
		match time["hour"]:
			17, 18, 19, 20, 21, 22, 23, 0, 1, 2, 3, 4:
				new_state = "fade_in"
			5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16:
				new_state = "fade_out"
			_:
				print(LS.ID + ": Failed to get hour for World Object: " + str(self))

	if new_state != current_state:
		if is_lighthouse: print(LS.ID + ": new_state did not equal current state: " + str(self))
		current_state = new_state
		match current_state:
			"fade_in":
				$Anim.play("Show")
				if is_lighthouse:
					$Anim.queue("Spin")
				if !visible:
					visible = true
			"fade_out":
				$Anim.play("Hide")
			"hidden":
				visible = false
	#if is_lighthouse && !$Anim.is_playing():
	#	$Anim.play("Spin")

func _ready():
	if LSTAPI != null:
		LSTAPI.connect("hour_has_passed", self, "_set_visibility_by_time")
	if has_node("lighthouse_light_glass_mesh"):
		is_lighthouse = true
	if tb != null:
		tb.connect("mod_config_updated", self, "_on_config_update")
	_load()

func _on_config_update(mod_id: String, new_config: Dictionary):
	if mod_id != LS.ID:
		return
	
	if is_lighthouse:
		match time["hour"]:
			20, 21, 22, 23, 0, 1, 2, 3, 4:
				match LS.config["lighthouse"]:
					true:
						$Anim.play("Show")
						$Anim.queue("Spin")
						current_state = "fade_in"
					false:
						$Anim.play("Hide")
						current_state = "fade_out"
			5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19:
				match LS.config["lighthouse"]:
					true:
						return
					false:
						if LS.LS_lighthouse_loaded:
							$Anim.play("Hide")

func _exit_tree():
	queue_free()
