extends Node2D

var characters_on_board: Array = [];
var rejected_characters: Array = [];
var dead_characters: Array = [];

var won = false;

# FIRST GAME LOAD:
func _ready() -> void:
	setup_game();
	SceneLoader.set_loading_screen("res://LoadingScreen.tscn");

func setup_game():
	won = false;
	reset_passengers();
	reset_money();
	reset_seats();
	reset_sections();

func do_action(command: String):
	var parts = command.split(",");
	var action_name = parts[0];
	parts.remove_at(0);
	print("calling action ", action_name, " with args: ", parts);
	callv(action_name, parts);

# =============================
# CHARACTERS

var all_passengers = [
	"veteran",
	"mercenary",
	"femme_fatale",
	"bard",
	"thief",
	"nervous_man",
	"priest",
	"fortune_teller",
	"cursed_one",
	"bear",
	"merchant",
	"beekeeper"
];

var unused_characters = all_passengers.duplicate();

func add_character(character_name: String):
	if not characters_on_board.has(character_name):
		characters_on_board.push_back(character_name);
		unused_characters.erase(character_name);
	print("added char ", character_name, " --> ", characters_on_board);

func reject_character(character_name: String):
	if not rejected_characters.has(character_name):
		rejected_characters.push_back(character_name);
		unused_characters.erase(character_name);
		characters_on_board.erase(character_name);
		seated_characters.erase(character_name);
	print("rejected char ", character_name, " --> ", rejected_characters);

func get_character_name(character_id: String):
	match character_id:
		"veteran":
			return "Althair";
		"mercenary":
			return "Soldnar";
		"femme_fatale":
			return "Verfyr";
		"bard":
			return "Minne";
		"thief":
			return "Deebe";
		"nervous_man":
			return "Hand";
		"priest":
			return "Heylar";
		"fortune_teller":
			return "Wahsaga";
		"cursed_one":
			return "Fluch";
		"bear":
			return "Arkr";
		"merchant":
			return "Handlur";
		"beekeeper":
			return "Imkahr";
		"cook":
			return "Wyrt";
		"woodworker":
			return "Shrynar"
	return "Unnamed";

var character_flip = {
	"veteran": true,
	"mercenary": false,
	"femme_fatale": false,
	"bard": true,
	"thief": true,
	"nervous_man": false,
	"priest": true,
	"fortune_teller": true,
	"cursed_one": false,
	"bear": true,
	"merchant": false,
	"beekeeper": true,
	"cook": false,
	"woodworker": false
};

# ===============================
# STATES

var passenger_states = {
	"veteran": [],
	"mercenary": [],
	"femme_fatale": [],
	"bard": [],
	"thief": [],
	"nervous_man": [],
	"priest": [],
	"fortune_teller": [],
	"cursed_one": [],
	"bear": [],
	"merchant": [],
	"beekeeper": [],
	"cook": [],
	"woodworker": [],
	"baggage_merchant": [],
	"baggage_beekeeper": []
};

func reset_passengers():
	unused_characters = all_passengers.duplicate();
	characters_on_board = [].duplicate();
	rejected_characters = [].duplicate();
	dead_characters = [].duplicate();
	passenger_states = {
		"veteran": [],
		"mercenary": [],
		"femme_fatale": [],
		"bard": [],
		"thief": [],
		"nervous_man": [],
		"priest": [],
		"fortune_teller": [],
		"cursed_one": [],
		"bear": [],
		"merchant": [],
		"beekeeper": [],
		"cook": [],
		"woodworker": [],
		"baggage_merchant": [],
		"baggage_beekeeper": []
	}.duplicate_deep();

func passenger_has_state(character_id: String, state: String):
	return passenger_states.get(character_id).has(state);

func add_passenger_state(character_id: String, state: String):
	var states = passenger_states.get(character_id);
	if not states.has(state):
		states.append(state);

func remove_passenger_state(character_id: String, state: String):
	var states = passenger_states.get(character_id);
	states.erase(state);

func passenger_kill(character_id: String):
	rejected_characters.erase(character_id);
	characters_on_board.erase(character_id);
	dead_characters.append(character_id);
	var seat_index = seat_assignments.find(character_id);
	if seat_index >= 0:
		seat_assignments[seat_index] = "";
	seated_characters.erase(character_id);

# =============================
# RESOURCES

var money = 200;

func reset_money():
	money = 200;

func lose_money(val: int):
	money -= val;

func gain_money(val: int):
	money += val;

# =============================
# SEATS

var existing_seats = [
	2, 3, 6, 7
];

var seat_assignments: Array = [
	"", "", "", "",
	"", "", "", ""
];
var seated_characters: Array[String] = [];

func assign_seat(character_id: String, seat_number: int):
	for index in range(seat_assignments.size()):
		if seat_assignments[index] == character_id:
			seat_assignments[index] = "";

	if seat_number == -1:
		seated_characters.erase(character_id);
		print("removed ", character_id);
	else:
		seat_assignments[seat_number] = character_id;
		if not seated_characters.has(character_id):
			seated_characters.push_back(character_id);
		print("seated ", character_id, " at ", seat_number);
	print("seat_assignments: ", seat_assignments);

func is_seat_taken(seat_number: int):
	return seat_assignments[seat_number] != "";

func reset_seats():
	seat_assignments = [
		"", "", "", "",
		"", "", "", ""
	];


# =============================
# WOODWORK

const WOODWORK_COST: int = 400;

func accept_woodwork():
	if money < WOODWORK_COST:
		DialogueOverlay.play_dialogue("no_money");
		return;
	
	if not existing_seats.has(2):
		existing_seats.push_back(2);
		existing_seats.push_back(5);
		lose_money(WOODWORK_COST);
		DialogueOverlay.play_dialogue("first_done");
	elif not existing_seats.has(1):
		existing_seats.push_back(1);
		existing_seats.push_back(4);
		lose_money(WOODWORK_COST);
		DialogueOverlay.play_dialogue("second_done");
	else:
		DialogueOverlay.play_dialogue("already_done");
	
	return;

func deny_woodwork():
	return;


# =============================
# MEALS

const MEAL_COST = 200;

func accept_meal():
	if money < MEAL_COST:
		DialogueOverlay.play_dialogue("no_money");
		return;
	
	lose_money(MEAL_COST);
	
	for character_id in characters_on_board:
		if passenger_has_state(character_id, "hungry"):
			remove_passenger_state(character_id, "hungry");
	
	DialogueOverlay.play_dialogue("done");
	
	return;

func deny_meal():
	return;

# =============================
# EFFECTS

var effects_queue = [];

# =============================
# SECTIONS

var next_section: int = 0;

var next_camp_has_cook = false;
var next_camp_has_woodworker = false;
var next_camp_passengers_count = 1;

var returning_to_previous_camp = false;
var previous_camp_passengers = [];

var sections_assigned: bool = false;
var map_sections = {};
var last_camp_index = 0;
var next_camp_index = 0;

func reset_sections():
	next_section = 0;
	
	sections_assigned = false;
	map_sections = {};
	
	next_camp_has_cook = false;
	next_camp_has_woodworker = false;
	next_camp_passengers_count = 1;
	previous_camp_passengers = [];
	returning_to_previous_camp = false;
	

# =============================
# TIMING

func wait(seconds: float):
	return get_tree().create_timer(seconds).timeout
