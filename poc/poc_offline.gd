extends Node

## PoC 3: 오프라인 보상 타이머 검증
## 확인 항목:
##   - 세이브 시 타임스탬프 저장
##   - 로드 시 경과 시간 계산 및 보상 정산
##   - 시스템 시간 조작 방지 (음수 diff 처리)
##   - 최대 누적 상한 (24시간 캡)

const SAVE_PATH := "user://poc_offline_save.json"
const GOLD_PER_SECOND := 2.0  # 초당 골드
const MAX_OFFLINE_SECONDS := 86400.0  # 최대 24시간 인정

@onready var label_gold: Label = $UI/VBox/LabelGold
@onready var label_last_save: Label = $UI/VBox/LabelLastSave
@onready var label_offline: Label = $UI/VBox/LabelOffline
@onready var label_realtime: Label = $UI/VBox/LabelRealtime

var gold: float = 0.0
var last_save_timestamp: int = 0
var session_start_time: int = 0


func _ready() -> void:
	session_start_time = Time.get_unix_time_from_system()
	_load_and_calc_offline_reward()
	_update_ui()


func _process(_delta: float) -> void:
	# 실시간 골드 누적 표시 (세션 중)
	var elapsed := Time.get_unix_time_from_system() - session_start_time
	var realtime_gold := gold + elapsed * GOLD_PER_SECOND
	label_realtime.text = "현재 골드 (실시간): %.0f" % realtime_gold
	label_last_save.text = "마지막 세이브: %s" % _format_time(last_save_timestamp)


func _load_and_calc_offline_reward() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		label_offline.text = "저장 데이터 없음 (첫 실행)"
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()

	gold = float(data.get("gold", 0))
	last_save_timestamp = int(data.get("timestamp", 0))

	var now := Time.get_unix_time_from_system()
	var diff := now - last_save_timestamp

	# 시간 조작 방지: 음수 diff 무시
	if diff < 0:
		label_offline.text = "⚠️ 시스템 시간 이상 감지 — 오프라인 보상 미지급"
		return

	# 최대 상한 적용
	var capped_diff := minf(diff, MAX_OFFLINE_SECONDS)
	var reward := capped_diff * GOLD_PER_SECOND

	gold += reward

	var capped := diff > MAX_OFFLINE_SECONDS
	label_offline.text = (
		"오프라인 경과: %s%s\n보상 골드: +%.0f%s"
		% [
			_format_duration(diff),
			" (24h 상한 적용됨)" if capped else "",
			reward,
			" (상한 초과분 무시)" if capped else ""
		]
	)


func _on_btn_save_pressed() -> void:
	var now := Time.get_unix_time_from_system()
	var elapsed := now - session_start_time
	var current_gold := gold + elapsed * GOLD_PER_SECOND

	var data := {"gold": current_gold, "timestamp": now}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

	gold = current_gold
	session_start_time = now
	label_offline.text = "✅ 세이브 완료"
	_update_ui()


func _on_btn_reset_pressed() -> void:
	gold = 0.0
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	label_offline.text = "리셋 완료"
	_update_ui()


func _update_ui() -> void:
	label_gold.text = "저장된 골드: %.0f" % gold


func _format_time(unix: int) -> String:
	if unix == 0:
		return "없음"
	var dt := Time.get_datetime_dict_from_unix_time(unix)
	return "%02d:%02d:%02d" % [dt["hour"], dt["minute"], dt["second"]]


func _format_duration(seconds: float) -> String:
	var h := int(seconds) / 3600
	var m := (int(seconds) % 3600) / 60
	var s := int(seconds) % 60
	return "%d시간 %d분 %d초" % [h, m, s]
