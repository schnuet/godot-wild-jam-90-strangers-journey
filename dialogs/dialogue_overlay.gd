extends Control

@onready var text_box:RichTextLabel = $RichTextLabel;
@onready var text_reveal_timer: Timer = $TextRevealTimer;
@onready var animated_sprite:AnimatedSprite2D = $AnimatedSprite2D;
@onready var background_color_rect: ColorRect = $BackgroundColorRect;
@onready var background_image: Sprite2D = $BackgroundImage;

@onready var BACKGROUND_COLOR_FINAL: Color = background_color_rect.color;
@onready var CHARACTER_POSITION_FINAL: Vector2 = animated_sprite.position;

@onready var dialogue_option_1: Button = $Buttons/Option1;
@onready var dialogue_option_2: Button = $Buttons/Option2;
@onready var dialogue_option_3: Button = $Buttons/Option3;

signal text_finished;
signal text_confirmed;
signal option_selected(num: int);

var character_name:String = "none";
var dialogue_options: Dictionary = {};

var closing = false;

func _ready() -> void:
	hide();

func _on_gui_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return;
 
	print("click on dialogue overlay");
	
	if text_box.visible_characters < text_box.get_total_character_count():
		text_box.visible_characters = text_box.get_total_character_count();
		return;
	
	text_confirmed.emit();

# ==========================
# DIALOGUE HANDLING

var playing_dialogue = null;

func play_dialogue(entry: String):
	if entry == "greeting":
		var speech: AudioStreamPlayer = get_node("speech_" + character_name);
		speech.play();
	
	var dialogue = dialogue_options.get(entry);
	
	var dialogue_lines: Array = dialogue.get("lines");
	if dialogue_lines == null:
		print("dialogue " + entry + " does not exist!");
		playing_dialogue = null;
		return;
	
	if playing_dialogue != null:
		return;
	playing_dialogue = entry;
	
	clear_text();
	
	for line in dialogue_lines:
		if line.begins_with("action:"):
			await Game.do_action(line.substr(7));
		else:
			add_text(line);
			await text_finished;
	
	var next = dialogue.get("next");
	if next != null:
		return await play_dialogue("next");
	
	var options = dialogue.get("options");
	if options != null:
		if options.size() >= 1:
			dialogue_option_1.text = options[0][0];
			dialogue_option_1.show();
		if options.size() >= 2:
			dialogue_option_2.text = options[1][0];
			dialogue_option_2.show();
		if options.size() >= 3:
			dialogue_option_3.text = options[2][0];
			dialogue_option_3.show();
		
		var selected_option = await option_selected;
		dialogue_option_1.hide();
		dialogue_option_2.hide();
		dialogue_option_3.hide();
		var next_dialogue_id = options[selected_option][1];
		playing_dialogue = null;
		return await play_dialogue(next_dialogue_id);
	
	return await close();

func set_dialogue(dialogue: Dictionary):
	dialogue_options = dialogue;

# ==========================
# VISIBILITY

func open():
	closing = false;
	clear_text();
	
	# hide everything for fade-in
	dialogue_option_1.hide();
	dialogue_option_2.hide();
	dialogue_option_3.hide();
	background_color_rect.color = Color(0,0,0,0);
	background_image.modulate = Color(0,0,0,0);
	animated_sprite.position = CHARACTER_POSITION_FINAL + Vector2(-200, 0);
	animated_sprite.modulate = Color.TRANSPARENT;
	animated_sprite.play();
	
	show();
	
	# animate background
	var tween_bg_in = get_tree().create_tween().set_parallel(true);
	tween_bg_in.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
	tween_bg_in.tween_property(background_color_rect, "color", BACKGROUND_COLOR_FINAL, 0.5);
	tween_bg_in.tween_property(background_image, "modulate", Color.WHITE, 0.5);
	
	# animate character
	var tween_char_in = get_tree().create_tween().set_parallel(true);
	tween_char_in.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
	tween_char_in.tween_property(animated_sprite, "position", CHARACTER_POSITION_FINAL, 0.5);
	tween_char_in.tween_property(animated_sprite, "modulate", Color.WHITE, 0.5);
	
	return await tween_char_in.finished;

func close():
	closing = true;
	
	text_box.text = "";
	
	# animate background
	var tween_bg_out = get_tree().create_tween();
	tween_bg_out.tween_property(background_color_rect, "color", Color(0,0,0,0), 0.5);
	tween_bg_out.tween_property(background_image, "modulate", Color(0,0,0,0), 0.5);
	
	# animate character
	var tween_char_out = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel(true);
	tween_char_out.tween_property(animated_sprite, "position", CHARACTER_POSITION_FINAL + Vector2(-200, 0), 0.5);
	tween_char_out.tween_property(animated_sprite, "modulate", Color.TRANSPARENT, 0.5);
	
	await tween_bg_out.finished;
	playing_dialogue = null;
	
	# stop speech
	if has_node("speech_" + character_name):
		var speech: AudioStreamPlayer = get_node("speech_" + character_name);
		if speech:
			speech.stop();
		
	if closing:
		hide();

# ============================
# TEXT HANDLING

func add_text(text: String):
	# show all previous lines
	var visible_characters = text_box.get_total_character_count();
	text_box.text  = text_box.text + text + "\n";
	text_box.visible_characters = visible_characters;
	text_reveal_timer.start();
	return text_finished;

func clear_text():
	text_box.text = "";
	text_box.visible_characters = 0;

func _on_text_reveal_timer_timeout() -> void:
	if text_box.visible_characters < text_box.get_total_character_count():
		text_box.visible_characters += 1;
	
	if text_box.visible_characters < text_box.get_total_character_count():
		var next_time = 0.04;
		var last_character = text_box.text.substr(
			text_box.visible_characters-1,
			text_box.visible_characters
		);
		if (last_character == "." or last_character == "?" or last_character == "!"):
			next_time = 0.4;
		elif last_character == "\n":
			next_time = 0.7;
		text_reveal_timer.start(next_time);
	else:
		text_finished.emit();

# ============================
# CHARACTER MANAGEMENT

func set_character(new_character_name: String) -> void:
	character_name = new_character_name;
	animated_sprite.animation = new_character_name;


func _on_option_1_pressed() -> void:
	option_selected.emit(0);


func _on_option_2_pressed() -> void:
	option_selected.emit(1);


func _on_option_3_pressed() -> void:
	option_selected.emit(2);
