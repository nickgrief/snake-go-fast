extends Node2D
class_name Cell

@onready
var sprite := $sprite

var current_state := CellState.state.EMPTY

func set_state(state: CellState.state):
  sprite.region_rect.position = Vector2(state, 0)
  current_state = state
