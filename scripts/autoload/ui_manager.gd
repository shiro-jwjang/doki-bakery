extends Node

## UI 매니저 - 화면 전환, 모달 관리

signal screen_changed(screen_name: String)

var _current_screen: Control = null
var _screen_stack: Array[Control] = []

@onready var _fade_rect: ColorRect


func _ready() -> void:
	if "--check-only" in OS.get_cmdline_args() or "--script-check" in OS.get_cmdline_args():
		return

	# 페이드 효과용 ColorRect 생성
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a = 0.0
	_fade_rect.anchor_right = 1.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.z_index = 1000


func change_screen(screen_scene: PackedScene, fade: bool = true) -> void:
	var new_screen = screen_scene.instantiate()

	if fade:
		await _fade_out()

	if _current_screen:
		_current_screen.queue_free()

	_current_screen = new_screen
	get_tree().root.add_child(new_screen)

	screen_changed.emit(new_screen.name)

	if fade:
		await _fade_in()


func push_screen(screen_scene: PackedScene, fade: bool = true) -> void:
	if _current_screen:
		_screen_stack.append(_current_screen)
		_current_screen.hide()

	var new_screen = screen_scene.instantiate()

	if fade:
		await _fade_out()

	_current_screen = new_screen
	get_tree().root.add_child(new_screen)

	screen_changed.emit(new_screen.name)

	if fade:
		await _fade_in()


func pop_screen(fade: bool = true) -> void:
	if _screen_stack.is_empty():
		return

	if fade:
		await _fade_out()

	if _current_screen:
		_current_screen.queue_free()

	_current_screen = _screen_stack.pop_back()
	_current_screen.show()

	screen_changed.emit(_current_screen.name)

	if fade:
		await _fade_in()


func show_modal(modal_scene: PackedScene) -> Control:
	var modal = modal_scene.instantiate()
	get_tree().root.add_child(modal)
	return modal


func close_modal(modal: Control) -> void:
	modal.queue_free()


func _fade_out(duration: float = 0.2) -> void:
	var tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, duration)
	await tween.finished


func _fade_in(duration: float = 0.2) -> void:
	var tween = create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, duration)
	await tween.finished
