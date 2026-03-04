extends Control
class_name DialogBox

## 재사용 가능한 대화창 컴포넌트
##
## 사용법:
## 1. 씬에 DialogBox 인스턴스 추가
## 2. set_dialogs()로 대화 목록 설정
## 3. dialog_finished 시그널 연결
## 4. show()로 표시

signal dialog_finished
signal dialog_advanced(current_index: int, total: int)

@onready var portrait: Label = $Background/PortraitContainer/Portrait
@onready var portrait_texture: TextureRect = $Background/PortraitContainer/PortraitTexture
@onready var speaker_name: Label = $Background/SpeakerName
@onready var dialog_text: Label = $Background/DialogText
@onready var click_hint: Label = $Background/ClickHint
@onready var skip_button: Button = $SkipButton

## 대화 데이터 구조
## {"speaker": "화자", "emoji": "🧚", "text": "대화 내용"}
var _dialogs: Array = []
var _current_index := 0

## 설정
@export var auto_hide_on_finish := true
@export var show_click_hint := true
@export var click_hint_text := "클릭하여 계속..."


func _ready() -> void:
	hide()
	skip_button.pressed.connect(_on_skip_pressed)
	click_hint.text = click_hint_text
	click_hint.visible = show_click_hint


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		advance()
		get_viewport().set_input_as_handled()


## 대화 목록 설정
func set_dialogs(dialogs: Array) -> void:
	_dialogs = dialogs
	_current_index = 0
	if _dialogs.size() > 0:
		_show_current()


## 대화 시작
func start_dialogs(dialogs: Array = []) -> void:
	if dialogs.size() > 0:
		set_dialogs(dialogs)
	show()
	_current_index = 0
	if _dialogs.size() > 0:
		_show_current()


## 다음 대화로 진행
func advance() -> void:
	_current_index += 1

	if _current_index >= _dialogs.size():
		finish()
	else:
		_show_current()
		dialog_advanced.emit(_current_index, _dialogs.size())


## 대화 종료
func finish() -> void:
	dialog_finished.emit()
	if auto_hide_on_finish:
		hide()


## 현재 대화 표시
func _show_current() -> void:
	if _current_index >= _dialogs.size():
		return

	var dialog = _dialogs[_current_index]

	# 애니메이션 효과 (페이드인)
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

	# 내용 설정
	portrait.hide()
	portrait_texture.hide()

	if dialog.has("portrait_path") and ResourceLoader.exists(dialog["portrait_path"]):
		var tex = load(dialog["portrait_path"])
		if tex:
			portrait_texture.texture = tex
			# Ensure pixel art looks sharp
			portrait_texture.texture_filter = TEXTURE_FILTER_NEAREST
			portrait_texture.show()
			portrait.get_parent().show()
	elif dialog.has("emoji"):
		portrait.text = dialog["emoji"]
		portrait.show()
		portrait.get_parent().show()
	else:
		portrait.get_parent().hide()

	speaker_name.text = dialog.get("speaker", "")
	dialog_text.text = dialog.get("text", "")


## 스킵 버튼
func _on_skip_pressed() -> void:
	finish()


## 외부에서 대화 추가
func add_dialog(speaker: String, text: String, emoji: String = "") -> void:
	var dialog = {"speaker": speaker, "text": text}
	if emoji != "":
		dialog["emoji"] = emoji
	_dialogs.append(dialog)


## 클릭 힌트 표시/숨김
func set_click_hint_visible(visible: bool) -> void:
	click_hint.visible = visible


## 스킵 버튼 표시/숨김
func set_skip_button_visible(visible: bool) -> void:
	skip_button.visible = visible
