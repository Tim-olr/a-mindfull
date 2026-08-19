extends Node

## Persisted player-facing settings (screen shake, display, fps, brightness).
## Autoloaded as GameSettings. Values are applied immediately when changed
## and written to user://settings.cfg so they survive between runs.

signal changed

const CONFIG_PATH := "user://settings.cfg"
const FPS_OPTIONS: Array[int] = [30, 60, 120, 144, 240, 0] ## 0 = uncapped
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

var screen_shake_intensity: float = 1.0
var brightness: float = 1.0
var fps_limit: int = 0
var fullscreen: bool = true
var window_size: Vector2i = Vector2i(1920, 1080)

func _ready() -> void:
	_load()
	# The project boots windowed (see project.godot) and this applies the
	# real starting mode a frame later. Doing it immediately, before the
	# initial windowed setup has actually settled, is what left fullscreen/
	# resize toggles unable to take effect afterwards.
	await get_tree().process_frame
	_apply_window()
	_apply_fps()
	changed.emit()

func set_screen_shake_intensity(value: float) -> void:
	screen_shake_intensity = clampf(value, 0.0, 2.0)
	_save()
	changed.emit()

func set_brightness(value: float) -> void:
	brightness = clampf(value, 0.4, 1.8)
	_save()
	changed.emit()

func set_fps_limit(value: int) -> void:
	fps_limit = value
	_apply_fps()
	_save()
	changed.emit()

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_window()
	_save()
	changed.emit()

func set_window_size(size: Vector2i) -> void:
	window_size = size
	_apply_window()
	_save()
	changed.emit()

func _apply_fps() -> void:
	Engine.max_fps = fps_limit

## Uses the Window node API rather than raw DisplayServer calls, and waits a
## frame after switching mode before touching size/position - going straight
## from EXCLUSIVE_FULLSCREEN (or setting mode+size+position in the same
## frame) is unreliable on Windows and silently no-ops the resize.
func _apply_window() -> void:
	var window := get_window()
	if fullscreen:
		window.mode = Window.MODE_FULLSCREEN
		return
	window.mode = Window.MODE_WINDOWED
	await get_tree().process_frame
	window.size = window_size
	var screen_size := DisplayServer.screen_get_size()
	window.position = (screen_size - window_size) / 2

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "window_width", window_size.x)
	cfg.set_value("display", "window_height", window_size.y)
	cfg.set_value("display", "fps_limit", fps_limit)
	cfg.set_value("display", "brightness", brightness)
	cfg.set_value("gameplay", "screen_shake_intensity", screen_shake_intensity)
	cfg.save(CONFIG_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	fullscreen = cfg.get_value("display", "fullscreen", fullscreen)
	window_size = Vector2i(
		int(cfg.get_value("display", "window_width", window_size.x)),
		int(cfg.get_value("display", "window_height", window_size.y))
	)
	fps_limit = cfg.get_value("display", "fps_limit", fps_limit)
	brightness = cfg.get_value("display", "brightness", brightness)
	screen_shake_intensity = cfg.get_value("gameplay", "screen_shake_intensity", screen_shake_intensity)
