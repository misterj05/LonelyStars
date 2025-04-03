extends Node

const ID = "LonelyStars"
const mod_ver = "0.1.0"

onready var worldenv: WorldEnvironment
onready var main_zone
var campfires: Array = []

var LS_fireflies = preload("res://mods/LonelyStars/Assets/Scenes/fireflies.tscn")
var LS_campfire = preload("res://mods/LonelyStars/Assets/Scenes/campfire.tscn")
var LS_campfire_tracker = preload("res://mods/LonelyStars/Assets/Scenes/campfire_tracker.tscn")
var LS_lighthouse = preload("res://mods/LonelyStars/Assets/Scenes/lighthouse.tscn")

var LS_worldenv_loaded = false
var LS_fireflies_loaded = false
var LS_lighthouse_loaded = false

var des_color = null
var in_rain = false
var debug_rain = false # Temp for rain_debug

var config: Dictionary
var LS_config_default: Dictionary = {
	"world_env": true,
	"fireflies": true,
	"campfire": true,
	"lighthouse": true
}

onready var pd = get_node("/root/PlayerData")
onready var popup = get_node("/root/PopupMessage")
var world # Temp for rain_debug

onready var LSTAPI = get_node_or_null("/root/LSTAPI")
onready var tb = get_node_or_null("/root/TackleBox")

onready var dn = get_node_or_null("/root/nubz4lifdaynightcycle")
onready var sf = get_node_or_null("/root/bytefragsSoulFires")

func _physics_process(delta):
	#if debug_rain && is_instance_valid(world):
	#	world._spawn_raincloud()
	pass

func _init_config():
	var saved_config = tb.get_mod_config(ID)

	for key in LS_config_default.keys():
		if !saved_config.has(key):
			saved_config[key] = LS_config_default[key]

	config = saved_config

	_check_config()

	tb.set_mod_config(ID, config)
	tb.connect("mod_config_updated", self, "_on_config_update")

func _check_config():
	if dn != null:
		print(ID + ": DayAndNight detected, disabling world_env and campfire modifications.")
		pd._send_notification(ID + ": DayAndNight Detected, disabling world_env and campfire modifications.", 1)
		config["world_env"] = false
		config["campfire"] = false
	if sf != null:
		print(ID + ": SoulFires detected, disabling campfire modifications.")
		pd._send_notification(ID + ": SoulFires Detected, disabling campfire modifications.", 1)
		config["campfire"] = false

func _on_config_update(mod_id: String, new_config: Dictionary):
	if mod_id != ID:
		return

	config = new_config
	_check_config()
	
	_cleanup()
	_rebuild()

func get_config():
	return config

func _ready():
	print(ID + " has loaded!")
	if tb != null:
		_init_config()
	else: config = LS_config_default
	if LSTAPI != null:
		LSTAPI.connect("time_has_jumped", self, "_handle_time_jump")
	pd.connect("_rain_toggle", self, "_handle_rain")
	get_tree().connect("node_added", self, "_node_scanner")

func _handle_rain(rain):
	if config["world_env"] == false:
		return

	worldenv.rain = false
	match rain:
		true:
			in_rain = true
			worldenv._rain_env(true, true)
			_set_color_by_time(LSTAPI.check_time(), false)
		false:
			in_rain = false
			worldenv._rain_env(false, true)
			_set_color_by_time(LSTAPI.check_time(), false)

func _handle_time_jump(time):
	_cleanup()
	_rebuild()

func _rebuild():
	_node_scanner(worldenv)
	_node_scanner(main_zone)

func _cleanup():
	if is_instance_valid(worldenv):
		match config["world_env"]:
			true:
				print(ID + ": Unloading " + str(worldenv))
				LSTAPI.disconnect("hour_has_passed", self, "_set_color_by_time")
				LS_worldenv_loaded = false
			false: # This is needed to catch if config was changed while loaded.
				if LS_worldenv_loaded:
					print(ID + ": Unloading " + str(worldenv))
					LSTAPI.disconnect("hour_has_passed", self, "_set_color_by_time")
					LS_worldenv_loaded = false
					if dn == null:
						_tween_property(worldenv, "des_color", Color("#ffeed5"))
		worldenv.disconnect("tree_exiting", self, "_cleanup")

	if is_instance_valid(main_zone):
		print(ID + ": Unloading " + str(main_zone))
		match config["fireflies"]:
			true:
				main_zone.call_deferred("remove_child", main_zone.get_node("LS_fireflies"))
				LS_fireflies_loaded = false
			false: # This is needed to catch if config was changed while loaded.
				if LS_fireflies_loaded:
					main_zone.call_deferred("remove_child", main_zone.get_node("LS_fireflies"))
					LS_fireflies_loaded = false
		match config["lighthouse"]:
			true:
				main_zone.call_deferred("remove_child", main_zone.get_node("LS_lighthouse"))
				LS_lighthouse_loaded = false
			false: # This is needed to catch if config was changed while loaded.
				if LS_lighthouse_loaded:
					main_zone.call_deferred("remove_child", main_zone.get_node("LS_lighthouse"))
					LS_lighthouse_loaded = false
		main_zone.disconnect("tree_exiting", self, "_cleanup")

func _node_scanner(node: Node):
	match node.get_path():
		NodePath("/root/world"): # Temp for rain_debug
			world = node
		NodePath("/root/world/Viewport/main/map/main_map/WorldEnvironment"), NodePath("/root/main_menu/world/Viewport/main/map/main_map/WorldEnvironment"):
			node.connect("tree_exiting", self, "_cleanup")
			worldenv = node # Needs to go above _set_color_by_time so worldenv is valid for that function
			if (config["world_env"]):
				LSTAPI.connect("hour_has_passed", self, "_set_color_by_time", [ true ])
				LS_worldenv_loaded = true
				print(ID + ": Found worldenv: " + str(node))
				call_deferred("_set_color_by_time", LSTAPI.check_time(), false)
		NodePath("/root/world/Viewport/main/map/main_map/zones/main_zone"), NodePath("/root/main_menu/world/Viewport/main/map/main_map/zones/main_zone"):
			if (config["fireflies"]):
				node.call_deferred("add_child", LS_fireflies.instance())
				LS_fireflies_loaded = true
			if (config["lighthouse"]) && !LS_lighthouse_loaded:
				node.call_deferred("add_child", LS_lighthouse.instance())
				LS_lighthouse_loaded = true
			node.connect("tree_exiting", self, "_cleanup")
			main_zone = node
	if node.has_node("campfire_flame"):
		if !node.has_node("LS_campfire_tracker"): node.call_deferred("add_child", LS_campfire_tracker.instance())

func _tween_property(node, property: String, val):
	var t = node.create_tween()
	t.tween_property(node, property, val, 5)
	t.tween_callback(t, "kill")

func _set_color_by_time(time, should_tween):
	if is_instance_valid(worldenv):
		match time["hour"]:
			0, 1, 2, 3, 4, 20, 21, 22, 23, 24:
				if should_tween: 
					_tween_property(worldenv, "des_color", Color("#3566b7"))
				else: worldenv.des_color = Color("#3566b7") # New: 3566b7 Old: 283e62 OG: 14253e
			5, 6, 7:
				if should_tween:
					_tween_property(worldenv, "des_color", Color("#ffd6e7"))
				else: worldenv.des_color = Color("#ffd6e7") # New: ffeed5 Old: ffd6e7
			17, 18, 19:
				if should_tween:
					_tween_property(worldenv, "des_color", Color("#ffa370"))
				else: worldenv.des_color = Color("#ffa370")
			8, 9, 10, 11, 12, 13, 14, 15, 16:
				if should_tween:
					_tween_property(worldenv, "des_color", Color("#d5eeff"))
				else: worldenv.des_color = Color("#d5eeff")
			_:
				worldenv.des_color = Color("ffeed5")
				print(ID + " Error: " + str(time) + ": could not set world_env by hour, hour is likely overflowed")
