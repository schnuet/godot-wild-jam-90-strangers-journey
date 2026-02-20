extends Node2D

var characters_on_board: Array[String] = [];
var rejected_characters: Array[String] = [];

func do_action(command: String):
	var parts = command.split(",");
	var action_name = parts[0];
	parts.remove_at(0);
	print("calling action ", action_name, " with args: ", parts);
	callv(action_name, parts);

func add_character(character_name: String):
	if not characters_on_board.has(character_name):
		characters_on_board.push_back(character_name);
	print("added char ", character_name, " --> ", characters_on_board);

func reject_character(character_name: String):
	if not rejected_characters.has(character_name):
		rejected_characters.push_back(character_name);
	print("rejected char ", character_name, " --> ", rejected_characters);


# =============================
# SEATS

var seat_assignments: Array = [
	"0", "1", "2", "3",
	"4", "5", "6", "7"
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
# TIMING

func wait(seconds: float):
	return get_tree().create_timer(seconds).timeout
