extends Node2D

@export var interactive: bool = true;

@onready var fade = $Fade;
@onready var content_pane = $Content;
@onready var camp_markers = get_tree().get_nodes_in_group("camp_marker");
@onready var sound_map = $sound_open;
@onready var castle_button = $Content/CastleButton;

@onready var coach_icons = [
	$Content/CoachIcon1,
	$Content/CoachIcon2,
	$Content/CoachIcon3,
	$Content/CoachIcon4,
	$Content/CoachIcon5,
	$Content/CoachIcon6,
	$Content/CoachIcon7,
]

func _ready() -> void:
	start_button.hide();
	drag_enabled = false;
	castle_button.disabled = true;
	
	for coach_icon in coach_icons:
		coach_icon.hide();
	
	if interactive:
		MusicPlayer.stop_music("camp_ambience");
		MusicPlayer.stop_music("main_music");
		MusicPlayer.start_music("event_music");
		MusicPlayer.start_music("travel_ambience");
	
		sound_map.play();
		fade.show();
		fade.color = Color.BLACK;
		var tween = get_tree().create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);
		tween.tween_property(fade, "color", Color(0,0,0,0), 1);
		
		start_button.connect("pressed", start_travel);
		load_sections();
		set_initial_section_visibilities();
		set_initial_camera_offset();
		
		await scroll_to_section(Game.next_section);
		
		var current_section_num = Game.next_section;
		await uncover_section(current_section_num);
		drag_enabled = true;

func _process(_delta: float) -> void:
	pan_map_process();

# =============================
# CHOOSE NEXT CAMP:

@onready var sections = [
	$Content/Section1,
	$Content/Section2,
	$Content/Section3,
	$Content/Section4,
	$Content/Section5,
	$Content/Section6,
];
@onready var covers = [
	$Content/Cover1,
	$Content/Cover2,
	$Content/Cover3,
	$Content/Cover4,
	$Content/Cover5,
	$Content/Cover6,
];
@onready var start_button = $Front/StartButton;

var can_choose: bool = true;
var chosen_camp: Node = null;

func set_initial_section_visibilities():
	for num in (Game.next_section):
		if num >= sections.size():
			continue;
		var section = sections[num];
		var cover = covers[num];
		section.show();
		cover.hide();

func uncover_section(num: int):
	if num >= sections.size():
		# END TRAVEL
		print("enabling castle_button");
		castle_button.disabled = false;
		move_coach_icon(6);
		return;
	
	var section = sections[num];
	var cover = covers[num];
	print("uncover section ", num);
	print(section, cover);
	if section:
		await show_section(section);
	if cover:
		await hide_cover(cover);
	if section:
		enable_section(section);
	move_coach_icon(num);

func show_section(section: Node):
	section.show();
	return;

func enable_section(section: Node):
	for marker in section.get_children():
		marker.show();
		if marker.is_in_group("camp_marker"):
			marker.disabled = false;
			marker.connect("pressed", choose_camp.bind(marker));
			print("enable marker ", marker);

func hide_cover(cover: Node):
	return await cover.move_out();

func choose_camp(camp_marker: CampMarker):
	var section = sections[Game.next_section];
	print("choose camp ", camp_marker);
	if chosen_camp != null:
		chosen_camp.set_selected(false);
	chosen_camp = camp_marker;
	chosen_camp.set_selected(true);
	var camp_index = section.get_children().find(camp_marker);
	Game.next_camp_index = camp_index;
	show_travel_button();
	
func show_travel_button():
	$Front.show();
	start_button.show();
	
func start_travel():
	if chosen_camp != null:
		Game.next_camp_has_cook = chosen_camp.has_cook;
		Game.next_camp_has_woodworker = chosen_camp.has_woodworker;
		Game.next_camp_passengers_count = chosen_camp.passengers_count;
	Game.next_section = Game.next_section + 1;

	SceneLoader.load_scene("res://04_travel/4_Travel.tscn", true);
	
	fade.color = Color(0,0,0,0);
	fade.show();
	
	var fade_tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);
	fade_tween.tween_property(fade, "color", Color.BLACK, 1);
	
	var button_tween = get_tree().create_tween();
	button_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).tween_property(start_button, "modulate", Color.TRANSPARENT, 0.5);
	await button_tween.finished;
	
	await Game.wait(1);
	switch_scene_if_loaded();

# =============================
# DRAG AND DROP PANNING

var drag_enabled = true;

var source_camera_offset = 0;
var source_mouse_position: Vector2 = Vector2.ZERO;
var camera_offset: int = 0;
const MIN_CAMERA_OFFSET = 0;
const MAX_CAMERA_OFFSET = 7500;

func set_initial_camera_offset():
	camera_offset = get_section_camera_offset(max(Game.next_section - 1, 0));

func scroll_to_section(num: int):
	print("scroll to section ", num);
	print("sections size", sections.size());
	
	if num >= sections.size():
		var tween = get_tree().create_tween();
		tween.set_ease(Tween.EASE_IN_OUT);
		tween.tween_property(self, "camera_offset", 7260, 1);
		return await tween.finished;
	
	print("scroll to section ", num);
	var target_camera_offset = get_section_camera_offset(num);
	print("scroll to offset", target_camera_offset);
	var tween = get_tree().create_tween();
	tween.set_ease(Tween.EASE_IN_OUT);
	tween.tween_property(self, "camera_offset", target_camera_offset, 1);
	await tween.finished;
	print("new offset", camera_offset);
	
	if num < sections.size():
		var section = sections[num];
		var camps = section.get_children();
		for camp in camps:
			camp.disabled = false;
	
	return;

func get_section_camera_offset(num: int):
	var progress = min(num, sections.size() - 1);
	var active_section = sections[progress];
	var section_position = active_section.position;
	return max(section_position.x - 1400, 0);

func pan_map_process():
	content_pane.position.x = -camera_offset;
	if drag_enabled:
		var current_mouse_position = get_global_mouse_position();
		if Input.is_action_just_pressed("ui_accept"):
			source_camera_offset = camera_offset;
			source_mouse_position = current_mouse_position;
		
		if Input.is_action_pressed("ui_accept"):
			camera_offset = source_camera_offset + source_mouse_position.x - current_mouse_position.x;
			camera_offset = clamp(camera_offset, MIN_CAMERA_OFFSET, MAX_CAMERA_OFFSET);

func move_coach_icon(num: int):
	var coach_icon = coach_icons[num];
	coach_icon.show();
	var pos = coach_icon.position;
	coach_icon.position = pos - Vector2(20, 0);
	coach_icon.modulate = Color.TRANSPARENT;
	var tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel();
	tween.tween_property(coach_icon, "modulate", Color.WHITE, 1);
	tween.tween_property(coach_icon, "position", pos, 1);
	return;

# ===========================
# SECTION ASSIGNMENT

func load_sections():
	assign_sections();
	
	for section_index in Game.map_sections:
		if section_index >= sections.size():
			continue;
		var section = sections[section_index];
		var children = section.get_children();
		var section_config = Game.map_sections.get(section_index);
		
		var camp_i = 0;
		for camp in children:
			camp.disabled = true;
			if not camp.is_in_group("camp_marker"):
				continue;
			var camp_config = section_config.get(camp_i);
			camp.passengers_count = camp_config.get("passengers_count");
			camp.has_cook = camp_config.get("has_cook");
			camp.has_woodworker = camp_config.get("has_woodworker");
			camp.update_icons();
			camp_i += 1;
	return;

func assign_sections():
	if Game.sections_assigned:
		return;
	
	print("assign sections");
	
	var config = {};
	var section_i = 0;
	for section in 7:
		var camp_i = 0;
		var section_config = {};
		for camp in 3:
			var camp_config = {
				"has_cook": false,
				"has_woodworker": false,
				"passengers_count": 0,
			};
			camp_config.set("passengers_count", randi_range(0, 3));
			if camp_config.get("passengers_count") == 0:
				var cook = randi_range(0, 1) == 1;
				if cook:
					camp_config.set("has_cook", true);
				else:
					camp_config.set("has_woodworker", false);
			section_config.set(camp_i, camp_config);
			camp_i += 1;
		config.set(section_i, section_config);
		section_i += 1;
	
	Game.map_sections = config;
	
	Game.sections_assigned = true;


func switch_scene_if_loaded():
	var status = SceneLoader.get_status()
	if status != ResourceLoader.THREAD_LOAD_LOADED:
		# Resource is not loaded, so show the loading screen
		SceneLoader.change_scene_to_loading_screen()
	else:
		# Resource is loaded, so switch to the loaded scene
		SceneLoader.change_scene_to_resource()


func _on_castle_button_pressed() -> void:
	Game.won = true;
	print("castle button pressed");
	start_travel()
