extends Node

onready var LS = get_node("/root/LonelyStars")
onready var tb = LS.tb
onready var parent: Node = get_parent()
var LS_campfire = preload("res://mods/LonelyStars/Assets/Scenes/campfire.tscn").instance()

func _ready():
	if tb != null:
		tb.connect("mod_config_updated", self, "_on_config_update")
	LS.campfires.append(parent)
	_add_or_remove_LS_campfire()

func _on_config_update(mod_id: String, new_config: Dictionary):
	if mod_id != LS.ID:
		return
	
	_add_or_remove_LS_campfire()

func _add_or_remove_LS_campfire():
	match LS.config["campfire"]:
		true:
			if !parent.has_node("LS_campfire"): parent.call_deferred("add_child", LS_campfire)
		false:
			if parent.has_node("LS_campfire"): parent.call_deferred("remove_child", parent.get_node("LS_campfire"))

func _exit_tree():
	LS.campfires.erase(parent)
	if parent.has_node("LS_campfire"):
		parent.call_deferred("remove_child", parent.get_node("LS_campfire"))
