extends Node2D

## PoC 2: 쿼터뷰 Y-Sort (깊이 정렬) 검증
## 확인 항목:
##   - 캐릭터가 오브젝트 앞/뒤를 지날 때 자연스러운 깊이 정렬
##   - WASD로 캐릭터 이동
##   - 오브젝트(진열대 역할)를 지나칠 때 정렬 전환 확인

const SPEED := 120.0

# 캐릭터 노드
@onready var character: ColorRect = $YSortRoot/Character
@onready var label_pos: Label = $UI/LabelPos

# 오브젝트들 (진열대/가구 역할)
@onready var ysort_root: Node2D = $YSortRoot


func _ready() -> void:
	# Y-Sort 활성화
	ysort_root.y_sort_enabled = true

	var hint := $UI/LabelHint
	hint.text = "WASD / 방향키로 이동\n캐릭터(파랑)가 오브젝트(갈색) 앞뒤를 지날 때\nY-Sort 정렬 확인"


func _process(delta: float) -> void:
	var dir := Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1

	if dir != Vector2.ZERO:
		character.position += dir.normalized() * SPEED * delta

	label_pos.text = "캐릭터 위치: (%.0f, %.0f)" % [character.position.x, character.position.y]
