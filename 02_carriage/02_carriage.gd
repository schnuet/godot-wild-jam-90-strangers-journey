extends Node2D

var CharacterCardScene = preload("res://02_carriage/character_cards/CharacterCard.tscn");

var active_card: CharacterCard;
var source_seat_number: int = -1;
var source_mouse_position: Vector2 = Vector2.ZERO;
var source_card_position: Vector2 = Vector2.ZERO;

@export var non_interactive = false;

@onready var top_row = $Control/TopRow;
@onready var bottom_row = $Control/BottomRow;
@onready var outside = $Control/Outside;
@onready var rejected = $Control/Rejected;
@onready var rejected_background = $Control/RejectedBackground;
@onready var stage = $Control;
@onready var next_button = $Front/NextButton;
@onready var fade = $Fade;

var character_places: Array[Node];
var characters: Array[CharacterCard] = [];
var visible_places_count = 8;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	next_button.hide();
	next_button.connect("pressed", go_to_map_screen);
	
	rejected.hide();
	rejected_background.hide();
	
	character_places = get_tree().get_nodes_in_group("character_place");
	for place in character_places:
		if not Game.existing_seats.has(place.seat_number):
			place.hide();
			visible_places_count -= 1;
	if visible_places_count == 4:
		$Control/WagenVonOben.show();
	elif visible_places_count == 6:
		$Control/WagenVonOben4Er.hide();
		$Control/WagenVonOben6Er.show();
	else:
		$Control/WagenVonOben4Er.hide();
		$Control/WagenVonOben6Er.hide();
		$Control/WagenVonOben.show();
	
	var new_characters = add_characters();
	place_seated_characters(new_characters);
	
	if not non_interactive:
		fade.show();
		fade.color = Color.BLACK;
		var tween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);
		tween.tween_property(fade, "color", Color(0,0,0,0), 1);
		await Game.wait(1);
		await place_unseated_characters(new_characters);
		if characters.size() > visible_places_count:
			rejected.show();
			rejected_background.show();
		update_next_button_visibility();
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if active_card:
		var mouse_offset = get_global_mouse_position() - source_mouse_position;
		active_card.global_position = source_card_position + mouse_offset;

func _input(event: InputEvent) -> void:
	if event.is_action_released("ui_accept"):
		release_card();

# ==========================
# CARDS

func create_character_card(character_id: String) -> CharacterCard:
	var seat_assignments = Game.seat_assignments;
	var seat_number = seat_assignments.find(character_id);
	var card: CharacterCard = CharacterCardScene.instantiate();
	card.set_character(character_id);
	card.seat_number = seat_number;
	if not non_interactive:
		card.connect("button_down", _on_card_down.bind(card));
	characters.push_back(card);
	print("character " + character_id + " states: ", Game.passenger_states.get(character_id));
	if Game.passenger_has_state(character_id, "hungry"):
		print("-> is hungry.");
		card.add_hunger();
	else:
		card.remove_hunger();
	if Game.passenger_has_state(character_id, "hurt"):
		print("-> is hurt.");
		card.add_wound();
	else:
		card.remove_wound();
	return card;

func add_character(character_id: String):
	var card = create_character_card(character_id);
	return card;

func add_characters() -> Array[CharacterCard]:
	var cards: Array[CharacterCard] = [];
	var character_ids = Game.characters_on_board;
	for character_id in character_ids:
		var card = create_character_card(character_id);
		if non_interactive and card.seat_number == -1:
			card = null;
		else:
			cards.push_back(card);
		if character_id == "merchant" or character_id == "beekeeper":
			var baggage_card = create_character_card("baggage_" + character_id);
			if non_interactive and baggage_card.seat_number == -1:
				baggage_card = null;
			else:
				cards.push_back(baggage_card);
	return cards;

func move_card(card: Node, new_position: Vector2) -> void:
	var move_tween = get_tree().create_tween();
	move_tween.set_ease(Tween.EASE_IN_OUT);
	move_tween.tween_property(card, "global_position", new_position, 0.18);

func get_place_for_seat_number(num: int):
	for place in character_places:
		if place.seat_number == num:
			return place;
	return null;

func place_seated_characters(character_cards: Array[CharacterCard]):
	for card in character_cards:
		var place = get_place_for_seat_number(card.seat_number);
		if place:
			place.add_child(card);

func place_unseated_characters(character_cards: Array[CharacterCard]):
	for card in character_cards:
		if card.seat_number == -1:
			add_to_outside(card);

# ==========================
# DRAG N DROP

func _on_card_down(card: CharacterCard):
	source_card_position = card.global_position;
	source_mouse_position = get_global_mouse_position();
	active_card = card;
	$sound_pick.play();
	source_seat_number = card.seat_number;
	card.get_parent().remove_child(card);
	stage.add_child(card);

func release_card():
	if not active_card:
		return;
	
	var dropped_place = get_dropped_place();
	
	var card = active_card;
	move_to_place(card, dropped_place);
	active_card = null;

func move_to_place(card: CharacterCard, place: CharacterPlace):
	var previous_seat_number = card.seat_number;
	var previous_place = get_place_for_seat_number(previous_seat_number);
	if place == null:
		if card == active_card:
			if (
				rejected.visible and
				card.global_position.x < 350 and
				card.global_position.y + card.size.y < 800
			):
				var rejected_cards = get_rejected_cards();
				if rejected_cards.size() >= get_cards_to_reject_count():
					var first_rejected = rejected_cards[0];
					move_to_place(first_rejected, place);
				add_to_rejected(card);
				$sound_return.play();
				update_next_button_visibility();
				return
		add_to_outside(card);
	else:
		$sound_place.play();
		card.seat_number = place.seat_number;
		var character_at_this_place = null;
		for character in characters:
			if character == card:
				continue;
			if character.seat_number == place.seat_number:
				character_at_this_place = character;
		if character_at_this_place:
			move_to_place(character_at_this_place, previous_place);
		var pos = card.global_position;
		card.get_parent().remove_child(card);
		place.add_child(card);
		card.global_position = pos;
		move_card(card, place.global_position);
		if previous_seat_number == -1:
			reorder_outside();
	
	Game.assign_seat(card.character_id, card.seat_number);
	update_next_button_visibility();

func add_to_outside(card: CharacterCard):
	print("move ", card.character_id + " to outside");
	card.seat_number = -1;
	var center = outside.global_position + Vector2(outside.size.x / 2, 0);
	if card.is_inside_tree():
		$sound_return.play();
		var pos = card.global_position;
		card.get_parent().remove_child(card);
		var other_cards = outside.get_children();
		var index = other_cards.size();
		for i in range(other_cards.size(), 0, -1):
			if i == 0:
				break;
			var other_card = other_cards[i - 1];
			print("i: ", index, ", x:", pos.x, " ", other_card.global_position.x);
			if pos.x >= other_card.global_position.x:
				break;
			index -= 1;
		print("index: ", index);
		outside.add_child(card);
		outside.move_child(card, index);
		card.global_position = pos;
	else:
		outside.add_child(card);
		card.global_position = center;
	reorder_outside();

func reorder_outside():
	var center = outside.global_position + Vector2(outside.size.x / 2, 0);
	var GAP = 30;
	var outside_cards = outside.get_children();
	if outside_cards.size() == 0:
		return;
	var card_width = outside_cards[0].size.x;
	var space = outside_cards.size() * card_width + (outside_cards.size() - 1) * GAP;
	var card_pos = center - Vector2(space / 2, 0);
	for list_card in outside_cards:
		move_card(list_card, card_pos);
		card_pos += Vector2(GAP, 0) + Vector2(list_card.size.x, 0);


func add_to_rejected(card: CharacterCard):
	card.seat_number = -2;
	var center = rejected.global_position + Vector2(rejected.size.x / 2, rejected.size.y);
	if card.is_inside_tree():
		var pos = card.global_position;
		card.get_parent().remove_child(card);
		var other_cards = rejected.get_children();
		var index = other_cards.size();
		for i in range(other_cards.size(), 0, -1):
			if i == 0:
				break;
			var other_card = other_cards[i - 1];
			print("i: ", index, ", y:", pos.y, " ", other_card.global_position.y);
			if pos.y >= other_card.global_position.y:
				break;
			index -= 1;
		print("index: ", index);
		rejected.add_child(card);
		rejected.move_child(card, index);
		card.global_position = pos;
	else:
		rejected.add_child(card);
		card.global_position = center;
	reorder_rejected();

func reorder_rejected():
	var center = rejected.global_position + Vector2(rejected.size.x / 2, rejected.size.y / 2);
	var GAP = 30;
	var rejected_cards = rejected.get_children();
	if rejected_cards.size() == 0:
		return;
	var card_height = rejected_cards[0].size.y;
	var space = rejected_cards.size() * card_height + (rejected_cards.size() - 1) * GAP;
	var card_pos = center - Vector2(card_height / 2, space / 2);
	for list_card in rejected_cards:
		move_card(list_card, card_pos);
		card_pos += Vector2(0, GAP) + Vector2(0, list_card.size.y);

func get_rejected_cards() -> Array[CharacterCard]:
	var rejected_cards: Array[CharacterCard] = [];
	for card in characters:
		if card.seat_number == -2:
			rejected_cards.append(card);
	return rejected_cards;
	
func get_cards_to_reject_count():
	return max(characters.size() - visible_places_count, 0);

func get_dropped_place():
	var active_card_left = active_card.global_position.x;
	var active_card_top = active_card.global_position.y;
	var active_card_width = active_card.size.x;
	var active_card_height = active_card.size.y;
	var active_card_right = active_card_left + active_card_width;
	var active_card_bottom = active_card_top + active_card_height;
	
	var overlap = 0;
	var overlap_place: Node = null;
	var leftmost_place_x = 1920;
	for place in character_places:
		if not place.visible:
			continue;
		var width = place.size.x;
		var height = place.size.y;
		var left = place.global_position.x;
		var top = place.global_position.y;
		var right = left + width;
		var bottom = top + height;
		
		if left < leftmost_place_x:
			leftmost_place_x = left;
		
		if right < active_card_left:
			continue;
		if left > active_card_right:
			continue;
		if top > active_card_bottom:
			continue;
		if bottom < active_card_top:
			continue;
		
		var overlap_x = min(right, active_card_right) - max(active_card_left, left);
		var overlap_y = min(bottom, active_card_bottom) - max(top, active_card_top);
		var place_overlap = overlap_x + overlap_y;
		if place_overlap > overlap:
			overlap = place_overlap;
			overlap_place = place;
	
	return overlap_place;


# ==========================
# SCREEN CHANGE

func update_next_button_visibility():
	if non_interactive:
		return;
	if is_ready_to_go_on():
		show_next_button();
	else:
		hide_next_button();

func show_next_button():
	next_button.show();

func hide_next_button():
	next_button.hide();

func is_ready_to_go_on():
	for char_card in characters:
		if char_card.seat_number == -1:
			return false;
	return true;

func go_to_map_screen():
	next_button.hide();
	await remove_rejected();
	SceneLoader.load_scene("res://03_map/3_Map.tscn", true);
	
	fade.color = Color(0,0,0,0);
	fade.show();
	
	var fade_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);
	fade_tween.tween_property(fade, "color", Color.BLACK, 1);
	
	var button_tween = get_tree().create_tween();
	button_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).tween_property(next_button, "modulate", Color.TRANSPARENT, 0.5);
	await button_tween.finished;
	
	await Game.wait(1);
	switch_scene_if_loaded();


func remove_rejected():
	var rejected_chars = [];
	for card in characters:
		if card.seat_number == -2:
			rejected_chars.append(card);

	for card in rejected_chars:
		remove_rejected_card(card);
	return await Game.wait(1);

func remove_rejected_card(card: CharacterCard):
	Game.reject_character(card.character_id);
	var tween = get_tree().create_tween();
	tween.tween_property(card, "global_position", Vector2(-500, card.global_position.y), 0.5);
	return await tween.finished;

# ===========================
# EFFECTS

func apply_effects():
	print("------");
	print("APPLY effects ", Game.effects_queue);
	var effects_queue = Game.effects_queue;
	for effect in effects_queue:
		await apply_effect(effect[0], effect[1], effect[2]);
	Game.effects_queue = [];

func apply_effect(source_character_id: String, effect: String, affected_character_ids: Array):
	if source_character_id:
		print(source_character_id + " affects ", affected_character_ids);
	
	if effect == "hurt":
		for character_id in affected_character_ids:
			if Game.passenger_has_state(character_id, "dead"):
				return;
			if Game.passenger_has_state(character_id, "hurt"):
				kill_card(character_id);
			else:
				hurt_card(character_id);
	
	if effect == "lost":
		for character_id in affected_character_ids:
			if Game.passenger_has_state(character_id, "dead"):
				return;
			kill_card(character_id);
	
	if effect == "heal":
		for character_id in affected_character_ids:
			if Game.passenger_has_state(character_id, "dead"):
				return;
			Game.remove_passenger_state(character_id, "hungry");
	
	if effect == "hungry":
		for character_id in affected_character_ids:
			if Game.passenger_has_state(character_id, "dead"):
				return;
			if Game.passenger_has_state(character_id, "hungry"):
				kill_card(character_id);
			elif Game.passenger_has_state(character_id, "hurt"):
				kill_card(character_id)
			else:
				add_hunger(character_id);
	
	if effect == "feed":
		for character_id in affected_character_ids:
			if Game.passenger_has_state(character_id, "dead"):
				return;
			if Game.passenger_has_state(character_id, "hungry"):
				remove_hunger(character_id);
	await Game.wait(0.5);

func kill_card(character_id: String):
	Game.passenger_kill(character_id);
	var card = find_character_card(character_id);
	print("kill ", character_id, " ", card);
	if card == null:
		return;
	await Game.wait(0.25);
	characters.erase(card);
	card.queue_free();

func hurt_card(character_id: String):
	var card = find_character_card(character_id);
	print("hurt ", character_id, " ", card);
	if card == null:
		return;
	card.add_wound();
	Game.add_passenger_state(character_id, "hurt");

func heal_card(character_id: String):
	var card = find_character_card(character_id);
	print("heal ", character_id, " ", card);
	if card == null:
		return;
	card.remove_wound();
	Game.remove_passenger_state(character_id, "hurt");

func add_hunger(character_id: String):
	var card = find_character_card(character_id);
	print("hunger ", character_id, " ", card);
	if card == null:
		return;
	card.add_hunger();
	Game.add_passenger_state(character_id, "hungry");

func remove_hunger(character_id: String):
	var card = find_character_card(character_id);
	print("feed ", character_id, " ", card);
	if card == null:
		return;
	card.remove_hunger();
	Game.remove_passenger_state(character_id, "hungry");

func find_character_card(character_id: String) -> CharacterCard:
	for card in characters:
		if card.character_id == character_id:
			return card;
	return null;
	

func switch_scene_if_loaded():
	var status = SceneLoader.get_status()
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		# Resource is not loaded, so show the loading screen
		SceneLoader.change_scene_to_loading_screen()
	else:
		# Resource is loaded, so switch to the loaded scene
		SceneLoader.change_scene_to_resource()
