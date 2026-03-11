extends Button

@export var hover_scale := 1.05
@export var pressed_scale := 0.95
@export var animation_duration := 0.08

var _scale_tween: Tween
var _is_hovered := false
var _is_pressed := false

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	resized.connect(_update_pivot_offset)
	_update_pivot_offset()

func _on_mouse_entered() -> void:
	_is_hovered = true
	_animate_to_current_state()

func _on_mouse_exited() -> void:
	_is_hovered = false
	_is_pressed = false
	_animate_to_current_state()

func _on_button_down() -> void:
	_is_pressed = true
	_animate_to_current_state()

func _on_button_up() -> void:
	_is_pressed = false
	_animate_to_current_state()

func _update_pivot_offset() -> void:
	pivot_offset = size * 0.5

func _animate_to_current_state() -> void:
	var target_scale := Vector2.ONE
	if _is_pressed:
		target_scale = Vector2(pressed_scale, pressed_scale)
	elif _is_hovered:
		target_scale = Vector2(hover_scale, hover_scale)

	if _scale_tween != null:
		_scale_tween.kill()
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", target_scale, animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
