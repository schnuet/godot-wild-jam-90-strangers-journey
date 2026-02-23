extends Node2D

@onready var main_music = $main_music;
@onready var event_music = $event_music;
@onready var camp_ambience = $camp_ambience;
@onready var travel_ambience = $travel_ambience;


func start_music(node_name: String, target_volume: float = 0.1):
	var music = get_node(node_name);
	if music.playing:
		return;
	music.volume_linear = 0.0;
	music.play();
	
	var tween = get_tree().create_tween().set_ease(Tween.EASE_IN);
	tween.tween_property(music, "volume_linear", target_volume, 0.5);

func stop_music(node_name: String):
	var music = get_node(node_name);
	
	var tween = get_tree().create_tween().set_ease(Tween.EASE_IN);
	tween.tween_property(music, "volume_linear", 0.0, 1);
	await tween.finished;
	music.stop();


func _on_main_music_finished() -> void:
	main_music.play();


func _on_camp_ambience_finished() -> void:
	camp_ambience.play();


func _on_travel_ambience_finished() -> void:
	travel_ambience.play();


func _on_event_music_finished() -> void:
	event_music.play();
