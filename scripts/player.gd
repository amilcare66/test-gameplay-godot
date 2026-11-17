extends CharacterBody3D

@export var speed: float = 6.0
@export var jump_velocity: float = 5.0
@export var bullet_scene: PackedScene

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var health: int = 100

# Боезапас Glock 19 и состояния
@export var max_ammo: int = 8
var current_ammo: int = 8
var is_reloading: bool = false
var can_shoot: bool = true
var in_cover: bool = false

# Выбранный мышкой враг
var selected_target: Node3D = null
var hud_label: Label

@onready var pivot: Node3D = $Pivot
@onready var muzzle: Marker3D = $Pivot/Muzzle

func _ready() -> void:
	# Создаем текст интерфейса на экране (HUD)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud_label = Label.new()
	hud_label.position = Vector2(20, 20)
	hud_label.add_theme_font_size_override("font_size", 22)
	canvas.add_child(hud_label)
	update_hud()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Ищем врага под курсором мыши
	update_target_under_mouse()

	# 1. Механика укрытия (зажата клавиша S)
	if Input.is_action_pressed("move_down") and is_on_floor():
		in_cover = true
		pivot.scale.y = 0.5 # Приседаем в укрытие
		velocity.x = 0
		velocity.z = 0
	else:
		in_cover = false
		pivot.scale.y = 1.0 # Встаем в полный рост

		# Прыжок (Пробел)
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = jump_velocity

		# 2. Движение влево-вправо (A / D) + небольшой шаг вглубь (W) при желании
		var input_x := Input.get_axis("move_left", "move_right")
		velocity.x = input_x * speed
		velocity.z = 0 # Фиксируем линию движения 2.5D

		# Поворот персонажа: если есть выбранная цель — смотрим на неё, иначе — по движению
		if is_instance_valid(selected_target):
			var target_pos := selected_target.global_position
			target_pos.y = global_position.y
			if global_position.distance_squared_to(target_pos) > 0.01:
				pivot.look_at(target_pos, Vector3.UP)
		elif input_x != 0:
			pivot.look_at(global_position + Vector3(input_x, 0, 0), Vector3.UP)

	move_and_slide()
	update_hud()

func update_target_under_mouse() -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
		
	var mouse_pos := get_viewport().get_mouse_position()
	var best_enemy: Node3D = null
	var min_dist: float = 180.0 # Радиус захвата цели вокруг курсора (в пикселях)

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy) or not enemy.is_inside_tree():
			continue
		var screen_pos := camera.unproject_position(enemy.global_position + Vector3(0, 0.5, 0))
		var dist := mouse_pos.distance_to(screen_pos)
		if dist < min_dist:
			min_dist = dist
			best_enemy = enemy

	if selected_target != best_enemy:
		if is_instance_valid(selected_target) and selected_target.has_method("set_targeted"):
			selected_target.set_targeted(false)
		selected_target = best_enemy
		if is_instance_valid(selected_target) and selected_target.has_method("set_targeted"):
			selected_target.set_targeted(true)

func _unhandled_input(event: InputEvent) -> void:
	# Выстрел по ЛКМ (только если не в укрытии)
	if event.is_action_pressed("shoot") and not in_cover:
		shoot()
		
	# Перезарядка на клавишу R (работает на любой раскладке)
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		reload()

func shoot() -> void:
	if is_reloading or not can_shoot:
		return
		
	if current_ammo <= 0:
		print("Щелк! Патроны кончились, нажми R для перезарядки!")
		reload()
		return
		
	if not bullet_scene:
		print("ОШИБКА: Не назначена сцена пули в Инспекторе игрока!")
		return

	current_ammo -= 1
	can_shoot = false
	
	# Поворачиваемся к выбранной цели перед выстрелом
	if is_instance_valid(selected_target):
		var target_pos := selected_target.global_position
		target_pos.y = global_position.y
		if global_position.distance_squared_to(target_pos) > 0.01:
			pivot.look_at(target_pos, Vector3.UP)

	var bullet = bullet_scene.instantiate()
	bullet.intended_target = selected_target
	get_tree().current_scene.add_child(bullet)
	bullet.global_transform = muzzle.global_transform
	
	update_hud()
	await get_tree().create_timer(0.25).timeout # Темп стрельбы Glock 19
	can_shoot = true

func reload() -> void:
	if is_reloading or current_ammo == max_ammo:
		return
	is_reloading = true
	update_hud()
	await get_tree().create_timer(1.5).timeout # 1.5 сек на смену магазина
	if not is_inside_tree():
		return
	current_ammo = max_ammo
	is_reloading = false
	update_hud()

func take_damage(amount: int) -> void:
	if health <= 0:
		return # Если уже мертвы — не перезагружаем сцену второй раз!
		
	if in_cover:
		print("Игрок в укрытии! Урон заблокирован.")
		return
		
	health -= amount
	update_hud()
	if health <= 0:
		get_tree().call_deferred("reload_current_scene")

func update_hud() -> void:
	if not hud_label:
		return
	var ammo_text := "ПЕРЕЗАРЯДКА..." if is_reloading else "%d / %d (R - перезарядка)" % [current_ammo, max_ammo]
	var cover_text := "\n[ В УКРЫТИИ - УРОН БЛОКИРУЕТСЯ ]" if in_cover else "\n[ Зажми S для укрытия ]"
	hud_label.text = "HP: %d / 100\nGlock 19: %s%s" % [health, ammo_text, cover_text]
