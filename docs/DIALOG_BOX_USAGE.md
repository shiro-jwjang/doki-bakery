# DialogBox 컴포넌트 사용 가이드

## 개요

`DialogBox`는 재사용 가능한 대화창 UI 컴포넌트입니다.

## 기능

- ✅ 대화 목록 관리
- ✅ 화자 이름, 이모지, 텍스트 표시
- ✅ 클릭/스페이스바로 진행
- ✅ 건너뛰기 버튼
- ✅ 완료 시 신호 발생
- ✅ 페이드인 애니메이션

## 사용법

### 1. 씬에 추가

```gdscript
# 방법 1: 미리 씬에 배치
@onready var dialog_box: DialogBox = $DialogBox

# 방법 2: 동적 생성
var dialog_box = preload("res://scenes/ui/dialog_box.tscn").instantiate()
add_child(dialog_box)
```

### 2. 대화 설정

```gdscript
var dialogs = [
 {"speaker": "밀가루 요정", "emoji": "🧚", "text": "안녕!"},
 {"speaker": "손님", "emoji": "👧", "text": "빵 주세요!"},
 {"speaker": "나레이션", "text": "이모지 없이도 가능"},
]

dialog_box.set_dialogs(dialogs)
```

### 3. 시작

```gdscript
dialog_box.dialog_finished.connect(_on_dialog_finished)
dialog_box.start_dialogs()
```

### 4. 완료 처리

```gdscript
func _on_dialog_finished():
 print("대화 완료!")
 # 다음 로직...
```

## 설정

```gdscript
# 자동 숨김
dialog_box.auto_hide_on_finish = true  # 기본값: true

# 클릭 힌트
dialog_box.show_click_hint = true  # 기본값: true
dialog_box.click_hint_text = "계속..."

# 스킵 버튼
dialog_box.set_skip_button_visible(false)
```

## 신호

| 신호 | 설명 |
|------|------|
| `dialog_finished` | 모든 대화 완료 시 |
| `dialog_advanced(current, total)` | 대화 진행 시 |

## 메서드

| 메서드 | 설명 |
|--------|------|
| `set_dialogs(dialogs)` | 대화 목록 설정 |
| `start_dialogs(dialogs?)` | 대화 시작 |
| `advance()` | 다음 대화로 진행 |
| `finish()` | 대화 종료 |
| `add_dialog(speaker, text, emoji?)` | 대화 추가 |

## 예시

### NPC 대화

```gdscript
func talk_to_npc():
 var dialogs = [
  {"speaker": "빵집 주인", "emoji": "👨‍🍳", "text": "어서오세요!"},
  {"speaker": "빵집 주인", "emoji": "👨‍🍳", "text": "오늘은 어떤 빵을 드릴까요?"},
 ]
 dialog_box.start_dialogs(dialogs)
```

### 스토리 진행

```gdscript
func show_story_chapter_1():
 dialog_box.add_dialog("나레이션", "옛날 옛적에...", "📖")
 dialog_box.add_dialog("나레이션", "작은 베이커리가 있었습니다.", "📖")
 dialog_box.start_dialogs()
```

### 튜토리얼

```gdscript
const TUTORIAL := [
 {"speaker": "요정", "emoji": "🧚", "text": "튜토리얼 시작!"},
 {"speaker": "요정", "emoji": "🧚", "text": "빵을 만들어보세요."},
]

func _ready():
 dialog_box.start_dialogs(TUTORIAL)
```
