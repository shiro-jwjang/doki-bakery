extends Control
class_name TutorialScreen

## 튜토리얼 화면 - DialogBox 컴포넌트 사용

@onready var dialog_box: DialogBox = $DialogBox

# 요정 초상화 미리 로드 (웹 빌드에서 동적 로드 방지)
var _fairy_portrait: Texture2D = preload("res://assets/images/characters/fairy_flour.png")


func _ready() -> void:
	dialog_box.dialog_finished.connect(_on_tutorial_finished)

	# 대화 데이터 구성 (preload된 텍스처 사용)
	var tutorials := [
		{
			"speaker": "밀가루 요정",
			"portrait": _fairy_portrait,
			"text": "안녕! 나는 밀가루 요정이야~\n이 베이커리에 오신 것을 환영해!"
		},
		{
			"speaker": "밀가루 요정",
			"portrait": _fairy_portrait,
			"text": "여기서는 맛있는 빵을 만들어서 팔 수 있어.\n빵을 팔면 골드를 벌 수 있지!"
		},
		{
			"speaker": "밀가루 요정",
			"portrait": _fairy_portrait,
			"text": "골드를 모아서 업그레이드도 하고,\n새로운 빵도 해금할 수 있어!"
		},
		{
			"speaker": "밀가루 요정",
			"portrait": _fairy_portrait,
			"text": "그럼, 이제부터 네 차례야!\n행운을 빌어~ 🍀"
		},
	]
	dialog_box.start_dialogs(tutorials)


func _on_tutorial_finished() -> void:
	# 튜토리얼 완료 저장
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager and save_manager.has_method("set_tutorial_completed"):
		save_manager.set_tutorial_completed(true)

	# 메인 화면으로 이동
	get_tree().change_scene_to_file("res://scenes/main.tscn")
