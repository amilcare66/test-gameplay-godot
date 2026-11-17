extends CharacterBody3D

@export var speed: float = 6.0
@export var jump_velocity: float = 5.0
@export var bullet_scene: PackedScene

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var health: int = 100

@onready var pivot: Node3D = $Pivot
@onready var muzzle: Marker3D = $Pivot/Muzzle

func _physics_process(delta: float) -> void:
	# 1. Гравитация и прыжок
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# 2. Передвижение (WASD)
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		# Поворачиваем только узел Pivot (тело и дуло), а камера остается неподвижной!
		pivot.look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		shoot()

func shoot() -> void:
	if not bullet_scene:
		print("ОШИБКА: Не назначена сцена пули в Инспекторе игрока!")
		return
		
	var bullet = bullet_scene.instantiate()
	# Добавляем пулю на текущую сцену уровня
	get_tree().current_scene.add_child(bullet)
	bullet.global_transform = muzzle.global_transform

func take_damage(amount: int) -> void:
	health -= amount
	print("Игрок получил урон! Осталось HP: ", health)
	if health <= 0:
		print("Игрок погиб!")
		# Безопасная перезагрузка сцены после завершения физического кадра:
		get_tree().call_deferred("reload_current_scene")
