extends Area2D

# Added a specific signal for the Arena script to listen to
signal health_changed(current_health, max_health)
signal boss_died 

@export var hp_bar: ProgressBar

@export var homing_laser_scene: PackedScene
@export var health: int = 50
@export var max_health: int = 50
@export var laser_interval: float = 3.0
@export var laser_to_spike_delay: float = 5.0
@export var spike_cooldown: float = 2.0
@export var spike_to_weakness_delay: float = 3.0
@export var cycle_restart_delay: float = 4.0
@export var laser_speed: float = 220.0
@export var laser_steer_force: float = 10.0
@export var spike_warning_time: float = 3.0
@export var spike_active_time: float = 2.0

@onready var muzzle_left: Marker2D = $MuzzleLeft
@onready var muzzle_right: Marker2D = $MuzzleRight
@onready var sprite: Sprite2D = $Sprite2D

var immune_to_normal_bullets: bool = true
var _running: bool = false
var _active_adds: int = 0   

func _ready() -> void:
	add_to_group("enemies")
	
	if hp_bar:
		# Connect to the health bar's update function
		health_changed.connect(hp_bar._on_boss_health_changed)
	
	health_changed.emit(health, max_health)

func _input(event: InputEvent) -> void:
	# Debug key for testing damage
	if event.is_action_pressed("ui_accept"):
		take_damage(10)

func start_attack_cycle() -> void:
	if _running:
		return
	_running = true

	await get_tree().create_timer(1.5).timeout

	while health > 0 and is_inside_tree():
		# PHASE 1: Laser Bursts
		for i in range(3):
			if health <= 0: return
			shoot_single_burst()
			await get_tree().create_timer(laser_interval).timeout

		await get_tree().create_timer(laser_to_spike_delay).timeout

		# PHASE 2: Spikes
		for i in range(3):
			if health <= 0: return
			await summon_spikes()
			await get_tree().create_timer(spike_cooldown).timeout

		await get_tree().create_timer(spike_to_weakness_delay).timeout

		if health <= 0: return

		# PHASE 3: Weakness Phase (Adds/Batteries)
		immune_to_normal_bullets = true
		_active_adds = 0

		var set_index: String = ["1", "2"].pick_random()
		trigger_weakness_set(set_index)
		
		while _active_adds > 0:
			await get_tree().create_timer(0.25).timeout
			if health <= 0: return
		
		# Boss takes damage once adds are cleared
		take_damage(10)
		immune_to_normal_bullets = false
		flash_color(Color.WHITE)
		await get_tree().create_timer(cycle_restart_delay).timeout

func trigger_weakness_set(suffix: String) -> void:
	var batt_group = get_tree().get_nodes_in_group("BattArr" + suffix)
	var enemy_group = get_tree().get_nodes_in_group("EnemyArr" + suffix)

	for battery in batt_group:
		if battery.has_method("trigger_sequence"):
			battery.trigger_sequence()
			if battery.has_signal("destroyed") and not battery.destroyed.is_connected(_on_add_destroyed):
				battery.destroyed.connect(_on_add_destroyed, CONNECT_ONE_SHOT)
			_active_adds += 1

	for enemy in enemy_group:
		if enemy.has_method("trigger_sequence"):
			enemy.trigger_sequence()
			if enemy.has_signal("destroyed") and not enemy.destroyed.is_connected(_on_add_destroyed):
				enemy.destroyed.connect(_on_add_destroyed, CONNECT_ONE_SHOT)
			_active_adds += 1

func _on_add_destroyed() -> void:
	_active_adds -= 1
	_active_adds = max(_active_adds, 0)

func summon_spikes() -> void:
	var spike_groups = get_tree().get_nodes_in_group("SpikeArr")
	if spike_groups.is_empty(): return

	var available: Array[Node] = []
	for group in spike_groups:
		var busy: bool = false
		for spike in group.get_children():
			if spike.has_method("is_sequence_active") and spike.is_sequence_active():
				busy = true
				break
		if not busy:
			available.append(group)

	if available.is_empty():
		await get_tree().create_timer(spike_warning_time + spike_active_time).timeout
		return

	var chosen = available.pick_random()
	for spike in chosen.get_children():
		if spike.has_method("trigger_sequence"):
			spike.warning_time = spike_warning_time
			spike.active_time = spike_active_time
			spike.trigger_sequence()

	await get_tree().create_timer(spike_warning_time + spike_active_time + 0.1).timeout

func shoot_single_burst() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty() or homing_laser_scene == null:
		return
	fire_pair(players.pick_random())

func fire_pair(target: Node2D) -> void:
	fire_single_laser(muzzle_left.global_position, (target.global_position - muzzle_left.global_position).angle(), target)
	fire_single_laser(muzzle_right.global_position, (target.global_position - muzzle_right.global_position).angle(), target)

func fire_single_laser(pos: Vector2, angle: float, target: Node2D) -> void:
	var laser = homing_laser_scene.instantiate()
	get_parent().add_child(laser)
	if "speed" in laser:
		laser.speed = laser_speed
	if laser.has_method("start"):
		laser.start(Transform2D(angle, pos), target)

func take_damage(amount: int) -> void:
	if immune_to_normal_bullets and amount < 5:
		flash_color(Color.CYAN)
		return

	health -= amount
	health_changed.emit(health, max_health)
	
	flash_color(Color.RED)
	if health <= 0:
		die()

func die() -> void:
	# Alert the Arena script that the boss is gone
	boss_died.emit()
	# Optional: Add an explosion or death animation here
	queue_free()

func flash_color(color: Color) -> void:
	if sprite == null:
		return
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", color, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
