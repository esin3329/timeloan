extends Node
## 예약 입력 큐.
##
## 상환(Repay) 구간은 타임스케일이 2.5배라 실시간 반응이 불가능하다.
## 그래서 Borrow / 정상 구간에서 미래에 실행될 커맨드를 "게임시간 기준 시각"으로
## 미리 넣어두고, 상환 구간이 오면 그 큐만 순서대로 실행한다.
##
## 이 구조가 이 게임의 두 번째 레이어 — "미래의 나를 프로그래밍하기" 다.

signal  queued(action_name: String, at_game_time: float)
signal  executed(action_name: String)
signal  cleared

const MAX_SLOTS: int = 4
const ACTIONS: Array[String] = ["move", "dash", "jump", "shoot"]

var game_time: float = 0.0
var _queue: Array = []   # [{time: float, action: String}]
var _listeners: Array = []

func register_listener(callable: Callable) -> void:
	_listeners.append(callable)

func slot_count() -> int:
	return _queue.size()

func has_free_slot() -> bool:
	return _queue.size() < MAX_SLOTS

func queue_action(action: String, delay_game_seconds: float) -> bool:
	if not has_free_slot():
		return false
	if action not in ACTIONS:
		push_warning("알 수 없는 액션: %s" % action)
		return false
	_queue.append({
		"time": game_time + maxf(0.0, delay_game_seconds),
		"action": action,
	})
	_queue.sort_custom(func(a, b): return a["time"] < b["time"])
	queued.emit(action, game_time + delay_game_seconds)
	return true

func advance(dt_game: float) -> void:
	game_time += dt_game
	while _queue.size() > 0 and _queue[0]["time"] <= game_time:
		var item: Dictionary = _queue.pop_front()
		executed.emit(item["action"])
		for c in _listeners:
			if c.is_valid():
				c.call(item["action"])

func clear() -> void:
	_queue.clear()
	cleared.emit()
