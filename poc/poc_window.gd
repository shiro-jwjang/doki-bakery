extends Node

## PoC 1: 항상 위 고정 + 픽셀 스케일링 검증
## 확인 항목:
##   - Always-on-Top 토글 동작
##   - 창 크기 자유 조절 시 픽셀 아트 렌더링 품질
##   - 최소 창 크기 제한

const MIN_WINDOW_SIZE := Vector2i(320, 180)

@onready var label_status: Label = $UI/VBox/LabelStatus
@onready var label_scale: Label = $UI/VBox/LabelScale
@onready var btn_always_on_top: Button = $UI/VBox/BtnAlwaysOnTop

var always_on_top: bool = false


func _ready() -> void:
	# 픽셀 아트 스케일링 설정
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	get_window().min_size = MIN_WINDOW_SIZE

	# 창 크기 변경 감지
	get_viewport().size_changed.connect(_on_size_changed)
	_update_labels()


func _on_btn_always_on_top_pressed() -> void:
	always_on_top = !always_on_top
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, always_on_top)
	_update_labels()


func _on_size_changed() -> void:
	_update_labels()


func _update_labels() -> void:
	var is_on_top := DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP)
	label_status.text = "Always-on-Top: %s" % ("ON ✅" if is_on_top else "OFF ❌")

	var win_size := DisplayServer.window_get_size()
	var base_size := Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)
	var scale_x := float(win_size.x) / float(base_size.x)
	var scale_y := float(win_size.y) / float(base_size.y)
	label_scale.text = "창 크기: %dx%d | 스케일: %.2fx %.2fy" % [win_size.x, win_size.y, scale_x, scale_y]

	btn_always_on_top.text = "Always-on-Top %s" % ("끄기" if is_on_top else "켜기")
