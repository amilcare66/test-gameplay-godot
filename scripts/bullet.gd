extends Area3D

@export var speed: float = 20.0
@export var damage: int = 20

func _ready() -> void:
	# Удаляем пулю через 3 секунды
	get_tree().create_timer(3.0).timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# Летим вперед по локальной оси -Z
	global_position += -global_transform.basis.z * speed * delta

func _on_body_entered(body: Node3D) -> void:
	# Игнорируем самого игрока, чтобы не ранить себя при выстреле
	if body.is_in_group("player"):
		return
		
	if body.has_method("take_damage"):
		body.take_damage(damage)
		
	queue_free() # Удаляем пулю при попадании в врага или стену
