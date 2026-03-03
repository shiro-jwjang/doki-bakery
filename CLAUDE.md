# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**두근두근 베이커리 (Doki-Doki Bakery)** is a cozy idle bakery tycoon game built with Godot 4.3. Players bake bread, hire fairy assistants, upgrade their bakery, and progress through an idle game loop.

- **Engine**: Godot 4.3.stable
- **Language**: GDScript (with strict typing enabled)
- **Testing Framework**: GUT (Godot Unit Test) 9.3.0
- **Development Style**: Test-Driven Development (TDD)

## Essential Commands

### Running Tests

```bash
# Run all tests (headless)
godot --headless res://addons/gut/gui/GutRunner.tscn

# Run single test file (modify .gutconfig.json "tests" array)
godot --headless res://addons/gut/gui/GutRunner.tscn
```

### Code Quality

```bash
# Format code
gdformat scripts/

# Check formatting
gdformat --check scripts/

# Run linter
gdlint scripts/

# Run full QA check (format, lint, type check, tests)
./scripts/qa-check.sh

# Run with coverage report
./scripts/qa-check.sh --coverage
```

### Type Checking

```bash
# Godot type check
godot --headless --check-only
```

## Architecture

### Singleton Managers (Autoload)

The game uses a singleton architecture with these core managers (defined in `project.godot`):

- **DataManager** (`scripts/autoload/data_manager.gd`)
  - Loads JSON data from `data/` directory
  - Provides access to BreadData, FairyData, UpgradeData, IngredientData
  - Emits `data_loaded` signal when ready

- **GameManager** (`scripts/autoload/game_manager.gd`)
  - Core game state: gold, level, experience
  - Tracks totals: `total_breads_crafted`, `total_gold_earned`
  - Signals: `gold_changed`, `level_changed`, `experience_changed`
  - Provides backward compatibility aliases: `player_gold`, `player_level`

- **ProductionManager** (`scripts/autoload/production_manager.gd`)
  - Manages oven baking slots (starts with 2, max 5)
  - Handles baking timers, progress, and completion
  - Supports offline progress calculation
  - Dependency injection support for testing

- **SalesManager** (`scripts/autoload/sales_manager.gd`)
  - Inventory management (bread_id → quantity)
  - Sales logic with dynamic pricing
  - Signals: `inventory_updated`, `bread_sold`

- **SaveManager** (`scripts/autoload/save_manager.gd`)
  - JSON-based save/load system
  - Auto-saves every 60 seconds
  - Stores 3 backup saves

- **UIManager** (`scripts/autoload/ui_manager.gd`)
  - Panel management (open/close with animations)
  - Available panels: bread_menu, fairy_menu, upgrade_menu

### Data Files

All game data is stored in `data/` as JSON:

- `breads.json` - Bread recipes (id, name, tier, base_price, base_craft_time, experience)
- `fairies.json` - Fairy assistants (id, name, ability, bonus_multiplier, hire_cost)
- `upgrades.json` - Upgrades (id, name, max_level, base_cost, cost_multiplier, effects)
- `ingredients.json` - Ingredient costs
- `balance.json` - Game balance values (level curves, costs, multipliers)

### Data Classes

Resource classes in `scripts/`:

- `BreadData` - Bread recipe data
- `FairyData` - Fairy character data
- `UpgradeData` - Upgrade configuration
- `IngredientData` - Ingredient costs
- `SaveData` - Save game structure

### Dependency Injection Pattern

All singleton managers support dependency injection for testing:

```gdscript
# In production: uses autoload path
var _game_manager = null

func _get_game_manager() -> Node:
    if _game_manager:
        return _game_manager
    return get_node_or_null("/root/GameManager")

# In tests:
manager.set_game_manager(test_game_manager_instance)
```

**Critical**: Always use the `_get_*()` accessor methods, never access autoloads directly. This ensures tests can inject mock dependencies.

### Game Loop

1. **Production**: Select bread → Bake in oven slot (timer-based)
2. **Completion**: Auto-add to SalesManager inventory
3. **Display**: DisplaySlot shows inventory items
4. **Sales**: Auto-sell every 5 seconds, gain gold + experience
5. **Growth**: Level up unlocks new breads, fairy hires, upgrades

### Scene Structure

```
scenes/
├── main.tscn (bakery_main.gd) - Main gameplay scene
├── title.tscn (title.gd) - Title screen
├── tutorial.tscn (tutorial.gd) - Tutorial system
└── ui/
    ├── hud.tscn (hud.gd) - Gold, level, EXP display
    ├── bread_menu.tscn (bread_menu.gd) - Bread selection
    ├── fairy_menu.tscn (fairy_menu.gd) - Fairy management
    ├── upgrade_menu.tscn (upgrade_menu.gd) - Upgrades
    ├── production_panel.tscn (production_panel.gd) - Oven slots
    └── dialog_box.tscn (dialog_box.gd) - Tutorial dialogs
```

### Test Structure

```
test/
├── test_*.gd - Unit tests for managers
├── components/ - Component tests
├── ui/ - UI integration tests
└── e2e/ - End-to-end scenario tests
```

Test files follow GUT framework patterns:

- Extend `test.gd` or `res://addons/gut/test.gd`
- Use `before_each()` for setup
- Use `after_each()` for cleanup
- Use dependency injection for singleton mocks

## Known Issues

### Current Test Failures

1. **test_bread_menu_connects_to_production_manager** - ProductionManager baking start signal issue
2. **test_upgrade_menu_checks_gold_before_purchase** - Gold check logic needs fixing

### Risky Tests (No Assertions)

1. **test_level_up_from_bread_sales** - Needs assertion added
2. **test_bread_menu_hides_after_selection** - Needs assertion added

### Signal Warnings

Multiple "Signal already connected" warnings in UI tests - signals are being connected multiple times in rapid test execution. This is non-blocking but should be fixed by checking `is_connected()` before `connect()`.

### Script Error

`save_manager.gd:31` - Type comparison error: `Object != Dictionary`. The `_get_game_manager()` is returning null in some contexts.

## Development Notes

- **Type Safety**: `project.godot` has `typing/strict=true` - always add type hints
- **Signals**: Use `emit_signal()` for all events; avoid direct method calls between managers
- **Save System**: Save after every meaningful action (purchase, hire, complete bake)
- **TDD**: Write tests before implementing features
- **E2E Tests**: Use `test/e2e_visual/` for visual regression tests with screenshots
- **Documentation**: Update `docs/GDD.md` when changing mechanics

## Project Configuration

- **Main Scene**: `res://scenes/title.tscn`
- **Display**: 1280×720 (4× scale from 320×180 base)
- **Renderer**: GL Compatibility
- **Test Config**: `.gutconfig.json` (exit after tests, include subdirs)
