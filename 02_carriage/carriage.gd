extends Node2D

var CharacterCardScene = preload("res://02_carriage/character_cards/CharacterCard.tscn");

var active_card: CharacterCard;
var source_seat_number: int = -1;
var source_mouse_position: Vector2 = Vector2.ZERO;
var source_card_position: Vector2 = Vector2.ZERO;

@onready var top_row = $Control/Inside/TopRow;
@onready var bottom_row = $Control/Inside/BottomRow;
@onready var outside = $Control/Outside;
@onready var stage = $Control;

var character_places: Array[Node];
var characters: Array[CharacterCard] = [];

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	character_places = get_tree().get_nodes_in_group("character_place");
	Game.add_character("mercenary");
	Game.add_character("femme");
	Game.add_character("veteran");
	Game.assign_seat("veteran", 3);
	var characters = add_characters();
	place_seated_characters(characters);
	await Game.wait(1);
	place_unseated_characters(characters);

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
	var card: CharacterCard = CharacterCardScene.instantiate();
	card.set_character(character_id);
	card.connect("button_down", _on_card_down.bind(card));
	characters.push_back(card);
	return card;

func add_character(character_id: String):
	var card = create_character_card(character_id);
	return card;

func add_characters() -> Array[CharacterCard]:
	var seated_characters = Game.seated_characters;
	var cards: Array[CharacterCard] = [];
	var character_ids = Game.characters_on_board;
	for character_id in character_ids:
		var card = create_character_card(character_id);
		var seat_number = seated_characters.find(character_id);
		card.seat_number = seat_number;
		cards.push_back(card);
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
	source_seat_number = card.seat_number;
	card.get_parent().remove_child(card);
	stage.add_child(card);

func release_card():
	if not active_card:
		return;
	
	var dropped_place = get_dropped_place();
	
	var card = active_card;
	active_card = null;
	
	move_to_place(card, dropped_place);

func move_to_place(card: CharacterCard, place: CharacterPlace):
	var previous_seat_number = card.seat_number;
	var previous_place = get_place_for_seat_number(previous_seat_number);
	if place == null:
		add_to_outside(card);
	else:
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

func add_to_outside(card: CharacterCard):
	card.seat_number = -1;
	var center = outside.global_position + Vector2(outside.size.x / 2, 0);
	if card.is_inside_tree():
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

func get_dropped_place():
	var active_card_left = active_card.global_position.x;
	var active_card_top = active_card.global_position.y;
	var active_card_width = active_card.size.x;
	var active_card_height = active_card.size.y;
	var active_card_right = active_card_left + active_card_width;
	var active_card_bottom = active_card_top + active_card_height;
	
	var overlap = 0;
	var overlap_place: Node = null;
	for place in character_places:
		var width = place.size.x;
		var height = place.size.y;
		var left = place.global_position.x;
		var top = place.global_position.y;
		var right = left + width;
		var bottom = top + height;
		
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
