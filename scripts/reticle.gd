extends CenterContainer

@export var DOT_RAD : float = 1.0
@export var DOT_COL : Color = Color.DARK_GRAY

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(0, 0), DOT_RAD, DOT_COL)
