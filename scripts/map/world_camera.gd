class_name WorldCamera
extends Camera2D
## Pan (right/middle-drag or WASD/arrows) and zoom (mouse wheel).

@export var pan_speed := 700.0
@export var zoom_step := 1.1
@export var min_zoom := 0.25
@export var max_zoom := 3.0

var _dragging := false


func _ready() -> void:
	make_current()


func set_zoom_level(z: float) -> void:
	var c := clampf(z, min_zoom, max_zoom)
	zoom = Vector2(c, c)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_by(zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_by(1.0 / zoom_step)
		elif event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		position -= event.relative / zoom


func _process(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if dir != Vector2.ZERO:
		position += dir.normalized() * pan_speed * delta / zoom.x


func _zoom_by(factor: float) -> void:
	set_zoom_level(zoom.x * factor)
