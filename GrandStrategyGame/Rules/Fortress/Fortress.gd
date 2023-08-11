class_name Fortress
extends ProvinceComponent
# In the future, methods could be added to build/destroy the fortress


var is_built: bool = false : set = set_is_built


func init(is_built_: bool, position_: Vector2):
	is_built = is_built_
	position = position_


func set_is_built(value: bool):
	visible = value
	is_built = value
