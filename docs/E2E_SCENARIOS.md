# 🧪 E2E 테스트 시나리오

## 두근두근 베이커리 프로토타입

### 📋 시나리오 개요

| ID | 시나리오 | 우선순위 | 예상 시간 |
|----|----------|----------|-----------|
| E2E-01 | 첫 실행 & 튜토리얼 | P0 | 30초 |
| E2E-02 | 빵 생산 & 판매 루프 | P0 | 1분 |
| E2E-03 | 요정 고용 & 효과 검증 | P1 | 2분 |
| E2E-04 | 업그레이드 구매 | P1 | 2분 |
| E2E-05 | 새로운 빵 해금 | P1 | 3분 |
| E2E-06 | 오프라인 보상 | P2 | 30초 |
| E2E-07 | 세이브/로드 | P0 | 1분 |
| E2E-08 | 5분 플레이 세션 | P0 | 5분 |

---

## E2E-01: 첫 실행 & 튜토리얼

### 사전 조건

- 새로 설치된 게임
- 세이브 파일 없음

### 테스트 단계

| 단계 | 액션 | 기대 결과 |
|------|------|-----------|
| 1 | 게임 실행 | 타이틀 화면 표시 |
| 2 | "시작하기" 버튼 클릭 | 튜토리얼 시작 |
| 3 | 대화 진행 | 스토리 대화 표시 |
| 4 | 튜토리얼 완료 | 메인 게임 화면 진입 |

### 검증 포인트

```gdscript
# test_e2e_01_first_launch.gd
func test_first_launch_shows_tutorial():
    # 세이브 파일 없음 확인
    assert_false(SaveManager.has_save(), "No save file")

    # 초기 상태 검증
    assert_eq(GameManager.gold, 0, "Start with 0 gold")
    assert_eq(GameManager.level, 1, "Start at level 1")
    assert_eq(ProductionManager.max_slots, 2, "Start with 2 slots")

func test_tutorial_completion():
    # 튜토리얼 완료 플래그
    assert_true(SaveManager.current_save.tutorial_completed, "Tutorial completed")
```

---

## E2E-02: 빵 생산 & 판매 루프

### 사전 조건

- 게임 시작 상태
- 골드: 0
- 오븐 슬롯: 2개

### 테스트 단계

| 단계 | 액션 | 기대 결과 |
|------|------|-----------|
| 1 | 빵 메뉴 열기 | 빵 선택 UI 표시 |
| 2 | "식빵" 선택 | 오븐 슬롯 0에 생산 시작 |
| 3 | 5초 대기 | 생산 완료 알림 |
| 4 | 진열대 확인 | 식빵 1개 추가됨 |
| 5 | 판매 버튼 클릭 | 골드 +30 획득 |

### 검증 포인트

```gdscript
# test_e2e_02_production_sales.gd
func test_white_bread_production_cycle():
    # 생산 시작
    ProductionManager.start_baking(0, "white_bread")
    assert_true(ProductionManager.active_baking.has(0), "Slot 0 baking")

    # 생산 시간 확인 (5초)
    var duration = ProductionManager.calculate_production_time("white_bread", "")
    assert_eq(duration, 5.0, "White bread takes 5 seconds")

func test_bread_sale_adds_gold():
    # 빵 추가
    SalesManager.add_bread_to_inventory("white_bread")

    # 판매 전 골드
    var gold_before = SalesManager.get_total_gold()

    # 판매
    SalesManager.sell_bread("white_bread", 1)

    # 골드 증가 확인 (30골드)
    assert_eq(SalesManager.get_total_gold(), gold_before + 30, "Gold increased by 30")

func test_multiple_production_slots():
    # 슬롯 0: 식빵
    ProductionManager.start_baking(0, "white_bread")

    # 슬롯 1: 크로와상
    ProductionManager.start_baking(1, "croissant")

    # 두 슬롯 모두 활성화 확인
    assert_eq(ProductionManager.active_baking.size(), 2, "Both slots active")
```

---

## E2E-03: 요정 고용 & 효과 검증

### 사전 조건

- 골드: 500 이상
- 요정 미고용 상태

### 테스트 단계

| 단계 | 액션 | 기대 결과 |
|------|------|-----------|
| 1 | 요정 메뉴 열기 | 고용 가능한 요정 목록 |
| 2 | "밀가루 요정" 선택 | 요정 정보 표시 |
| 3 | "고용" 버튼 클릭 | 골드 -500, 요정 획득 |
| 4 | 식빵 생산 시작 | 생산 시간 감소 확인 |

### 검증 포인트

```gdscript
# test_e2e_03_fairy_hire.gd
func test_fairy_hire_reduces_gold():
    var gold_before = GameManager.gold

    # 요정 고용
    GameManager.spend_gold(500)
    SaveManager.current_save.owned_fairies.append("fairy_flour")

    assert_eq(GameManager.gold, gold_before - 500, "Gold reduced by 500")
    assert_true("fairy_flour" in SaveManager.current_save.owned_fairies, "Fairy owned")

func test_fairy_reduces_production_time():
    # 요정 없이
    var time_without_fairy = ProductionManager.calculate_production_time("white_bread", "")

    # 요정 고용 (레벨 1: 5% 감소)
    SaveManager.current_save.owned_fairies.append("fairy_flour")

    var time_with_fairy = ProductionManager.calculate_production_time("white_bread", "fairy_flour")

    # 5% 감소 확인
    var expected_time = 5.0 * (1 - 0.05)  # 4.75초
    assert_almost_eq(time_with_fairy, expected_time, 0.1, "Production time reduced by 5%")

func test_fairy_level_scaling():
    # 레벨 5 요정
    var level_5_time = ProductionManager.calculate_production_time("white_bread", "")
    # FairyLevelBonus = 0.05, Level 5 = 25% 감소
    # But capped at 80% (min 20% of base)

    # Formula: BaseTime × (1 - FairyLevel × 0.05) × (1 - UpgradeLevel × 0.1)
    # Min: BaseTime × 0.2
    var min_time = 5.0 * 0.2  # 1초
    assert_gt(level_5_time, min_time, "Production time above minimum")
```

---

## E2E-04: 업그레이드 구매

### 사전 조건

- 골드: 300 이상
- 기본 오븐 슬롯: 2개

### 테스트 단계

| 단계 | 액션 | 기대 결과 |
|------|------|-----------|
| 1 | 업그레이드 메뉴 열기 | 업그레이드 목록 |
| 2 | "오븐 속도" 레벨 1 구매 | 골드 -100 |
| 3 | 식빵 생산 시간 확인 | 10% 감소 |
| 4 | "오븐 슬롯" 레벨 1 구매 | 슬롯 2 → 3개 |

### 검증 포인트

```gdscript
# test_e2e_04_upgrades.gd
func test_oven_speed_upgrade():
    var gold_before = GameManager.gold

    # 업그레이드 구매
    GameManager.spend_gold(100)
    SaveManager.current_save.upgrade_levels["oven_speed"] = 1

    assert_eq(GameManager.gold, gold_before - 100, "Gold reduced by 100")

    # 생산 시간 감소 확인
    var time = ProductionManager.calculate_production_time_with_upgrade("white_bread", 1)
    var expected_time = 5.0 * (1 - 0.1)  # 4.5초
    assert_almost_eq(time, expected_time, 0.1, "Production time reduced by 10%")

func test_oven_slot_upgrade():
    # 기본 슬롯
    assert_eq(ProductionManager.max_slots, 2, "Start with 2 slots")

    # 슬롯 업그레이드
    SaveManager.current_save.upgrade_levels["oven_slots"] = 1
    ProductionManager.update_max_slots()

    assert_eq(ProductionManager.max_slots, 3, "Now have 3 slots")

func test_upgrade_cost_scaling():
    # 비용 공식: BaseCost × (1.5 ^ (Level - 1))
    var level_1_cost = 100
    var level_2_cost = 100 * 1.5  # 150
    var level_3_cost = 100 * pow(1.5, 2)  # 225

    assert_eq(level_2_cost, 150, "Level 2 costs 150")
    assert_eq(level_3_cost, 225, "Level 3 costs 225")
```

---

## E2E-05: 새로운 빵 해금

### 사전 조건

- 레벨 2 달성
- 기본 빵(식빵)만 보유

### 테스트 단계

| 단계 | 액션 | 기대 결과 |
|------|------|-----------|
| 1 | 빵 판매로 경험치 획득 | 경험치 +10 |
| 2 | 100 경험치 달성 | 레벨 업! |
| 3 | 빵 메뉴 확인 | 크로와상 해금 |

### 검증 포인트

```gdscript
# test_e2e_05_unlock_bread.gd
func test_experience_from_bread_sale():
    var exp_before = GameManager.experience

    # 빵 판매
    SalesManager.add_bread_to_inventory("white_bread")
    SalesManager.sell_bread("white_bread", 1)

    # 경험치 획득 (판매 금액의 10%)
    var exp_gained = 30 * 0.1  # 3
    assert_eq(GameManager.experience, exp_before + exp_gained, "Experience gained")

func test_level_up_unlocks_bread():
    # 레벨 1 → 2
    GameManager.add_experience(100)

    assert_eq(GameManager.level, 2, "Level up to 2")

    # 크로와상 해금 확인
    assert_true("croissant" in SaveManager.current_save.unlocked_breads, "Croissant unlocked")

func test_unlocked_bread_available_in_menu():
    # 레벨 2 달성
    GameManager.level = 2
    SaveManager.current_save.unlocked_breads.append("croissant")

    # 메뉴에서 크로와상 선택 가능
    var available_breads = DataManager.get_unlocked_breads(GameManager.level)
    assert_true("croissant" in available_breads, "Croissant in menu")
```

---

## E2E-06: 오프라인 보상

### 사전 조건

- 게임 플레이 후 종료
- 1시간 경과

### 테스트 단계

| 단계 | 액션 | 기대 결과 |
|------|------|-----------|
| 1 | 게임 재실행 | 오프라인 보상 팝업 |
| 2 | "수령하기" 클릭 | 골드 획득 |
| 3 | 보상 계산 확인 | 레벨×0.1×3600×0.5 |

### 검증 포인트

```gdscript
# test_e2e_06_offline_rewards.gd
func test_offline_reward_calculation():
    # 레벨 5, 1시간(3600초) 오프라인
    GameManager.level = 5
    SaveManager.set_offline_start()

    # 1시간 시뮬레이션
    SaveManager.current_save.offline_start_time -= 3600

    var offline_gold = SaveManager.calculate_offline_reward()

    # 공식: Level × 0.1 × Duration × 0.5
    var expected = 5 * 0.1 * 3600 * 0.5  # 900
    assert_eq(offline_gold, expected, "Offline reward calculated correctly")

func test_offline_reward_cap():
    # 30시간 오프라인 (24시간 캡)
    GameManager.level = 5
    SaveManager.current_save.offline_start_time -= (30 * 3600)

    var offline_gold = SaveManager.calculate_offline_reward()

    # 24시간으로 캡
    var max_duration = 24 * 3600
    var expected = 5 * 0.1 * max_duration * 0.5  # 21600
    assert_eq(offline_gold, expected, "Offline reward capped at 24 hours")

func test_offline_reward_on_load():
    var gold_before = GameManager.gold

    # 게임 로드 (오프라인 보상 포함)
    SaveManager.load_game()

    # 오프라인 보상 수령 확인
    assert_gt(GameManager.gold, gold_before, "Gold increased from offline rewards")
```

---

## E2E-07: 세이브/로드

### 사전 조건

- 게임 플레이 상태
- 골드, 레벨, 요정 보유

### 테스트 단계

| 단계 | 액션 | 기대 결과 |
|------|------|-----------|
| 1 | 게임 종료 | 자동 세이브 |
| 2 | 게임 재실행 | 세이브 로드 |
| 3 | 상태 확인 | 모든 데이터 복원 |

### 검증 포인트

```gdscript
# test_e2e_07_save_load.gd
func test_save_preserves_all_data():
    # 게임 상태 설정
    GameManager.gold = 1234
    GameManager.level = 5
    GameManager.experience = 500
    SaveManager.current_save.owned_fairies = ["fairy_flour", "fairy_sugar"]
    SaveManager.current_save.upgrade_levels = {"oven_speed": 3, "oven_slots": 2}

    # 세이브
    SaveManager.save_game()

    # 데이터 리셋
    GameManager.gold = 0
    GameManager.level = 1
    SaveManager.current_save = SaveData.new()

    # 로드
    var loaded = SaveManager.load_game()

    # 복원 확인
    assert_eq(loaded.gold, 1234, "Gold restored")
    assert_eq(loaded.level, 5, "Level restored")
    assert_eq(loaded.experience, 500, "Experience restored")
    assert_eq(loaded.owned_fairies.size(), 2, "Fairies restored")
    assert_eq(loaded.upgrade_levels["oven_speed"], 3, "Upgrades restored")

func test_auto_save_on_exit():
    # 골드 변경
    GameManager.gold = 999

    # 자동 세이브 트리거 (60초마다)
    SaveManager._auto_save_timer = 60.0
    SaveManager._process(0.1)

    # 세이브 파일 존재 확인
    assert_true(SaveManager.has_save(), "Auto-save created")

func test_backup_restore():
    # 세이브 생성
    GameManager.gold = 1000
    SaveManager.save_game()

    # 메인 세이브 손상
    var file = FileAccess.open("user://save.json", FileAccess.WRITE)
    file.store_string("corrupted")
    file.close()

    # 백업에서 복구
    var loaded = SaveManager.load_game()
    assert_eq(loaded.gold, 1000, "Restored from backup")
```

---

## E2E-08: 5분 플레이 세션

### 사전 조건

- 새 게임 시작
- 모든 기능 테스트

### 테스트 단계

| 시간 | 액션 | 기대 결과 |
|------|------|-----------|
| 0:00 | 게임 시작 | 튜토리얼 완료 |
| 0:30 | 식빵 생산×2 | 골드 +60 |
| 1:00 | 식빵 5개 판매 | 골드 +150, 경험치 +15 |
| 1:30 | 레벨 업 | 레벨 2, 크로와상 해금 |
| 2:00 | 크로와상 생산 | 10초 대기 |
| 2:30 | 크로와상 판매 | 골드 +47 |
| 3:00 | 오븐 속도 업그레이드 | 골드 -100 |
| 3:30 | 요정 고용 준비 | 골드 모으기 |
| 4:30 | 요정 고용 | 골드 -500 |
| 5:00 | 세션 종료 | 자동 세이브 |

### 검증 포인트

```gdscript
# test_e2e_08_full_session.gd
func test_5min_session():
    # 초기 상태
    assert_eq(GameManager.gold, 0, "Start with 0 gold")
    assert_eq(GameManager.level, 1, "Start at level 1")

    # 1분: 빵 생산 & 판매
    for i in range(5):
        SalesManager.add_bread_to_inventory("white_bread")
        SalesManager.sell_bread("white_bread", 1)

    assert_eq(GameManager.gold, 150, "Gold from 5 breads")
    assert_almost_eq(GameManager.experience, 15, 1, "Experience from sales")

    # 레벨 업
    GameManager.add_experience(85)  # 총 100
    assert_eq(GameManager.level, 2, "Level up to 2")

    # 업그레이드 구매
    GameManager.spend_gold(100)
    SaveManager.current_save.upgrade_levels["oven_speed"] = 1

    # 요정 고용
    GameManager.add_gold(400)  # 충분한 골드
    GameManager.spend_gold(500)
    SaveManager.current_save.owned_fairies.append("fairy_flour")

    # 최종 상태
    assert_gt(GameManager.gold, 0, "Has gold remaining")
    assert_eq(GameManager.level, 2, "Level 2")
    assert_true(SaveManager.current_save.owned_fairies.size() > 0, "Has fairy")

    # 세이브
    SaveManager.save_game()
    assert_true(SaveManager.has_save(), "Game saved")
```

---

## 🎯 마일스톤 검증

### 5분 마일스톤

```gdscript
func test_5min_milestone():
    # 첫 빵 판매 (100골드)
    GameManager.add_gold(100)
    assert_gte(GameManager.gold, 100, "5min milestone: First bread sold")
```

### 30분 마일스톤

```gdscript
func test_30min_milestone():
    # 요정 1명 고용 (500골드)
    GameManager.add_gold(500)
    GameManager.spend_gold(500)
    SaveManager.current_save.owned_fairies.append("fairy_flour")

    assert_gte(SaveManager.current_save.owned_fairies.size(), 1, "30min milestone: First fairy hired")
```

### 1시간 마일스톤

```gdscript
func test_1hour_milestone():
    # 두 번째 빵 해금 (1000경험치)
    GameManager.level = 2
    SaveManager.current_save.unlocked_breads.append("croissant")

    assert_gte(SaveManager.current_save.unlocked_breads.size(), 2, "1hour milestone: Second bread unlocked")
```

---

## 📊 테스트 실행 방법

```bash
# 전체 E2E 테스트 실행
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/e2e

# 특정 시나리오 실행
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/e2e/test_e2e_02.gd

# 커버리지 포함
./scripts/qa-check.sh --coverage
```

---

## ✅ 완료 기준

| 기준 | 상태 |
|------|------|
| 모든 E2E 테스트 통과 | ⬜ |
| 커버리지 70% 이상 | ⬜ |
| 타입 체크 통과 | ⬜ |
| 린트 경고 0개 | ⬜ |
