extends CharacterBody3D

@export var speed: float = 3.0
@export var damage: int = 15

var player: Node3D
var health: int = 60
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var attack_cooldown: float = 0.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
var base_color: Color

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if mesh.get_active_material(0):
		base_color = mesh.get_active_material(0).albedo_color

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if attack_cooldown > 0:
		attack_cooldown -= delta

	if is_instance_valid(player) and player.is_inside_tree() and health > 0:
		var dir_to_player := player.global_position - global_position
		dir_to_player.y = 0
		var distance := dir_to_player.length()
		
		if distance > 1.2:
			var direction := dir_to_player.normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			look_at(global_position + direction, Vector3.UP)
		else:
			velocity.x = 0
			velocity.z = 0
			if attack_cooldown <= 0 and player.has_method("take_damage"):
				player.take_damage(damage)
				attack_cooldown = 1.0 

	if is_inside_tree():
		move_and_slide()

func take_damage(amount: int) -> void:
	if health <= 0:
		return
		
	health -= amount
	print("Враг ранен! HP: ", health)
	
	if health <= 0:
		queue_free() # Умираем сразу, не ждем конца мигания!
		return
	
	var mat := mesh.get_active_material(0) as StandardMaterial3D
	if mat:
		mat.albedo_color = Color.RED
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self) and mat:
			mat.albedo_color = base_color
