extends Button
class_name CampMarker

@export var has_cook: bool = false;
@export var has_woodworker: bool = false;
@export var passengers_count: int = 0;

@onready var cook_icon = $CookIcon;
@onready var woodworker_icon = $WoodworkerIcon;
@onready var passengers_icon = $PassengersIcon;
@onready var shadow = $Shadow;

var selected = false;

func _ready() -> void:
	cook_icon.hide();
	woodworker_icon.hide();
	passengers_icon.hide();
	shadow.show();
	shadow.modulate = Color(1,1,1, 0.1);
	$AnimatedSprite2D.animation = str(randi_range(1, 6));

func set_selected(sel: bool):
	selected = sel;
	if sel:
		shadow.modulate = Color(1,1,1, 0.4);
	else:
		shadow.modulate = Color(1,1,1, 0.1);

func update_icons():
	if has_cook:
		cook_icon.show();
	else:
		cook_icon.hide();
	
	if has_woodworker:
		woodworker_icon.show();
	else:
		woodworker_icon.hide();
	
	if passengers_count > 0:
		passengers_icon.show();
	else:
		passengers_icon.hide();

func set_has_cook(val: bool):
	has_cook = val;
	if val:
		cook_icon.show();
	else:
		cook_icon.hide();

func set_has_woodworker(val: bool):
	has_woodworker = val;
	if val:
		woodworker_icon.show();
	else:
		woodworker_icon.hide();

func set_passengers_count(val: int):
	passengers_count = val;
	if passengers_count > 0:
		passengers_icon.show();
	else:
		passengers_icon.hide();


func _on_button_pressed() -> void:
	print("camp button pressed");
	emit_signal("pressed");


func _on_button_mouse_entered() -> void:
	if disabled:
		return;
	if selected:
		shadow.modulate = Color(1,1,1, 0.4);
	else:
		shadow.modulate = Color(1,1,1, 0.2);


func _on_button_mouse_exited() -> void:
	if disabled:
		return;
	if selected:
		shadow.modulate = Color(1,1,1, 0.4);
	else:
		shadow.modulate = Color(1,1,1, 0.1);
