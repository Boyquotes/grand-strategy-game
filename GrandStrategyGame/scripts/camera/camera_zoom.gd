class_name CameraZoom
extends Node
## Allows the player to zoom the camera in/out.
## Automatically zooms in the direction of the cursor.
##
## This node is meant to be added as a child of a CustomCamera2D node.
##
## See this video for more information about some of the code:
## https://www.youtube.com/watch?v=gpvLqLggJuk


# The camera will do its best to reach this amount of zoom
var _target_zoom: float = 1.0
# The previous target is used to correctly zoom at the cursor's location
var _previous_target: float = 1.0

# The limit on how close the camera can zoom in
var _maximum_zoom: float = 1.0
# How close/far the camera will zoom in/out each time
var _zoom_increment: float = 0.075
# How fast the camera zooms in/out
var _zoom_rate: float = 8.0


func _ready() -> void:
	get_tree().get_root().size_changed.connect(_on_screen_size_changed)


func _physics_process(delta: float) -> void:
	var camera := get_parent() as Camera2D
	if not camera:
		set_physics_process(false)
		return
	
	var weight: float = _zoom_rate * delta
	camera.zoom = camera.zoom.lerp(_target_zoom * Vector2.ONE, weight)
	set_physics_process(not is_equal_approx(camera.zoom.x, _target_zoom))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var event_typed := event as InputEventMouseButton
		if event_typed.is_pressed():
			if event_typed.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoom_in(event_typed.position)
			if event_typed.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_out(event_typed.position)


func _zoom_in(mouse_position: Vector2) -> void:
	var camera := get_parent() as CustomCamera2D
	if not camera:
		return
	
	_previous_target = _target_zoom
	_target_zoom = minf(_target_zoom + _zoom_increment, _maximum_zoom)
	_zoom_to_cursor(camera, mouse_position)
	set_physics_process(true)


func _zoom_out(mouse_position: Vector2) -> void:
	var camera := get_parent() as CustomCamera2D
	if not camera:
		return
	
	_previous_target = _target_zoom
	_target_zoom = maxf(_target_zoom - _zoom_increment, _minimum_zoom(camera))
	_zoom_to_cursor(camera, mouse_position)
	set_physics_process(true)


# Make the camera zoom to the cursor's position
func _zoom_to_cursor(camera: CustomCamera2D, mouse_position: Vector2) -> void:
	var viewport_size: Vector2 = camera.get_viewport_rect().size
	var offset_pixels: Vector2 = mouse_position - viewport_size * 0.5
	var current_zoom: Vector2 = Vector2.ONE / _previous_target
	var new_zoom: Vector2 = Vector2.ONE / _target_zoom
	var scaled_offset: Vector2 = offset_pixels * (current_zoom - new_zoom)
	
	# The get_target_position() function from Camera2D doesn't
	# give accurate results when the zoom level is changed smoothly.
	# We have to temporarily set the camera's zoom level to what
	# it's going to be in the end. After using the function,
	# we immediately set the zoom level back to what it was.
	# Now it correctly zooms in/out at the cursor's exact location.
	var temp_zoom: Vector2 = camera.zoom
	camera.zoom = _target_zoom * Vector2.ONE
	camera.position = camera.position_in_bounds(
			camera.get_target_position() + scaled_offset
	)
	camera.zoom = temp_zoom


# Returns the minimum zoom amount such that the camera remains in bounds
func _minimum_zoom(camera: Camera2D) -> float:
	var viewport_size_x: float = camera.get_viewport_rect().size.x
	var viewport_size_y: float = camera.get_viewport_rect().size.y
	var camera_view_size_x: float = camera.limit_right - camera.limit_left
	var camera_view_size_y: float = camera.limit_bottom - camera.limit_top
	var min_zoom_x: float = viewport_size_x / camera_view_size_x
	var min_zoom_y: float = viewport_size_y / camera_view_size_y
	return maxf(min_zoom_x, min_zoom_y)


func _on_screen_size_changed() -> void:
	# Ensure the camera stays in bounds when the screen size changes
	
	var camera := get_parent() as Camera2D
	if not camera:
		return
	
	var minimum_zoom: float = _minimum_zoom(camera)
	if camera.zoom.x < minimum_zoom or camera.zoom.y < minimum_zoom:
		camera.zoom = minimum_zoom * Vector2.ONE
		_target_zoom = minimum_zoom
