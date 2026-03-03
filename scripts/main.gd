extends Node2D

## Main 게임 씬

@onready var hud: CanvasLayer = $HUD
@onready var ui_layer: CanvasLayer = $UILayer
@onready var fairy_menu: Control = $UILayer/FairyMenu
@onready var upgrade_menu: Control = $UILayer/UpgradeMenu

var fairy_btn: Button = null
var upgrade_btn: Button = null


func _ready() -> void:
	# Sidebar 버튼은 UILayer 아래에서 찾기
	var sidebar = ui_layer.get_node_or_null("Sidebar")
	if sidebar:
		fairy_btn = sidebar.get_node_or_null("FairyBtn")
		upgrade_btn = sidebar.get_node_or_null("UpgradeBtn")

		if fairy_btn:
			fairy_btn.pressed.connect(_on_fairy_btn_pressed)
		if upgrade_btn:
			upgrade_btn.pressed.connect(_on_upgrade_btn_pressed)

	# 메뉴 닫기 신호 연결
	if fairy_menu and fairy_menu.has_signal("close_requested"):
		fairy_menu.close_requested.connect(_close_all_menus)
	if upgrade_menu and upgrade_menu.has_signal("close_requested"):
		upgrade_menu.close_requested.connect(_close_all_menus)

	# HUD 초기화
	call_deferred("_init_hud")


func _init_hud() -> void:
	if hud and hud.has_method("_initialize_hud"):
		hud._initialize_hud()


func _on_fairy_btn_pressed() -> void:
	_close_all_menus()
	fairy_menu.show()


func _on_upgrade_btn_pressed() -> void:
	_close_all_menus()
	upgrade_menu.show()


func _close_all_menus() -> void:
	if fairy_menu:
		fairy_menu.hide()
	if upgrade_menu:
		upgrade_menu.hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close_all_menus()
