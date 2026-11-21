class_name TimeLoanCore
extends RefCounted
## 시간 대출 경제의 순수 로직. 씬/노드에 의존하지 않아 헤드리스 테스트가 가능하다.
##
## 규칙 요약
##  - Borrow(홀드): 타임스케일 0.25, 실시간 1초당 게이지 -1.0
##  - Repay(수동) : 타임스케일 2.5, 실시간 1초당 게이지 +0.9 (이자 10%)
##  - 강제 상환   : 게이지가 바닥에 닿으면 자동 발동, 회복률 0.6 (이자 1.5배)
##  - 정상 구간   : 타임스케일 1.0, 게이지 유지

enum Mode { NORMAL, BORROW, REPAY }

const MAX_T: float = 6.0          # 빌릴 수 있는 최대치
const FLOOR_T: float = -4.0       # 빚 한도. 여기 닿으면 강제 상환
const SLOW_SCALE: float = 0.25
const REPAY_SCALE: float = 2.5
const REPAY_RATE: float = 0.9     # 자발 상환 회복률 (= 이자 10%)
const FORCED_RATE: float = 0.6    # 강제 상환 회복률
const FORCED_EXIT_T: float = 1.0  # 강제 상환이 끝나려면 이만큼 회복해야 한다

var t: float = MAX_T
var mode: int = Mode.NORMAL
var forced: bool = false

# 지표 수집 (R3 "자발적 Repay 사용률" 등 검증용)
var borrowed_total: float = 0.0
var interest_total: float = 0.0
var forced_count: int = 0
var voluntary_repay_count: int = 0

func reset() -> void:
	t = MAX_T
	mode = Mode.NORMAL
	forced = false
	borrowed_total = 0.0
	interest_total = 0.0
	forced_count = 0
	voluntary_repay_count = 0

func is_in_debt() -> bool:
	return t < 0.0

func debt_amount() -> float:
	return maxf(0.0, -t)

func repay_rate() -> float:
	return FORCED_RATE if forced else REPAY_RATE

func timescale() -> float:
	match mode:
		Mode.BORROW:
			return SLOW_SCALE
		Mode.REPAY:
			return REPAY_SCALE
	return 1.0

func can_queue_input() -> bool:
	## 상환 구간에서는 실시간 입력이 무시된다 — 예약 입력만 실행된다.
	return mode != Mode.REPAY

func update(dt_real: float, want_borrow: bool, want_repay: bool) -> void:
	# 1) 상태 전이
	match mode:
		Mode.NORMAL:
			if want_repay and t < MAX_T:
				_begin_repay(false)
			elif want_borrow:
				mode = Mode.BORROW
		Mode.BORROW:
			if not want_borrow:
				mode = Mode.NORMAL
		_:
			pass

	# 2) 대출 소모 (버튼을 누른 첫 프레임부터 소모된다)
	if mode == Mode.BORROW and want_borrow:
		t -= dt_real
		borrowed_total += dt_real
		if t <= FLOOR_T + 0.000001:   # 부동소수점 누적 오차 허용
			t = FLOOR_T
			forced_count += 1
			_begin_repay(true)
			return

	# 3) 상환
	if mode == Mode.REPAY:
		var rate: float = repay_rate()
		t += dt_real * rate
		interest_total += dt_real * (1.0 - rate)   # 갚지 못한 차액 = 이자
		if forced:
			# 강제 상환은 플레이어 의사와 무관하게 일정량 회복까지 이어진다
			if t >= FORCED_EXIT_T:
				forced = false
				mode = Mode.NORMAL
		elif not want_repay or t >= MAX_T:
			mode = Mode.NORMAL

func _begin_repay(is_forced: bool) -> void:
	forced = is_forced
	mode = Mode.REPAY
	if not is_forced:
		voluntary_repay_count += 1
