extends Area3D

@export_multiline var thought_text: String = "Все гадают о причинах, а мне и так ясно. Начальство догадалось, насколько наш отдел бесполезен."

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var dialogue_box: ColorRect = $"../UI/DialogueBox"
@onready var dialogue_label: Label = $"../UI/DialogueBox/DialogueText"

var is_hovered: bool = false

func _ready() -> void:
	# Делаем так, чтобы плашка текста не мешала кликать по 3D-столу
	if dialogue_box:
		dialogue_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if dialogue_label:
		dialogue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _physics_process(_delta: float) -> void:
	# Пускаем луч прямо из камеры туда, где сейчас курсор мыши
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return
		
	var mouse_pos := get_viewport().get_mouse_position()
	var from := cam.project_ray_origin(mouse_pos)
	var to := from + cam.project_ray_normal(mouse_pos) * 10.0
	
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	var hit_me: bool = result and result.collider == self
	
	if hit_me != is_hovered:
		is_hovered = hit_me
		if is_hovered:
			mesh.position.y = 0.03 # Приподнимаем листок при наведении
			Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		else:
			mesh.position.y = 0.0 # Опускаем обратно
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_hovered:
			print("Кликнули по документу!")
			dialogue_label.text = thought_text
			dialogue_box.visible = true
		elif dialogue_box and dialogue_box.visible:
			# Если кликнули мимо документа в пустое место — прячем текст
			dialogue_box.visible = false
