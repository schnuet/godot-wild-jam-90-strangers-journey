extends Area2D
class_name CampCharacter

@export var character_name:String;
@export var dialogue_options: JSON;
signal start_dialog
signal dialog_done

var animated_sprite: AnimatedSprite2D;

func _ready() -> void:
	if has_node("AnimatedSprite2D"):
		animated_sprite = $AnimatedSprite2D;
		animated_sprite.play();

	print("character " + character_name + " ready.");
	
	connect("input_event", _on_input_event);

func _on_input_event(_viewport: Node, _event: InputEvent, _shape_idx: int) -> void:
	if not Input.is_action_just_pressed("ui_accept"):
		return;
	
	print("click on " + character_name);
	DialogueOverlay.set_character(character_name);
	var dialogue: Dictionary = dialogue_options.data;
	DialogueOverlay.set_dialogue(dialogue);
	emit_signal("start_dialog");
	await DialogueOverlay.open();
	if Game.rejected_characters.has(character_name):
		await DialogueOverlay.play_dialogue("greeting");
	elif Game.characters_on_board.has(character_name):
		await DialogueOverlay.play_dialogue("accept");
	else:
		await DialogueOverlay.play_dialogue("greeting");
		
	dialog_done.emit();

func update_placeholder():
	if has_node("AnimatedSprite2D"):
		return;
	var placeholder_size = Vector2(150, 475);
	var placeholder_position = Vector2(-75, -475);
	var placeholder = ColorRect.new();
	add_child(placeholder);
	placeholder.color = Color.DARK_GRAY;
	placeholder.size = placeholder_size;
	placeholder.position = placeholder_position;
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE;
	var placeholder_label = Label.new();
	add_child(placeholder_label);
	placeholder_label.text = Game.get_character_name(character_name) + " (" + character_name + ")";

func flip(flipped: bool):
	if not has_node("AnimatedSprite2D"):
		return;
	animated_sprite.flip_h = Game.character_flip.get(character_name);
	if not flipped:
		animated_sprite.flip_h = not animated_sprite.flip_h
