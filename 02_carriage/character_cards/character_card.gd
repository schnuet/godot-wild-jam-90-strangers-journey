extends TextureButton
class_name CharacterCard

var character_id: String = "";
@export var seat_number: int = -1;
@export var status: String = "normal";

@onready var sprite = $AnimatedSprite2D;
@onready var wounded_marker = $WoundedMarker;
@onready var hungry_marker = $HungryMarker;

func _ready() -> void:
	#$ColorRect.hide();
	#$Label.hide();
	wounded_marker.hide();
	hungry_marker.hide();
	update_image();

func set_character(id: String):
	character_id = id;
	$Label.text = character_id;
	update_image();

func add_hunger():
	status = "hunger";
	update_image();

func remove_hunger():
	status = "normal";
	update_image();

func add_wound():
	status = "hurt";
	update_image();

func remove_wound():
	status = "normal";
	update_image();

func update_image():
	if not sprite:
		return;
	sprite.animation = character_id + "_" + status;
