extends GutTest

## E2E-01: 첫 실행 & 튜토리얼
## 프로토타입의 첫 번째 E2E 테스트 시나리오

var GameManager: Node
var SaveManager: Node
var ProductionManager: Node


func before_each():
	# 세이브 파일 초기화
	if FileAccess.file_exists("user://save.json"):
		DirAccess.remove_absolute("user://save.json")
	if FileAccess.file_exists("user://save_backup.json"):
		DirAccess.remove_absolute("user://save_backup.json")

	# 매니저 생성
	SaveManager = load("res://scripts/autoload/save_manager.gd").new()
	add_child_autofree(SaveManager)
	SaveManager._ready()

	GameManager = load("res://scripts/autoload/game_manager.gd").new()
	add_child_autofree(GameManager)
	GameManager._ready()

	var DataManager = load("res://scripts/autoload/data_manager.gd").new()
	add_child_autofree(DataManager)
	DataManager.load_all_data()

	ProductionManager = load("res://scripts/autoload/production_manager.gd").new()
	add_child_autofree(ProductionManager)
	ProductionManager._ready()


# ========================================
# E2E-01: 첫 실행 테스트
# ========================================


func test_first_launch_has_no_save():
	# 세이브 파일 삭제 후 확인
	if FileAccess.file_exists("user://save.json"):
		DirAccess.remove_absolute("user://save.json")

	assert_false(SaveManager.has_save(), "Should have no save file on first launch")


func test_initial_game_state():
	# 초기 골드
	assert_eq(GameManager.gold, 0, "Should start with 0 gold")

	# 초기 레벨
	assert_eq(GameManager.level, 1, "Should start at level 1")

	# 초기 경험치
	assert_eq(GameManager.experience, 0, "Should start with 0 experience")


func test_initial_production_slots():
	# 기본 오븐 슬롯
	assert_eq(ProductionManager.max_slots, 2, "Should start with 2 oven slots")

	# 빈 활성 생산
	assert_eq(ProductionManager.active_baking.size(), 0, "Should have no active baking")


func test_initial_unlocked_breads():
	# 기본 해금된 빵
	var unlocked = SaveManager.current_save.unlocked_breads
	assert_eq(unlocked.size(), 0, "Should start with no unlocked breads (tutorial not complete)")


func test_initial_owned_fairies():
	# 고용한 요정 없음
	var fairies = SaveManager.current_save.owned_fairies
	assert_eq(fairies.size(), 0, "Should start with no owned fairies")


func test_initial_upgrade_levels():
	# 업그레이드 없음
	var upgrades = SaveManager.current_save.upgrade_levels
	assert_eq(upgrades.size(), 0, "Should start with no upgrades")


# ========================================
# 튜토리얼 완료 후 상태
# ========================================


func test_after_tutorial_first_bread_unlocked():
	# 튜토리얼 완료 시 첫 빵 해금
	SaveManager.current_save.unlocked_breads.append("white_bread")
	SaveManager.current_save.tutorial_completed = true
	SaveManager.save_game()

	var loaded = SaveManager.load_game()
	assert_true(
		"white_bread" in loaded.unlocked_breads, "White bread should be unlocked after tutorial"
	)
	assert_true(loaded.tutorial_completed, "Tutorial should be marked as completed")


func test_after_tutorial_can_start_baking():
	# 튜토리얼 후 생산 가능
	SaveManager.current_save.unlocked_breads.append("white_bread")

	# 생산 시작
	ProductionManager.start_baking(0, "white_bread")

	assert_true(
		ProductionManager.active_baking.has(0), "Should be able to start baking after tutorial"
	)
	assert_eq(ProductionManager.active_baking[0].bread_id, "white_bread", "Baking white bread")


func test_first_save_creates_file():
	# 첫 세이브
	SaveManager.save_game()

	assert_true(FileAccess.file_exists("user://save.json"), "First save should create save file")
	assert_true(
		FileAccess.file_exists("user://save_backup.json"), "First save should create backup"
	)


func test_first_save_preserves_tutorial_state():
	# 튜토리얼 완료 상태 저장
	SaveManager.current_save.tutorial_completed = true
	SaveManager.current_save.unlocked_breads.append("white_bread")
	SaveManager.save_game()

	# 리셋 후 로드
	SaveManager.current_save = load("res://scripts/save_data.gd").new()
	var loaded = SaveManager.load_game()

	assert_true(loaded.tutorial_completed, "Tutorial state should persist")
	assert_true("white_bread" in loaded.unlocked_breads, "Unlocked bread should persist")
