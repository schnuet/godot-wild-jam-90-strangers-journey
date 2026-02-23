extends Node2D

@onready var carriage = $Carriage;
@onready var next_button = $Front/NextButton;

func _ready() -> void:
	next_button.hide();
	MusicPlayer.stop_music("event_music");
	MusicPlayer.stop_music("travel_ambience");
	MusicPlayer.start_music("camp_ambience");
	MusicPlayer.start_music("main_music");
	
	if Game.effects_queue.size() == 0:
		next_scene(0);
	else:
		await Game.wait(1);
		await carriage.apply_effects();
		next_button.show();

func next_scene(wait_seconds: int = 1):
	if Game.won:
		print("game is won");
		SceneLoader.load_scene("res://scenes_outgame/Credits.tscn", true);
	elif Game.next_section >= 7:
		print("game is at max section", Game.next_section);
		SceneLoader.load_scene("res://scenes_outgame/Credits.tscn", true);
	else:
		SceneLoader.load_scene("res://01_camp/1_Camp.tscn", true);
	
	await Game.wait(wait_seconds);
	switch_scene_if_loaded();

func _on_next_button_pressed() -> void:
	next_scene();


func switch_scene_if_loaded():
	var status = SceneLoader.get_status()
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		# Resource is not loaded, so show the loading screen
		SceneLoader.change_scene_to_loading_screen()
	else:
		# Resource is loaded, so switch to the loaded scene
		SceneLoader.change_scene_to_resource()
