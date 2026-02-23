extends Node2D

@export var interactive: bool = true;
@onready var next_button = $Front/NextButton;
@onready var camera = $Camera2D;
@onready var coach = $Background/Coach;
@onready var fade = $Fade;
@onready var whip = $whip;

var effects_queue = [];
var dead_characters = [];
var coach_offset = 0;
var new_coach_offset = 0;

func _ready() -> void:
	next_button.hide();
	coach.play();
	whip.play();
	
	if interactive:
		fade.show();
		fade.color = Color.BLACK;
		var tween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);
		tween.tween_property(fade, "color", Color(0,0,0,0), 1);
		
		next_button.connect("pressed", enter_next_camp);
		
		await StoryOverlay.open();
		await run_random_event();
		await do_placement_effects();
		await apply_slight_hunger();
		await StoryOverlay.close();
	
		Game.effects_queue = effects_queue;
	
		enter_next_camp();
		# next_button.show();

func _process(delta: float) -> void:
	camera.position.x += delta * 100;
	coach.position.x += delta * 100;
	var coach_offset_difference = new_coach_offset - coach_offset;
	if abs(coach_offset_difference) < 0.5:
		new_coach_offset = randi_range(-50, 40);
	else:
		coach_offset += delta * coach_offset_difference / 2;
		coach.position.x += delta * coach_offset_difference / 2;
	
	fade.global_position = get_viewport().get_camera_2d().global_position;

func add_effect_to_queue(character_id: String, effect_type: String, affected_characters: Array):
	effects_queue.push_back([character_id, effect_type, affected_characters]);

# ================================
# PLACEMENT EFFECTS

var fighters_fought = false;

func do_placement_effects():
	fighters_fought = false;
	var seats = Game.seat_assignments;
	for seat_index in seats.size():
		var character_id = seats[seat_index];
		if character_id == "":
			continue;
		
		var neighbours = get_neighbour_characters(seat_index, seats);
		await do_neighbour_effects(character_id, neighbours);

func get_neighbour_characters(seat_index: int, seats: Array):
	var places = get_neighbour_places(seat_index, seats);
	while places.has(""):
		places.erase("");
	for dead_char_id in dead_characters:
		places.erase(dead_char_id);
	return places;

func get_neighbour_places(seat_index: int, seats: Array):
	if seat_index == 0:
		return [seats[1]];
	if seat_index == 3:
		return [seats[2]];
	if seat_index == 4:
		return [seats[5]];
	if seat_index == 7:
		return [seats[6]];
	return [seats[seat_index - 1], seats[seat_index + 1]];

func do_neighbour_effects(character_id: String, neighbours):
	if dead_characters.has(character_id):
		return;
	print("do neighbour effects for ", character_id, ": ", neighbours);
	
	if is_fighter(character_id):
		var other_fighter = null;
		var entertainer = null;
		for neighbour in neighbours:
			if is_fighter(neighbour):
				other_fighter = neighbour;
			if is_entertaining(neighbour):
				entertainer = neighbour;
		if other_fighter:
			var fighter_name = Game.get_character_name(character_id);
			if entertainer != null:
				var entertainer_name = Game.get_character_name(entertainer);
				await StoryOverlay.show_text(fighter_name + " is entertained by " + entertainer_name + ".");
				await StoryOverlay.show_text("His bad mood lightens a bit.");
				return;
			elif not fighters_fought:
				add_effect_to_queue(character_id, "hurt", [other_fighter]);
				add_effect_to_queue(other_fighter, "hurt", [character_id]);
				await StoryOverlay.show_text("A fight erupts!");
				var name_b = Game.get_character_name(other_fighter);
				await StoryOverlay.show_text(fighter_name + " and " + name_b + " got in a disagreement over a game of dice.");
				await StoryOverlay.show_text("They both hit each other hard. Blood runs through the cabin. This does not look good.");
				fighters_fought = true;
			return;
	elif is_devious(character_id):
		var rich = [];
		var next_to_fighter = false;
		var fighter = null;
		for neighbour in neighbours:
			if is_rich(neighbour):
				rich.append(neighbour);
			elif is_fighter(neighbour):
				fighter = neighbour;
				next_to_fighter = true;
		if rich.size() == 0:
			return;
		var rich_char_id = rich[0];
		var rich_name = Game.get_character_name(rich_char_id);
		var devious_name = Game.get_character_name(character_id);
		await StoryOverlay.show_text(devious_name + " got more and more twitchy as the trip went on.", true);
		if next_to_fighter:
			var fighter_name = Game.get_character_name(fighter);
			await StoryOverlay.show_text(fighter_name + "s intimidating presence seemed to make him very uneasy.");
		else:
			await StoryOverlay.show_text("For a while, all went alright.");
			await StoryOverlay.show_text("But as the moon disappeared behind a cloud, it got dark in the cabin...");
			await StoryOverlay.show_text(
				"And when the light reached inside again, both him and " + 
				rich_name + " were nowhere to be seen anymore."
			);
			add_effect_to_queue(character_id, "lost", [character_id, rich_char_id]);
			dead_characters.append(character_id);
			dead_characters.append(rich_char_id);
		return;
	
	if is_intelligent(character_id):
		var entertainer = null;
		var has_hurt = false;
		for neighbour in neighbours:
			if is_entertaining(neighbour):
				entertainer = neighbour;
			if is_hurt(neighbour):
				has_hurt = true;
		var intelligent_name = Game.get_character_name(character_id);
		if entertainer:
			var entertainer_name = Game.get_character_name(entertainer);
			await StoryOverlay.show_text(intelligent_name + " had a good time with " + entertainer_name + ".");
			await StoryOverlay.show_text("They didn't even feel time passing by.");
			await StoryOverlay.show_text("For a short while, it was as if the world around them didn't exist.");
			return;
		if has_hurt:
			var healed_neighbours = [];
			for neighbour in neighbours:
				if is_hurt(neighbour):
					healed_neighbours.append(neighbour);
			if healed_neighbours.size() > 0:
				await StoryOverlay.show_text(intelligent_name + " got busy tending to the wounded.");
				add_effect_to_queue(character_id, "heal", healed_neighbours);
		add_effect_to_queue(character_id, "hungry", neighbours);
		return;
	
	if is_cursed(character_id):
		print(character_id + " is cursed.");
		var wise = null;
		for neighbour in neighbours:
			if is_intelligent(neighbour):
				wise = neighbour;
		if wise == null:
			return;
			
		print(character_id + " is next to " + wise);
		
		# Kill all
		var wise_name = Game.get_character_name(wise);
		await StoryOverlay.show_text(wise_name + " felt something strange during the trip.", true);
		await StoryOverlay.show_text("Something was here that should not. Should not be at all.");
		await StoryOverlay.show_text("Chills running down the spine, he slowly turned his head...");
		await StoryOverlay.show_text("...");
		await StoryOverlay.show_text("First, silence.");
		await StoryOverlay.show_text("Then, a shattering roar rumbled through the cabin as something erupted and expelled its rage all around.");
		await StoryOverlay.show_text("Blood. Blood everywhere.");
		await StoryOverlay.show_text("...");
		await StoryOverlay.show_text("Nobody survived. The carriage is empty.");
		add_effect_to_queue(character_id, "lost", Game.characters_on_board);
		for char_id in Game.characters_on_board:
			dead_characters.append(char_id);
		return;
	
	if is_rich(character_id):
		var rich_name = Game.get_character_name(character_id);
		await StoryOverlay.show_text(rich_name + " pays you for the travel expenses.", true);
		Game.gain_money(100);
		
		var has_hungry = false;
		for neighbour in neighbours:
			if is_hungry(neighbour):
				has_hungry = true;
		if has_hungry:
			await StoryOverlay.show_text("...and shared some food with neighbours.");
			var hungry_neighbours = [];
			for neighbour in neighbours:
				if is_hungry(neighbour):
					hungry_neighbours.append(neighbour);
			if hungry_neighbours.size() > 0:
				add_effect_to_queue(character_id, "feed", hungry_neighbours);
		return;


# =========================================
# EVENTS


var events = [
	"ambush",
	"long_trip",
	"fog",
	"closed_gate",
	"wisp"
];

func run_random_event():
	var event_name = events[randi_range(0, events.size() - 1)];
	return await run_event(event_name);

func run_event(event_name: String):
	match event_name:
		"ambush":
			await run_ambush();
		"long_trip":
			await run_long_trip();
		"fog":
			await run_fog();
		"closed_gate":
			await run_closed_gate();
		"wisp":
			await run_wisp();

func run_ambush():
	print("run ambush event");
	var intro = (
		"Suddenly, several hooded scoundrels break out of the undergrowth. " +
		"Within seconds, they surround the coach and begin to approach it whilst their faces reflect a lust for murder. " +
		"The men are armed with rusty swords and one of them even carries a mace. With a guttural scream, the attackers rush " +
		"toward the coach.\n"
	);
	await StoryOverlay.show_text(intro, true);
	var round_count = Game.next_section + 1;
	var attack_size = randi_range(max(round_count - 1, 0), round_count + 1);
	var defense_size = Game.characters_on_board.size();
	var fighters = get_fighters_on_board();
	defense_size += fighters.size() * 2;
	if defense_size == 0:
		await StoryOverlay.show_text("Without any passengers, your coach is doomed and your journey finds an abrupt end.");
		return game_over();
	elif defense_size > attack_size:
		var success_text = "Your coach remains steadfast and the passengers can survive the attack unharmed. And so their journey continues.";
		if fighters.size() > 0:
			success_text = "Thanks to " + Game.get_character_name(fighters[0]) + ", y" + success_text.substr(1);
		await StoryOverlay.show_text(success_text);
	else:
		var loss_text = (
			"After a brutal fight, several injured passengers are left in the coach. " +
			"The attackers managed to steal a number of coins and so the journey continues with a painful loss."
		);
		apply_damage("event");
		Game.money = round(Game.money / 3.0);
		await StoryOverlay.show_text(loss_text);
	
	await StoryOverlay.text_confirmed;

func run_long_trip():
	print("run long trip event");
	var intro = (
		"The journey takes the coach through tangled forests and winding paths. " +
		"This leads to a considerable delay. This weighs particularly heavily on the small and weaker members.\n"
	);
	await StoryOverlay.show_text(intro, true);
	
	var entertaining_characters = get_entertainers_on_board();
	if entertaining_characters.size() == 0:
		var outcome = "Some of the passengers develop a feeling of hunger.";
		apply_hunger("event");
		await StoryOverlay.show_text(outcome);
	else:
		var outcome = "Despite all the hardships of the journey, the mood in the coach remains cheerful and exuberant.";
		print("entertainers on board: ", entertaining_characters);
		await StoryOverlay.show_text(outcome);

func run_fog():
	print("run fog event");
	var intro = (
		"A thick fog suddenly rolls in and obstructs the coachman’s view. " +
		"He finds it difficult to recognize the right path and steers the coach " +
		"uncertainly through the increasingly dense fog.\n"
	);
	await StoryOverlay.show_text(intro, true);
	
	var wise_characters = get_intelligent_on_board();
	if wise_characters.size() == 0:
		var outcome = "After hours of slow movement with no clear path in view, you arrive at a camp in the woods.";
		var section_camps = Game.map_sections.get(Game.next_section);
		var random_camp_id = randi_range(0, 2);
		if section_camps != null:
			var next_camp = section_camps.get(random_camp_id);
			Game.next_camp_has_cook = next_camp.get("has_cook");
			Game.next_camp_has_woodworker = next_camp.get("has_woodworker");
			Game.next_camp_passengers_count = next_camp.get("passengers_count");
		await StoryOverlay.show_text(outcome);
		await StoryOverlay.show_text("But was it the one you were looking for?");
	else:
		var wise_name = Game.get_character_name(wise_characters[0]);
		var outcome = "Thankfully, " + wise_name + " has travelled through these woods quite often and helps you find the way despise the thick cloudy obstacle.";
		await StoryOverlay.show_text(outcome);
	
func run_closed_gate():
	print("run gate event");
	var intro = (
		"The coach comes to an abrupt halt. A humongous, rusty gate blocks the way. " +
		"There seems to be no way to open it. It seems as if the fellowship will have to take a detour.\n"
	);
	await StoryOverlay.show_text(intro, true);
	
	var devious_characters = get_devious_on_board();
	if devious_characters.size() > 0:
		var devious_name = Game.get_character_name(devious_characters[0]);
		var outcome = "But then " + devious_name + " finds a way in! He gets the key and opens up the gate.";
		await StoryOverlay.show_text(outcome);
	else:
		var detour = randf() > 0.5;
		if detour:
			var outcome = "The coach has to turn around and return to the last camp.";
			Game.next_section = Game.next_section - 1;
			Game.returning_to_previous_camp = true;
			await StoryOverlay.show_text(outcome);
		else:
			var outcome = "The coach is taking a longer detour, but the fellowship is growing hungry.";
			apply_hunger("event");
			await StoryOverlay.show_text(outcome);
	
func run_wisp():
	print("run wisp event");
	var intro = (
		"Tempting voices echo from the undergrowth and dancing lights lure the coach into the woods.\n"
	);
	await StoryOverlay.show_text(intro, true);
	
	var characters_on_board = Game.characters_on_board;
	var cursed_characters = get_cursed_on_board();
	if characters_on_board.size() == 0:
		var outcome = "The voices are calling you. Their calls are strong and lead you further off the path...";
		await StoryOverlay.show_text(outcome);
		await StoryOverlay.show_text("As your carriage doesn't fit through the dense underwood, you descend and leave it alone.");
		await StoryOverlay.show_text("...");
		await StoryOverlay.show_text("Nobody ever saw you again as you lost your way in the cold swamps of the dark forest.");
		return game_over();
	if cursed_characters.size() == 0:
		var lost_character = characters_on_board[randi_range(0, characters_on_board.size() - 1)];
		add_effect_to_queue("event", "lost", [lost_character]);
		dead_characters.append(lost_character);
		var char_name = Game.get_character_name(lost_character);
		var outcome = char_name + " can't resist the voices and dancing lights. They wander into the woods and are lost forever.";
		await StoryOverlay.show_text(outcome);
	else:
		await StoryOverlay.show_text("But suddently, the eerie voices grow quiet.");
		await StoryOverlay.show_text("The window slows down, the forest grows silent, as if it were afraid.");
		await StoryOverlay.show_text("No more trace of the tempting will-o’-the-wisps...");
		var char_name = Game.get_character_name(cursed_characters[0]);
		var outcome = char_name + " lets out a slow growling moan.";
		await StoryOverlay.show_text(outcome);
	


# ===========================================
# CHARACTER CHECKERS

func apply_damage(source: String):
	var damaged = [];
	for character_id in Game.seat_assignments:
		if character_id == "baggage_merchant" or character_id == "baggage_beekeeper":
			continue;
		if character_id == "":
			continue;
		var hurt = randf() > 0.5;
		if hurt:
			damaged.append(character_id);
	if damaged.size() > 0:
		add_effect_to_queue(source, "hurt", damaged);

func apply_hunger(source: String):
	var hungry = [];
	var available_characters = [];
	for character_id in Game.seat_assignments:
		if character_id == "baggage_merchant" or character_id == "baggage_beekeeper":
			continue;
		if character_id == "":
			continue;
		if dead_characters.has(character_id):
			continue;
		available_characters.append(character_id);
	if available_characters.size() == 0:
		return;
	for character_id in available_characters:
		var char_hungers = randf() > 0.5;
		if char_hungers:
			hungry.append(character_id);
	if hungry.size() == 0:
		hungry.append(available_characters[0]);
	add_effect_to_queue(source, "hungry", hungry);

func apply_slight_hunger():
	var hungry = [];
	var starved = []
	for character_id in Game.seat_assignments:
		if character_id == "baggage_merchant" or character_id == "baggage_beekeeper":
			continue;
		if character_id == "":
			continue;
		var char_hungers = randf() >= 0.6;
		if char_hungers:
			var character_name = Game.get_character_name(character_id);
			if is_hungry(character_id):
				starved.append(character_id);
				await StoryOverlay.show_text(character_name + " starves.", true);
			else:
				hungry.append(character_id);
				await StoryOverlay.show_text(character_name + " grows hungry.", true);
	if hungry.size() > 0:
		add_effect_to_queue("event", "hungry", hungry);
	if starved.size() > 0:
		add_effect_to_queue("event", "hungry", starved);

func get_entertainers_on_board():
	var chars = Game.seat_assignments;
	var result = [];
	for chara in chars:
		if is_entertaining(chara):
			result.push_back(chara);
	return result;

func get_fighters_on_board():
	var chars = Game.seat_assignments;
	var result = [];
	for chara in chars:
		if is_fighter(chara):
			result.push_back(chara);
	return result;

func get_devious_on_board():
	var chars = Game.seat_assignments;
	var result = [];
	for chara in chars:
		if is_devious(chara):
			result.push_back(chara);
	return result;

func get_intelligent_on_board():
	var chars = Game.seat_assignments;
	var result = [];
	for chara in chars:
		if is_intelligent(chara):
			result.push_back(chara);
	return result;


func get_rich_on_board():
	var chars = Game.seat_assignments;
	var result = [];
	for chara in chars:
		if is_intelligent(chara):
			result.push_back(chara);
	return result;

func get_cursed_on_board():
	var chars = Game.seat_assignments;
	var result = [];
	for chara in chars:
		if is_cursed(chara):
			result.push_back(chara);
	return result;

# ===========================================

func game_over():
	SceneLoader.load_scene("res://scenes_outgame/GameOver.tscn");

# ===========================================
# CHARACTER PROPERTIES

func is_fighter(character_name: String):
	return character_name == "veteran" or character_name == "mercenary";

func is_rich(character_name: String):
	return character_name == "merchant" or character_name == "beekeeper";
	
func is_entertaining(character_name: String):
	return character_name == "bard" or character_name == "femme_fatale";
	
func is_intelligent(character_name: String):
	return character_name == "priest" or character_name == "fortune_teller";
	
func is_cursed(character_name: String):
	return character_name == "bear" or character_name == "cursed_one";
	
func is_devious(character_name: String):
	return character_name == "thief" or character_name == "nervous_man";
	
func is_hurt(character_name: String):
	return Game.passenger_has_state(character_name, "hurt");

func is_hungry(character_name: String):
	return Game.passenger_has_state(character_name, "hungry");
	

# ==================================
# TRAVEL

func enter_next_camp():
	Game.effects_queue = effects_queue;
	if Game.effects_queue.size() == 0:
		if Game.won:
			SceneLoader.load_scene("res://scenes_outgame/Credits.tscn", true);
		else:
			SceneLoader.load_scene("res://01_camp/1_Camp.tscn", true);
	else:
		SceneLoader.load_scene("res://05_effects/05_Effects.tscn", true);
	
	fade.color = Color(0,0,0,0);
	fade.show();
	
	var fade_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);
	fade_tween.tween_property(fade, "color", Color.BLACK, 1);
	
	var button_tween = get_tree().create_tween();
	button_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).tween_property(next_button, "modulate", Color.TRANSPARENT, 0.5);
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
		SceneLoader.change_scene_to_resource()
