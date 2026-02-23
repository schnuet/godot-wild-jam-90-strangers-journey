extends Node2D

@onready var fade = $Fade;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MusicPlayer.stop_music("travel_ambience");
	MusicPlayer.start_music("main_music");
	fade.show();
	fade.color = Color.BLACK;
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);
	tween.tween_property(fade, "color", Color(0,0,0,0), 3);
