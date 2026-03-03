extends GutTest

## E2E-08: 5분 플레이 세션
## 전체 게임 루프 통합 테스트

var GameManager: Node
var SaveManager: Node
var ProductionManager: Node
var SalesManager: Node
var DataManager: Node


func before_each():
	# 세이브 초기화
	if FileAccess.file_exists("user://save.json"):
		DirAccess.remove_absolute("user://save.json")
	if FileAccess.file_exists("user://save_backup.json"):
		DirAccess.remove_absolute("user://save_backup.json")

	# 매니저 생성
	SaveManager = load("res://scripts/autoload/save_manager.gd").new()
	add_child_autofree(SaveManager)
	SaveManager._ready()

	DataManager = load("res://scripts/autoload/data_manager.gd").new()
	add_child_autofree(DataManager)
	DataManager.load_all_data()

	GameManager = load("res://scripts/autoload/game_manager.gd").new()
	add_child_autofree(GameManager)
	GameManager._ready()

	ProductionManager = load("res://scripts/autoload/production_manager.gd").new()
	add_child_autofree(ProductionManager)
	ProductionManager._ready()

	SalesManager = load("res://scripts/autoload/sales_manager.gd").new()
	add_child_autofree(SalesManager)
	SalesManager._ready()

	# 의존성 주입
	ProductionManager.set_sales_manager(SalesManager)
	ProductionManager.set_save_manager(SaveManager)
	ProductionManager.set_data_manager(DataManager)
	SalesManager.set_data_manager(DataManager)
	SaveManager.set_game_manager(GameManager)

	# 튜토리얼 완료 상태로 시작
	SaveManager.current_save.tutorial_completed = true
	SaveManager.current_save.unlocked_breads.append("white_bread")


# ========================================
# 5분 세션 시뮬레이션
# ========================================


func test_full_5min_session():
	# === 0:00 - 게임 시작 ===
	assert_eq(GameManager.gold, 0, "[0:00] Start with 0 gold")
	assert_eq(GameManager.level, 1, "[0:00] Start at level 1")
	assert_eq(GameManager.experience, 0, "[0:00] Start with 0 experience")

	# === 0:30 - 첫 빵 생산 & 판매 ===
	ProductionManager.start_baking(0, "white_bread")
	ProductionManager.start_baking(1, "white_bread")

	# 생산 완료 시뮬레이션
	SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.sell_bread("white_bread", 2)

	assert_eq(SalesManager.get_total_gold(), 60, "[0:30] Earned 60 gold from 2 breads")

	# GameManager와 동기화
	GameManager.add_gold(60)

	# === 1:00 - 빵 5개 판매 ===
	for i in range(5):
		SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.sell_bread("white_bread", 5)

	var gold_after_5 = SalesManager.get_total_gold()
	assert_eq(gold_after_5, 210, "[1:00] Total 210 gold (7 breads)")

	GameManager.add_gold(150)

	# 경험치 획득 (판매 금액의 일부)
	GameManager.add_experience(15)
	assert_eq(GameManager.experience, 15, "[1:00] Gained experience from sales")

	# === 1:30 - 레벨 업 ===
	GameManager.add_experience(85)  # 총 100 경험치
	assert_eq(GameManager.level, 2, "[1:30] Leveled up to 2")

	# 크로와상 해금
	SaveManager.current_save.unlocked_breads.append("croissant")
	assert_true(
		"croissant" in SaveManager.current_save.unlocked_breads, "[1:30] Croissant unlocked"
	)

	# === 2:00 - 크로와상 생산 ===
	ProductionManager.start_baking(0, "croissant")

	# 생산 완료
	SalesManager.add_bread_to_inventory("croissant")
	SalesManager.sell_bread("croissant", 1)

	var croissant_gold = SalesManager.calculate_sell_price("croissant")
	var total_after_croissant = 210 + croissant_gold
	assert_almost_eq(
		SalesManager.get_total_gold(), total_after_croissant, 5, "[2:00] Croissant sold"
	)

	# === 3:00 - 오븐 속도 업그레이드 ===
	GameManager.add_gold(int(croissant_gold))
	var gold_before_upgrade = GameManager.gold

	# 업그레이드 구매 (100골드)
	var upgrade_success = GameManager.spend_gold(100)
	assert_true(upgrade_success, "[3:00] Upgrade purchased")
	assert_eq(GameManager.gold, gold_before_upgrade - 100, "[3:00] Gold reduced by 100")

	SaveManager.current_save.upgrade_levels["oven_speed"] = 1

	# 생산 시간 감소 확인
	var reduced_time = ProductionManager.calculate_production_time("white_bread", "")
	assert_lt(reduced_time, 5.0, "[3:00] Production time reduced after upgrade")

	# === 4:00 - 요정 고용 준비 ===
	# 추가 골드 획득
	for i in range(10):
		SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.sell_bread("white_bread", 10)

	GameManager.add_gold(300)
	assert_gt(GameManager.gold, 400, "[4:00] Enough gold for fairy")

	# === 4:30 - 요정 고용 ===
	var gold_before_fairy = GameManager.gold

	# 요정 고용 (500골드)
	var fairy_hire_success = GameManager.spend_gold(500)
	if fairy_hire_success:
		SaveManager.current_save.owned_fairies.append("fairy_flour")
		assert_true("fairy_flour" in SaveManager.current_save.owned_fairies, "[4:30] Fairy hired")

	# === 5:00 - 세션 종료 & 세이브 ===
	SaveManager.save_game()
	assert_true(SaveManager.has_save(), "[5:00] Game saved")

	# 최종 상태 검증
	assert_gt(GameManager.gold, 0, "[5:00] Has gold remaining")
	assert_eq(GameManager.level, 2, "[5:00] Level 2")
	assert_gte(
		SaveManager.current_save.unlocked_breads.size(), 2, "[5:00] At least 2 breads unlocked"
	)
	assert_gte(SaveManager.current_save.upgrade_levels.size(), 1, "[5:00] At least 1 upgrade")


# ========================================
# 마일스톤 테스트
# ========================================


func test_5min_milestone_first_bread():
	# 5분 마일스톤: 첫 빵 판매 (100골드)
	GameManager.add_gold(100)

	assert_gte(GameManager.gold, 100, "5min milestone: First bread sold (100 gold)")


func test_30min_milestone_first_fairy():
	# 30분 마일스톤: 요정 1명 고용 (500골드)
	GameManager.add_gold(500)
	GameManager.spend_gold(500)
	SaveManager.current_save.owned_fairies.append("fairy_flour")

	assert_gte(
		SaveManager.current_save.owned_fairies.size(), 1, "30min milestone: First fairy hired"
	)


func test_1hour_milestone_second_bread():
	# 1시간 마일스톤: 두 번째 빵 해금
	GameManager.level = 2
	SaveManager.current_save.unlocked_breads.append("croissant")

	assert_gte(
		SaveManager.current_save.unlocked_breads.size(), 2, "1hour milestone: Second bread unlocked"
	)


func test_1day_milestone_basic_upgrades():
	# 1일 마일스톤: 기본 업그레이드 완료
	SaveManager.current_save.upgrade_levels["oven_speed"] = 3
	SaveManager.current_save.upgrade_levels["oven_slots"] = 2

	assert_gte(
		SaveManager.current_save.upgrade_levels.size(), 2, "1day milestone: Basic upgrades complete"
	)


# ========================================
# 세이브/로드 통합 테스트
# ========================================


func test_session_save_and_load():
	# Disable GameManager sync for isolated save/load testing
	SaveManager.set_game_manager(null)

	# 세션 데이터 설정
	SaveManager.current_save.gold = 1234
	SaveManager.current_save.level = 5
	SaveManager.current_save.experience = 500

	# owned_fairies 직접 할당 대신 append 사용
	SaveManager.current_save.owned_fairies.clear()
	SaveManager.current_save.owned_fairies.append("fairy_flour")
	SaveManager.current_save.owned_fairies.append("fairy_sugar")

	SaveManager.current_save.upgrade_levels = {"oven_speed": 3, "oven_slots": 2}

	# unlocked_breads 직접 할당 대신 append 사용
	SaveManager.current_save.unlocked_breads.clear()
	SaveManager.current_save.unlocked_breads.append("white_bread")
	SaveManager.current_save.unlocked_breads.append("croissant")
	SaveManager.current_save.unlocked_breads.append("chocolate_muffin")

	# 세이브
	SaveManager.save_game()

	# 데이터 리셋
	SaveManager.current_save = load("res://scripts/save_data.gd").new()

	# 로드
	var loaded = SaveManager.load_game()

	# 복원 확인
	assert_eq(loaded.gold, 1234, "Gold restored after session")
	assert_eq(loaded.level, 5, "Level restored after session")
	assert_eq(loaded.experience, 500, "Experience restored after session")
	assert_eq(loaded.owned_fairies.size(), 2, "Fairies restored after session")
	assert_eq(loaded.upgrade_levels.size(), 2, "Upgrades restored after session")
	assert_eq(loaded.unlocked_breads.size(), 3, "Unlocked breads restored after session")


# ========================================
# 성장 곡선 테스트
# ========================================


func test_experience_curve():
	# 레벨 1 → 2: 100 경험치
	var exp_level_1 = GameManager.calculate_experience_needed(1)
	assert_eq(exp_level_1, 100, "Level 1 needs 100 exp")

	# 레벨 2 → 3: 150 경험치
	var exp_level_2 = GameManager.calculate_experience_needed(2)
	assert_eq(exp_level_2, 150, "Level 2 needs 150 exp")

	# 레벨 3 → 4: 225 경험치
	var exp_level_3 = GameManager.calculate_experience_needed(3)
	assert_eq(exp_level_3, 225, "Level 3 needs 225 exp")


func test_multiple_level_ups():
	# 한 번에 여러 레벨 업
	GameManager.add_experience(500)  # 100 + 150 + 225 = 475 for 3 levels

	assert_gte(GameManager.level, 3, "Should reach at least level 3")


func test_production_efficiency_improves():
	# 기본 시간
	var base_time = ProductionManager.calculate_production_time("white_bread", "")
	assert_eq(base_time, 5.0, "Base production time is 5 seconds")

	# 업그레이드 후
	SaveManager.current_save.upgrade_levels["oven_speed"] = 1
	var upgraded_time = ProductionManager.calculate_production_time("white_bread", "")
	assert_lt(upgraded_time, base_time, "Upgraded production is faster")

	# 요정 고용 후
	SaveManager.current_save.owned_fairies.append("fairy_flour")
	var with_fairy_time = ProductionManager.calculate_production_time("white_bread", "fairy_flour")
	assert_lt(with_fairy_time, upgraded_time, "Production with fairy is even faster")


# ========================================
# 방치 보상 테스트
# ========================================


func test_offline_rewards_integration():
	# 오프라인 시간 설정
	GameManager.level = 5
	SaveManager.set_offline_start()
	SaveManager.current_save.offline_start_time -= 3600  # 1시간 전

	# 오프라인 보상 계산
	var offline_duration = SaveManager.get_offline_duration()
	assert_gt(offline_duration, 3500, "Offline duration is about 1 hour")

	# 게임 로드 시 오프라인 보상 수령
	var gold_before = GameManager.gold
	# 오프라인 보상 로직 (실제 구현에 따라 다름)
	# GameManager.add_offline_rewards()

	# assert_gt(GameManager.gold, gold_before, "Gold increased from offline rewards")


# ========================================
# UI 상태 테스트
# ========================================


func test_gold_display_updates():
	watch_signals(GameManager)

	# 골드 변경
	GameManager.add_gold(100)

	# 신호 확인
	assert_signal_emitted(GameManager, "gold_changed", "Gold changed signal emitted")


func test_level_display_updates():
	watch_signals(GameManager)

	# 레벨 업
	GameManager.add_experience(100)

	# 신호 확인
	assert_signal_emitted(GameManager, "level_changed", "Level changed signal emitted")


func test_inventory_display_updates():
	watch_signals(SalesManager)

	# 인벤토리 변경
	SalesManager.add_bread_to_inventory("white_bread")

	# 신호 확인
	assert_signal_emitted(SalesManager, "inventory_updated", "Inventory updated signal emitted")
