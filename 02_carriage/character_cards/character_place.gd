extends Control
class_name CharacterPlace

@onready var shadow = $Shadow;
@export var seat_number: int = 0;

func _ready() -> void:
	shadow.hide();

func show_hover():
	shadow.show();

func hide_hover():
	shadow.hide();
