extends Node2D

@onready var camp = $Camp;
@onready var seating_button = $Front/SeatingButton;
@onready var fire_animation = $Fire;
@onready var fade = $Fade;

var characters = [];
var character_ids = [];

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fade.show();
	fade.color = Color.BLACK;
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);
	tween.tween_property(fade, "color", Color(0,0,0,0), 1);
	
	MusicPlayer.stop_music("event_music");
	MusicPlayer.stop_music("travel_ambience");
	MusicPlayer.start_music("camp_ambience");
	MusicPlayer.start_music("main_music");
	
	seating_button.connect("pressed", _on_seating_button_pressed);
	seating_button.hide();
	fire_animation.play();
	
	if not Game.returning_to_previous_camp:
		place_random_characters();
		Game.previous_camp_passengers = character_ids.duplicate();
	else:
		place_previous_characters();
		Game.returning_to_previous_camp = false;
	
	# Make sure that we can proceed if the camp is empty:
	if characters.size() == 0:
		await Game.wait(2);
		show_seating_button();


# =============================
# CHARACTER PLACEMENT

var character_scene_paths = {
	"veteran": "res://characters/veteran/veteran.tscn",
	"mercenary": "res://characters/mercenary/mercenary.tscn",
	"femme_fatale": "res://characters/femme_fatale/femme_fatale.tscn",
	"bard": "res://characters/bard/bard.tscn",
	"thief": "res://characters/thief/thief.tscn",
	"nervous_man": "res://characters/nervous_man/nervous_man.tscn",
	"priest": "res://characters/priest/priest.tscn",
	"fortune_teller": "res://characters/fortune_teller/fortune_teller.tscn",
	"cursed_one": "res://characters/cursed_one/cursed_one.tscn",
	"bear": "res://characters/bear/bear.tscn",
	"merchant": "res://characters/merchant/merchant.tscn",
	"beekeeper": "res://characters/beekeeper/beekeeper.tscn",
	"cook": "res://characters/cook/cook.tscn",
	"woodworker": "res://characters/woodworker/woodworker.tscn"
};

func place_random_characters():
	var characters_to_place = Game.next_camp_passengers_count;
	print("placin characters: ", characters_to_place);
	
	var remaining_characters = Game.unused_characters.duplicate();
	
	while (characters_to_place > 0):
		characters_to_place -= 1;
		var index = randi_range(0, remaining_characters.size() - 1);
		if remaining_characters.size() == 0:
			continue;
		var character_id = remaining_characters[index];
		remaining_characters.remove_at(index);
		place_character(character_id);
	
	if Game.next_camp_has_cook:
		place_character("cook");
	
	if Game.next_camp_has_woodworker:
		place_character("woodworker");

func place_character(character_id: String):
	var char_scene = load(character_scene_paths.get(character_id));
	var char_person = char_scene.instantiate();
	char_person.character_name = character_id;
	camp.add_child(char_person);
	characters.append(char_person);
	character_ids.append(character_id);
	char_person.update_placeholder();
	char_person.global_position = get_character_place();
	char_person.connect("dialog_done", _on_char_dialog_done);
	if char_person.global_position.x < 960:
		char_person.flip(true);
	else:
		char_person.flip(false);

func place_previous_characters():
	for char_id in Game.previous_camp_passengers:
		var character_id = char_id;
		var char_scene = load(character_scene_paths.get(character_id));
		var char_person = char_scene.instantiate();
		char_person.character_name = character_id;
		camp.add_child(char_person);
		characters.append(char_person);
		character_ids.append(character_id);
		char_person.update_placeholder();
		char_person.global_position = get_character_place();
		char_person.connect("dialog_done", _on_char_dialog_done);

func _on_char_dialog_done():
	show_seating_button();

var character_places = [
	Vector2(607, 692),
	Vector2(1262, 692),
	Vector2(1460, 730),
	Vector2(420, 730)
];

func get_character_place():
	var place_index = randi_range(0, character_places.size() - 1);
	var place = character_places[place_index];
	character_places.remove_at(place_index);
	return place;

# =============================
# NEXT SCREEN

func show_seating_button():
	seating_button.show();
	
func _on_seating_button_pressed():
	SceneLoader.load_scene("res://02_carriage/2_Carriage.tscn", true);
	fade.color = Color(0,0,0,0);
	fade.show();
	
	var fade_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);
	fade_tween.tween_property(fade, "color", Color.BLACK, 1);
	var button_tween = get_tree().create_tween();
	button_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).tween_property(seating_button, "modulate", Color.TRANSPARENT, 0.5);
	await button_tween.finished;
	
	await Game.wait(1);
	switch_scene_if_loaded();

func switch_scene_if_loaded():
	var status = SceneLoader.get_status()
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		# Resource is not loaded, so show the loading screen
		SceneLoader.change_scene_to_loading_screen()
	else:
		# Resource is loaded, so switch to the loaded scene
		SceneLoader.change_scene_to_resource();
