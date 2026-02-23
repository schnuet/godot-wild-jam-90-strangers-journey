extends Node2D

@onready var map = $Map;
@onready var start_button = $StartButton;
@onready var credits_button = $CreditsButton;
@onready var logo = $logo;

func _ready() -> void:
	map.camera_offset = 7200;
	MusicPlayer.start_music("main_music");


func _on_start_button_pressed() -> void:
	SceneLoader.load_scene("res://01_camp/1_Camp.tscn", true);
	start_button.disabled = true;
	
	var button_tween = get_tree().create_tween();
	button_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).tween_property(start_button, "modulate", Color.TRANSPARENT, 0.5);
	
	# PAN CAMERA TO LEFT
	var tween = get_tree().create_tween().set_parallel();
	tween.set_trans(Tween.TRANS_QUAD);
	tween.set_ease(Tween.EASE_IN_OUT);
	tween.tween_property(map, "camera_offset", 0, 2);
	tween.tween_property(logo, "modulate", Color.TRANSPARENT, 2);
	await tween.finished;
	await Game.wait(1);
	
	switch_scene_if_loaded();
	
func switch_scene_if_loaded():
	var status = SceneLoader.get_status()
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		# Resource is not loaded, so show the loading screen
		SceneLoader.change_scene_to_loading_screen()
	else:
		# Resource is loaded, so switch to the loaded scene
		SceneLoader.change_scene_to_resource()

func _on_credits_button_pressed() -> void:
	pass # Replace with function body.
