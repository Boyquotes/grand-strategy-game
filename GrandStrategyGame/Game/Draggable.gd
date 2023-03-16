extends Control
class_name Draggable

## This signal will trigger on every frame where this object is being dragged.
signal is_dragged

var is_being_dragged:bool = false
var relative_starting_position:Vector2 = Vector2.ZERO
var relative_mouse_origin:Vector2 = Vector2.ZERO

func _process(_delta):
	if is_being_dragged:
		var relative_position:Vector2 = get_relative_mouse_position()
		var delta_x:float = relative_position.x - relative_mouse_origin.x
		var delta_y:float = relative_position.y - relative_mouse_origin.y
		var relative_width:float = anchor_right - anchor_left
		var relative_height:float = anchor_bottom - anchor_top
		anchor_left = relative_starting_position.x + delta_x
		anchor_left = clampf(anchor_left, 0, 1 - relative_width)
		anchor_right = anchor_left + relative_width
		anchor_top = relative_starting_position.y + delta_y
		anchor_top = clampf(anchor_top, 0, 1 - relative_height)
		anchor_bottom = anchor_top + relative_height
		emit_signal("is_dragged", self)

func _input(event):
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_being_dragged = false

# Connect signals to this
func _on_dragged():
	is_being_dragged = true
	relative_starting_position = Vector2(anchor_left, anchor_top)
	relative_mouse_origin = get_relative_mouse_position()

func get_relative_mouse_position() -> Vector2:
	var mouse_position:Vector2 = get_viewport().get_mouse_position()
	var window_size:Vector2 = get_viewport().get_visible_rect().size
	return Vector2( \
		mouse_position.x / window_size.x, \
		mouse_position.y / window_size.y)

## Experimental; do not use. Only works for objects anchored to the top-left corner
func clamp_to(control:Control):
	var delta_x:float = anchor_left - control.anchor_right
	var delta_y:float = anchor_top - control.anchor_bottom
	if delta_x < 0 and delta_y < 0:
		if delta_x < delta_y:
			var relative_height:float = anchor_bottom - anchor_top
			anchor_top = control.anchor_bottom
			anchor_bottom = anchor_top + relative_height
		else:
			var relative_width:float = anchor_right - anchor_left
			anchor_left = control.anchor_right
			anchor_right = anchor_left + relative_width