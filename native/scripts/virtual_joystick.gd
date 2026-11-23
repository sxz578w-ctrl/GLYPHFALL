extends Control
class_name GlyphfallTouchStick

signal direction_changed(value: Vector2)

var _pressed: bool = false
var _direction := Vector2.ZERO
var _knob_position := Vector2.ZERO
var _radius: float = 76.0

func _ready() -> void:
    custom_minimum_size = Vector2(188.0, 188.0)
    mouse_filter = Control.MOUSE_FILTER_STOP
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _pressed = true
            _update_direction(_screen_to_local(event.position))
        else:
            _release_stick()
    elif event is InputEventScreenDrag and _pressed:
        _update_direction(to_local(event.position))
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        _pressed = event.pressed
        if _pressed:
            _update_direction(get_local_mouse_position())
        else:
            _release_stick()
    elif event is InputEventMouseMotion and _pressed:
        _update_direction(get_local_mouse_position())

func _screen_to_local(screen_position: Vector2) -> Vector2:
    var inverse_canvas_transform: Transform2D = get_global_transform_with_canvas().affine_inverse()
    return inverse_canvas_transform * screen_position

func _update_direction(point: Vector2) -> void:
    var center := size * 0.5
    var delta := point - center
    _knob_position = delta.limit_length(_radius)
    _direction = Vector2(_knob_position.x / _radius, _knob_position.y / _radius).limit_length(1.0)
    direction_changed.emit(_direction)
    queue_redraw()

func _release_stick() -> void:
    _pressed = false
    _direction = Vector2.ZERO
    _knob_position = Vector2.ZERO
    direction_changed.emit(Vector2.ZERO)
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    draw_circle(center, _radius + 8.0, Color(0.015, 0.025, 0.055, 0.36))
    draw_arc(center, _radius + 6.0, 0.0, TAU, 64, Color(0.43, 0.79, 0.98, 0.62), 2.0, true)
    draw_arc(center, _radius - 2.0, 0.0, TAU, 64, Color(0.62, 0.82, 1.0, 0.12), 1.0, true)
    draw_circle(center + _knob_position, 39.0, Color(0.18, 0.53, 0.8, 0.72))
    draw_arc(center + _knob_position, 39.0, 0.0, TAU, 48, Color(0.82, 0.94, 1.0, 0.9), 2.0, true)
    draw_line(center + Vector2(-18.0, 0.0), center + Vector2(18.0, 0.0), Color(0.82, 0.94, 1.0, 0.34), 1.0)
    draw_line(center + Vector2(0.0, -18.0), center + Vector2(0.0, 18.0), Color(0.82, 0.94, 1.0, 0.34), 1.0)
