extends GutTest

## E2E-02: 빵 생산 & 판매 루프
## 핵심 게임 루프 테스트

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

	# 기본 빵 해금
	SaveManager.current_save.unlocked_breads.append("white_bread")
	SaveManager.current_save.unlocked_breads.append("croissant")


# ========================================
# 생산 테스트
# ========================================


func test_start_baking_white_bread():
	# 식빵 생산 시작
	ProductionManager.start_baking(0, "white_bread")

	assert_true(ProductionManager.active_baking.has(0), "Slot 0 should be active")
	assert_eq(
		ProductionManager.active_baking[0].bread_id, "white_bread", "Should be baking white bread"
	)


func test_white_bread_production_time():
	# 식빵 기본 생산 시간 (5초)
	var duration = ProductionManager.calculate_production_time("white_bread", "")
	assert_eq(duration, 5.0, "White bread should take 5 seconds")


func test_croissant_production_time():
	# 크로와상 기본 생산 시간 (5초)
	var duration = ProductionManager.calculate_production_time("croissant", "")
	assert_eq(duration, 5.0, "Croissant should take 5 seconds")


func test_cannot_use_same_slot_twice():
	# 슬롯 0에 식빵
	ProductionManager.start_baking(0, "white_bread")

	# 같은 슬롯에 크로와상 시도
	ProductionManager.start_baking(0, "croissant")

	# 여전히 식빵이어야 함
	assert_eq(
		ProductionManager.active_baking[0].bread_id,
		"white_bread",
		"Should still be baking white bread"
	)
	assert_eq(ProductionManager.active_baking.size(), 1, "Should have only one active baking")


func test_multiple_slots_simultaneous():
	# 슬롯 0: 식빵
	ProductionManager.start_baking(0, "white_bread")

	# 슬롯 1: 크로와상
	ProductionManager.start_baking(1, "croissant")

	assert_eq(ProductionManager.active_baking.size(), 2, "Should have 2 active bakings")
	assert_true(ProductionManager.active_baking.has(0), "Slot 0 active")
	assert_true(ProductionManager.active_baking.has(1), "Slot 1 active")


func test_is_slot_free():
	# 초기 상태
	assert_true(ProductionManager.is_slot_free(0), "Slot 0 should be free initially")

	# 생산 시작
	ProductionManager.start_baking(0, "white_bread")
	assert_false(ProductionManager.is_slot_free(0), "Slot 0 should not be free while baking")


# ========================================
# 판매 테스트
# ========================================


func test_add_bread_to_inventory():
	# 인벤토리에 빵 추가
	SalesManager.add_bread_to_inventory("white_bread")

	assert_true(SalesManager.inventory.has("white_bread"), "Inventory should have white_bread")
	assert_eq(SalesManager.inventory["white_bread"], 1, "Should have 1 white_bread")


func test_add_multiple_breads():
	# 여러 개 추가
	SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.add_bread_to_inventory("white_bread")

	assert_eq(SalesManager.inventory["white_bread"], 3, "Should have 3 white_breads")


func test_sell_bread_removes_from_inventory():
	# 빵 추가 후 판매
	SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.sell_bread("white_bread", 1)

	assert_eq(SalesManager.inventory["white_bread"], 0, "Should have 0 white_breads after selling")


func test_sell_bread_adds_gold():
	# 빵 판매로 골드 획득
	SalesManager.add_bread_to_inventory("white_bread")
	var gold_before = SalesManager.get_total_gold()

	SalesManager.sell_bread("white_bread", 1)

	# 식빵 가격: 10 * 2.5 + 5 = 30
	assert_eq(
		SalesManager.get_total_gold(), gold_before + 30, "Should gain 30 gold from white bread"
	)


func test_sell_multiple_breads():
	# 여러 개 판매
	SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.add_bread_to_inventory("white_bread")

	SalesManager.sell_bread("white_bread", 2)

	assert_eq(SalesManager.get_total_gold(), 60, "Should gain 60 gold from 2 white breads")


func test_cannot_sell_more_than_owned():
	# 1개만 보유
	SalesManager.add_bread_to_inventory("white_bread")

	# 5개 판매 시도
	SalesManager.sell_bread("white_bread", 5)

	# 판매 실패, 골드 변화 없음
	assert_eq(SalesManager.inventory["white_bread"], 1, "Should still have 1 bread")
	assert_eq(SalesManager.get_total_gold(), 0, "Should have 0 gold (sale failed)")


func test_different_breads_different_prices():
	# 각 빵의 가격 계산
	var white_bread_price = SalesManager.calculate_sell_price("white_bread")
	var croissant_price = SalesManager.calculate_sell_price("croissant")

	# 크로와상이 더 비싸야 함
	assert_gt(croissant_price, white_bread_price, "Croissant should cost more than white bread")


# ========================================
# 생산 → 판매 플로우
# ========================================


func test_full_production_sales_cycle():
	# 1. 생산 시작
	ProductionManager.start_baking(0, "white_bread")

	# 2. 생산 완료 시뮬레이션 (인벤토리에 추가)
	SalesManager.add_bread_to_inventory("white_bread")

	# 3. 판매
	var gold_before = SalesManager.get_total_gold()
	SalesManager.sell_bread("white_bread", 1)

	# 4. 골드 획득 확인
	assert_eq(SalesManager.get_total_gold(), gold_before + 30, "Full cycle: gold gained")


func test_multiple_cycles():
	# 5번의 생산-판매 사이클
	for i in range(5):
		SalesManager.add_bread_to_inventory("white_bread")
		SalesManager.sell_bread("white_bread", 1)

	assert_eq(SalesManager.get_total_gold(), 150, "5 cycles should give 150 gold")


func test_mixed_bread_sales():
	# 식빵 3개 + 크로와상 2개
	for i in range(3):
		SalesManager.add_bread_to_inventory("white_bread")
	for i in range(2):
		SalesManager.add_bread_to_inventory("croissant")

	SalesManager.sell_bread("white_bread", 3)
	SalesManager.sell_bread("croissant", 2)

	# 식빵: 30 * 3 = 90
	# 크로와상: 47.5 * 2 = 95
	var total = SalesManager.get_total_gold()
	assert_gt(total, 180, "Should have at least 180 gold")
	assert_lt(total, 200, "Should have less than 200 gold")


# ========================================
# 신호(Signal) 테스트
# ========================================


func test_baking_started_signal():
	watch_signals(ProductionManager)
	ProductionManager.start_baking(0, "white_bread")

	assert_signal_emitted(ProductionManager, "baking_started", "Should emit baking_started signal")


func test_inventory_updated_signal():
	watch_signals(SalesManager)
	SalesManager.add_bread_to_inventory("white_bread")

	assert_signal_emitted(SalesManager, "inventory_updated", "Should emit inventory_updated signal")


func test_bread_sold_signal():
	watch_signals(SalesManager)
	SalesManager.add_bread_to_inventory("white_bread")
	SalesManager.sell_bread("white_bread", 1)

	assert_signal_emitted(SalesManager, "bread_sold", "Should emit bread_sold signal")


# ========================================
# 엣지 케이스
# ========================================


func test_sell_with_empty_inventory():
	# 인벤토리 없이 판매 시도
	SalesManager.sell_bread("white_bread", 1)

	assert_eq(SalesManager.get_total_gold(), 0, "Should have 0 gold (nothing to sell)")


func test_sell_unknown_bread():
	# 존재하지 않는 빵 판매 시도
	SalesManager.sell_bread("unknown_bread", 1)

	assert_eq(SalesManager.get_total_gold(), 0, "Should have 0 gold (unknown bread)")


func test_production_with_all_slots_filled():
	# 모든 슬롯 사용
	ProductionManager.start_baking(0, "white_bread")
	ProductionManager.start_baking(1, "croissant")

	# 추가 슬롯 없음
	assert_eq(ProductionManager.active_baking.size(), 2, "All slots filled")
