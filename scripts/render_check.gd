extends Node2D
## 이 기기에서 Godot이 "실제로 화면을 그릴 수 있는지" 확인하는 렌더 체크 씬.
## Xvfb 등 X11 디스플레이가 있을 때만 의미가 있다.
##
##   godot --path . res://scenes/render_check.tscn
##
## 결과물: 프로젝트 루트의 render_check.png + FPS/메모리 출력

const OUT_PATH: String = "res://render_check.png"
const WARMUP_FRAMES: int = 30
const MEASURE_FRAMES: int = 120

var _frames: int = 0
var _elapsed: float = 0.0

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.10)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 시간 게이지를 흉내낸 막대 3개 (UI가 실제로 그려지는지 확인용)
	for i in range(3):
		var bar := ColorRect.new()
		bar.color = [Color(0.20, 0.85, 0.85), Color(0.95, 0.85, 0.25), Color(0.95, 0.30, 0.30)][i]
		bar.size = Vector2(120 + i * 60, 18)
		bar.position = Vector2(40, 40 + i * 30)
		add_child(bar)

	var label := Label.new()
	label.text = "TIMELON render check"
	label.position = Vector2(40, 170)
	label.add_theme_font_size_override("font_size", 24)
	add_child(label)

	set_process(true)

func _process(delta: float) -> void:
	_frames += 1
	if _frames == WARMUP_FRAMES + 1:
		_elapsed = 0.0
	elif _frames > WARMUP_FRAMES + 1:
		_elapsed += delta
		if _frames >= WARMUP_FRAMES + MEASURE_FRAMES:
			_finish()
		return
	if _frames == WARMUP_FRAMES:
		print("워밍업 %d프레임 완료" % WARMUP_FRAMES)

func _finish() -> void:
	set_process(false)
	var fps: float = float(MEASURE_FRAMES) / maxf(_elapsed, 0.0001)
	print("측정 프레임: %d" % MEASURE_FRAMES)
	print("평균 FPS: %.1f" % fps)
	print("메모리(static): %.1f MiB" % (OS.get_static_memory_usage() / 1048576.0))
	print("렌더 드라이버: ", ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var err: int = img.save_png(ProjectSettings.globalize_path(OUT_PATH))
	print("이미지 크기: ", img.get_size())
	print("저장: ", ProjectSettings.globalize_path(OUT_PATH), " err=", err)
	get_tree().quit(0 if err == OK else 1)
