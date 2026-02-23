extends Node2D

@onready var label = $ColorRect/RichTextLabel;
@onready var rect = $ColorRect;
@onready var fade = $Fade;

@onready var rect_offset = rect.position;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fade.show();
	fade.color = Color.BLACK;
	var tween_fade_in = get_tree().create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);
	tween_fade_in.tween_property(fade, "color", Color(0,0,0,0), 3);
	
	$Travel/MoneyBag.hide();
	MusicPlayer.stop_music("event_music");
	MusicPlayer.start_music("travel_ambience");
	MusicPlayer.stop_music("camp_ambience");
	MusicPlayer.start_music("main_music");
	
	rect.color = Color(0,0,0,0);
	
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT);
	tween.tween_property(rect, "color", Color(0,0,0,0.3), 2);
	await tween.finished;
	
	var tween_text = get_tree().create_tween();
	tween_text.tween_property(label, "position", Vector2(label.position.x, -1300), 20);
	await tween_text.finished;
	
	var tween_rect_out = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT);
	tween_rect_out.tween_property(rect, "color", Color(0,0,0,0), 0.5);
	await tween_rect_out.finished;
	
	fade.color = Color(0,0,0,0);
	fade.show();
	var tween_fade = get_tree().create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);
	tween_fade.tween_property(fade, "color", Color(0,0,0,1), 1);
	await tween_fade.finished;
	
	SceneLoader.load_scene("res://scenes_outgame/EndScreen.tscn");


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var camera_pos = get_viewport().get_camera_2d().global_position;
	rect.global_position = camera_pos + rect_offset;
	fade.global_position = camera_pos;
