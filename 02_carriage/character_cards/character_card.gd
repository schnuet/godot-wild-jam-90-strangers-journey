extends TextureButton
class_name CharacterCard

var character_id: String = "";
@export var seat_number: int = -1;

func set_character(id: String):
	character_id = id;
