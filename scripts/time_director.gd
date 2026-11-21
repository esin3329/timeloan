extends Node
## 시간 대출 경제를 게임 월드에 적용하는 감독(autoload).
##
##  - 매 프레임 "실시간 delta"로 코어 경제를 갱신한다
##  - 그 결과로 나온 타임스케일을 Engine.time_scale 에 반영한다
##  - 게임시간 delta(= 실시간 delta × 타임스케일)로 예약 입력 큐를 진행한다
##
## 입력과 시간의 분리가 이 게임 구현의 핵심이다.

signal mode_changed(mode: int, forced: bool)

const KEY_BORROW: int = KEY_SHIFT
const KEY_REPAY: int = KEY_R
const KEY_QUEUE: int = KEY_Q

var core: TimeLoanCore = TimeLoanCore.new()
var locked_until_game_time: float = -1.0   # 데모: 상환 중 입력 잠김 표현용

func _process(delta: float) -> void:
	var want_borrow: bool = Input.is_key_pressed(KEY_BORROW)
	var want_repay: bool = Input.is_key_pressed(KEY_REPAY)
	var prev_mode: int = core.mode

	core.update(delta, want_borrow, want_repay)
	Engine.time_scale = core.timescale()

	# 게임시간으로 예약 입력 진행 (타임스케일이 커도 큐는 게임시간 기준으로 흐른다)
	InputQueue.advance(delta * Engine.time_scale)

	if core.mode != prev_mode:
		mode_changed.emit(core.mode, core.forced)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_QUEUE and core.can_queue_input():
			# 프로토타입: Q 한 번에 "0.5 게임초 뒤 대시"를 예약
			InputQueue.queue_action("dash", 0.5)

func current_mode_name() -> String:
	match core.mode:
		TimeLoanCore.Mode.BORROW:
			return "BORROW"
		TimeLoanCore.Mode.REPAY:
			return "REPAY(강제)" if core.forced else "REPAY"
	return "NORMAL"
