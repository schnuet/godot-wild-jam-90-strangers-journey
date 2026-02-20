extends Area2D
class_name CampCharacter

@export var character_name:String;
@export var dialogue_options: JSON;
signal start_dialog

var animated_sprite: AnimatedSprite2D;

func _ready() -> void:
	if has_node("AnimatedSprite2D"):
		animated_sprite = $AnimatedSprite2D;
		animated_sprite.play();

	print("character " + character_name + " ready.");
	
	connect("input_event", _on_input_event);

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if not Input.is_action_just_pressed("ui_accept"):
		return;
	
	print("click on " + character_name);
	DialogueOverlay.set_character(character_name);
	var dialogue: Dictionary = dialogue_options.data;
	DialogueOverlay.set_dialogue(dialogue);
	await DialogueOverlay.open();
	if Game.rejected_characters.has(character_name):
		DialogueOverlay.play_dialogue("deny");
	elif Game.characters_on_board.has(character_name):
		DialogueOverlay.play_dialogue("accept");
	else:
		DialogueOverlay.play_dialogue("greeting");
	emit_signal("start_dialog");
