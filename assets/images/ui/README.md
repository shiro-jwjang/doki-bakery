# UI 아이콘 사용 가이드

## 파일 목록

| 파일 | 크기 | 용도 | 원본 |
|------|------|------|------|
| `gold.png` | 16×16 | 골드 표시 | Kenney ★ |
| `level.png` | 16×16 | 레벨 표시 | Kenney ★ |
| `crown.png` | 16×16 | 경험치 표시 | Kenney ★ (임시) |
| `close.png` | 16×16 | 팝업 닫기 | Kenney X |
| `hired.png` | 16×16 | 고용됨 뱃지 | Kenney ✓ |
| `locked.png` | 16×16 | 잠금 뱃지 | Kenney 🔒 |

## Godot 설정

### TextureRect (아이콘 표시)

```gdscript
@onready var gold_icon = $GoldIcon

func _ready():
    gold_icon.texture = preload("res://assets/images/ui/gold.png")
    gold_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # 픽셀 깨짐 방지
    gold_icon.stretch_mode = TextureRect.STRETCH_SCALE
    gold_icon.scale = Vector2(4, 4)  # 16×16 → 64×64
```

### 또는 씬에서 직접 설정

```
TextureRect:
  ├── texture = "res://assets/images/ui/gold.png"
  ├── texture_filter = 0 (NEAREST)
  ├── stretch_mode = 4 (SCALE)
  └── scale = Vector2(4, 4)
```

## 9-slice 버튼 (Kenney Large tiles)

### 위치

```
assets/kenney-ui-pixel/Tiles/Large tiles/Thick outline/
```

### Godot NinePatchRect 설정

```gdscript
@onready var button = $Button

func _ready():
    button.texture = preload("res://assets/kenney-ui-pixel/Tiles/Large tiles/Thick outline/tile_0000.png")
    button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

    # 9-slice 영역 설정 (32×32 타일 기준)
    button.patch_margin_left = 4
    button.patch_margin_right = 4
    button.patch_margin_top = 4
    button.patch_margin_bottom = 4
```

## 추천 버튼 타일

| 타일 | 용도 |
|------|------|
| `tile_0004.png` ~ `tile_0006.png` | 갈색 버튼 (기본/호버/눌림) |
| `tile_0013.png` ~ `tile_0015.png` | 회색 버튼 (기본/호버/눌림) |

## 라이선스

- **Kenney UI Pack**: CC0 (Public Domain) — 상업적 사용 가능
- **출처**: <https://kenney.nl/assets/ui-pack-pixel-adventure>
