extends Control

@onready var label = $Label;

var offset: Vector2 = Vector2.ZERO;

var value: int = 0;
var displayed_value: int = 0;

func _ready() -> void:
	offset = global_position;
	value = Game.money;
	displayed_value = Game.money;
	label.text = str(round(value));

func _process(_delta: float) -> void:
	if Game.money != value:
		set_value(Game.money);
	
	label.text = str(round(displayed_value));
	update_camera_position();

func set_value(val: int):
	value = val;
	var tween = get_tree().create_tween();
	
	tween.tween_property(self, "displayed_value", value, 0.5);

func update_camera_position():
	var camera = get_viewport().get_camera_2d();
	if camera:
		global_position = camera.global_position + offset;
	else:
		global_position = offset;
