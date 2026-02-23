extends Control

@onready var clouds = get_children();
var moving_out = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_cloud_movement();

var move_tweens: Array[Tween] = [];

func start_cloud_movement():
	for cloud in clouds:
		move_in_dir(cloud, 1 if (randf() > 0.5) else -1);

func move_in_dir(cloud: Node, dir: int):
	if moving_out:
		return;
	if cloud == null:
		return;
	var tree = get_tree();
	if tree == null:
		return;
	var tween = tree.create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD);
	tween.tween_property(cloud, "position", cloud.position + (Vector2(30, 2) * dir), randf_range(1.6, 3.0));
	tween.tween_callback(move_in_dir.bind(cloud, dir * -1));
	move_tweens.append(tween);

func move_out():
	for tween in move_tweens:
		tween.stop();
	for cloud in clouds:
		var tween = get_tree().create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD).set_parallel();
		var v_dir = 1;
		var cloud_rect: Rect2 = cloud.get_rect();
		if cloud.global_position.y + cloud_rect.size.y / 2 < 540:
			v_dir = -1;
		tween.tween_property(cloud, "global_position", Vector2(cloud.global_position.x + randi_range(800, 1200), cloud.global_position.y + v_dir * randi_range(100, 600)), 3)
		tween.tween_property(cloud, "modulate", Color.TRANSPARENT, 2.5)
		tween.tween_property(cloud, "scale", Vector2(1.2, 1.2), 3);	
	
	await Game.wait(3);
	hide();
