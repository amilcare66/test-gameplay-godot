extends Area3D

@export var speed: float = 25.0
@export var damage: int = 20

# Конкретная цель, которую выбрал игрок мышкой
var intended_target: Node3D = null

func _ready() -> void:
	get_tree().create_timer(3.0).timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += -global_transform.basis.z * speed * delta

func _on_body_entered(body: Node3D) -> void:
	# 1. Игнорируем самого игрока
	if body.is_in_group("player"):
		return
		
	# 2. Если игрок прицелился в конкретного врага, пуля пролетает мимо других врагов,
	# чтобы попасть именно в выбранную цель!
	if is_instance_valid(intended_target) and body.is_in_group("enemy") and body != intended_target:
		return
		
	if body.has_method("take_damage"):
		body.take_damage(damage)
		
	queue_free()
