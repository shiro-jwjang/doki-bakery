# SNA-29: 프로토타입 플레이 가능 - TDD로 구현

## 완료 상태: ✅ COMPLETE

## 구현된 컴포넌트

### Phase 1: 씬 구조 및 인터랙션 (TDD) ✅

#### 1.1 BakeryMain 씬 완성
- ✅ `test/test_bakery_main.gd` 작성
- ✅ `scenes/bakery/BakeryMain.tscn` 업데이트 (OvenSlot, DisplaySlot 포함)
- ✅ `scripts/bakery/bakery_main.gd` 업데이트 (신호 연결)

**테스트 항목:**
- 배경 색상 확인
- 2개의 OvenSlot 확인
- 2개의 DisplaySlot 확인
- HUD 연결 확인
- 빵 제작 완료 시 진열대 자동 추가 로직 테스트

#### 1.2 OvenSlot 컴포넌트
- ✅ `test/components/test_oven_slot.gd` 작성
- ✅ `scripts/components/oven_slot.gd` 구현
- ✅ `scenes/components/OvenSlot.tscn` 생성

**기능:**
- 빵 굽기 시작 (`start_baking()`)
- 진행률 추적 (`get_progress()`)
- 완료 후 수집 (`collect_bread()`)
- ProductionManager와 연동

#### 1.3 DisplaySlot 컴포넌트
- ✅ `test/components/test_display_slot.gd` 작성
- ✅ `scripts/components/display_slot.gd` 구현
- ✅ `scenes/components/DisplaySlot.tscn` 생성

**기능:**
- 빵 표시 (`display_bread()`)
- 판매 (`sell_bread()`)
- SalesManager와 연동
- 가격 계산 (`get_sell_price()`)

### Phase 2: UI 통합 (TDD) ✅

#### 2.1 HUD 연동
- ✅ `test/ui/test_hud_integration.gd` 작성
- ✅ 기존 HUD와 GameManager 연결 확인

**테스트 항목:**
- 초기 골드 표시
- 골드 변경 시 실시간 업데이트
- 레벨 표시 및 업데이트
- 시간 표시

#### 2.2 BreadMenu
- ✅ `test/ui/test_bread_menu.gd` 작성
- ✅ `scripts/ui/bread_menu.gd` 구현
- ✅ `scenes/ui/BreadMenu.tscn` 생성

**기능:**
- 레벨별 해금 빵 목록 표시
- 빵 선택 시 제작 시작
- ProductionManager 연동
- ESC로 닫기

#### 2.3 UpgradeMenu
- ✅ `test/ui/test_upgrade_menu.gd` 작성
- ✅ `scripts/ui/upgrade_menu.gd` 구현
- ✅ `scenes/ui/UpgradeMenu.tscn` 생성

**기능:**
- 업그레이드 목록 표시
- 레벨별 비용 계산
- 구매 기능 (골드 확인)
- 최대 레벨 표시

#### 2.4 FairyMenu
- ✅ `test/ui/test_fairy_menu.gd` 작성
- ✅ `scripts/ui/fairy_menu.gd` 구현
- ✅ `scenes/ui/FairyMenu.tscn` 생성

**기능:**
- 요정 목록 표시
- 고용 비용 및 레벨 요구사항 확인
- 고용 기능
- 이미 고용된 요정 표시

### Phase 3: 게임 루프 통합 (TDD) ✅

#### 3.1 생산→판매 플로우
- ✅ `test/test_game_loop.gd` 작성

**테스트 항목:**
- ProductionManager → SalesManager → GameManager 완전 사이클
- 빵 굽기 → 인벤토리 추가 → 판매 → 골드 획득
- 여러 슬롯 동시 작동
- 다양한 빵 판매

#### 3.2 오프라인 보상
- ✅ `test/test_offline_rewards.gd` 작성

**테스트 항목:**
- SaveManager의 마지막 저장 시간 추적
- 오프라인 시간 계산
- 오프라인 보상 계산 (레벨 기반)
- 24시간 캡
- 8시간 100% 효율, 이후 50% 효율

## 테스트 결과

```
=== Test Summary ===
Passed: 28
Failed: 0

✅ All tests PASSED
```

## 완료된 기능

1. ✅ **OvenSlot**: 빵 제작 슬롯 (진행률, 완료, 수집)
2. ✅ **DisplaySlot**: 빵 진열 및 판매 슬롯
3. ✅ **BakeryMain**: 오븐과 진열대 배치된 메인 화면
4. ✅ **BreadMenu**: 빵 선택 및 제작 시작 메뉴
5. ✅ **UpgradeMenu**: 업그레이드 구매 메뉴
6. ✅ **FairyMenu**: 요정 고용 메뉴
7. ✅ **HUD 연동**: 실시간 골드/레벨 표시
8. ✅ **게임 루프**: 제작 → 판매 → 골드 흐름
9. ✅ **오프라인 보상**: 저장 시간 기반 보상

## 게임 플로우

```
1. 게임 시작
   ↓
2. 빵 선택 메뉴에서 빵 선택
   ↓
3. OvenSlot에서 제작 시작 (ProductionManager)
   ↓
4. 제작 완료 대기 (진행률 표시)
   ↓
5. 완료 시 자동으로 DisplaySlot에 추가 (SalesManager 인벤토리)
   ↓
6. 판매 버튼으로 판매
   ↓
7. 골드 획득 (GameManager 업데이트)
   ↓
8. 경험치 획득 및 레벨업 가능
   ↓
9. 새로운 빵/요정 해금
   ↓
10. 게임 저장 및 종료
    ↓
11. 재접속 시 오프라인 보상 지급
```

## 추가 작업 제안

1. **시각 효과**: 빵 제작/완료 애니메이션
2. **사운드**: 제작/판매 효과음
3. **요정 효과**: 요정 능력(제작 속도, 가격 보너스) 실제 적용
4. **업그레이드 효과**: 업그레이드 스탯 실제 적용
5. **세이브/로드**: 자동 저장, 수동 저장 UI
6. **도전 과제**: achievements.json 연동

## 파일 목록

### 컴포넌트
- `scripts/components/oven_slot.gd`
- `scenes/components/OvenSlot.tscn`
- `scripts/components/display_slot.gd`
- `scenes/components/DisplaySlot.tscn`

### UI
- `scripts/ui/bread_menu.gd`
- `scenes/ui/BreadMenu.tscn`
- `scripts/ui/upgrade_menu.gd`
- `scenes/ui/UpgradeMenu.tscn`
- `scripts/ui/fairy_menu.gd`
- `scenes/ui/FairyMenu.tscn`

### 테스트
- `test/test_bakery_main.gd`
- `test/components/test_oven_slot.gd`
- `test/components/test_display_slot.gd`
- `test/ui/test_bread_menu.gd`
- `test/ui/test_upgrade_menu.gd`
- `test/ui/test_fairy_menu.gd`
- `test/ui/test_hud_integration.gd`
- `test/test_game_loop.gd`
- `test/test_offline_rewards.gd`

### 수정된 파일
- `scenes/bakery/BakeryMain.tscn`
- `scripts/bakery/bakery_main.gd`
- `scripts/components/oven_slot.gd`
- `scripts/ui/fairy_menu.gd`
