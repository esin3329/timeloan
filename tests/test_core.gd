extends SceneTree
## 헤드리스 회계 검증. 실행:
##   ~/bin/godot --headless --path ~/timeloan -s res://tests/test_core.gd

var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	test_borrow_consumes_gauge()
	test_forced_repay_at_floor()
	test_interest_is_ten_percent()
	test_forced_penalty_worse_than_voluntary()
	test_input_blocked_during_repay()

	print("")
	print("통과 %d / %d" % [checks - failures, checks])
	quit(1 if failures > 0 else 0)

func _check(cond: bool, label: String, detail: String = "") -> void:
	checks += 1
	if cond:
		print("  ✓ %s" % label)
	else:
		failures += 1
		print("  ✗ %s %s" % [label, detail])

func _near(a: float, b: float, eps: float = 0.02) -> bool:
	return absf(a - b) <= eps

func test_borrow_consumes_gauge() -> void:
	print("[1] Borrow는 실시간 1초당 게이지 1.0을 소모한다")
	var c := TimeLoanCore.new()
	c.update(1.0, true, false)
	_check(_near(c.t, 5.0), "1초 대출 후 t=5.0", "실제 t=%.3f" % c.t)
	_check(c.mode == TimeLoanCore.Mode.BORROW and _near(c.timescale(), 0.25),
			"BORROW 모드, 타임스케일 0.25")

func test_forced_repay_at_floor() -> void:
	print("[2] 게이지가 바닥(-4.0)에 닿으면 강제 상환이 발동한다")
	var c := TimeLoanCore.new()
	for i in range(200):
		c.update(0.05, true, false)
		if c.forced:
			break
	_check(c.forced and c.mode == TimeLoanCore.Mode.REPAY, "강제 상환 진입")
	_check(c.forced_count == 1, "강제 상환 1회 기록")
	# 강제 상환은 FORCED_EXIT_T(=1.0)까지 회복해야 풀린다
	for i in range(400):
		c.update(0.05, false, false)
		if not c.forced:
			break
	_check(not c.forced and c.t >= TimeLoanCore.FORCED_EXIT_T - 0.02,
			"t>=1.0 회복 후에만 해제", "실제 t=%.3f" % c.t)

func test_interest_is_ten_percent() -> void:
	print("[3] 자발 상환의 이자는 10% (회복률 0.9)")
	var c := TimeLoanCore.new()
	c.reset()
	c.t = 0.0
	c.mode = TimeLoanCore.Mode.REPAY
	c.forced = false
	for i in range(20):          # 1.0초(0.05×20) 상환
		if c.mode != TimeLoanCore.Mode.REPAY:
			break
		c.update(0.05, false, true)
	_check(_near(c.t, 0.9), "1초 상환 시 게이지 +0.9", "실제 t=%.3f" % c.t)
	_check(_near(c.interest_total, 0.1), "이자 0.1 누적", "실제 %.3f" % c.interest_total)

func test_forced_penalty_worse_than_voluntary() -> void:
	print("[4] 강제 상환(0.6)이 자발 상환(0.9)보다 불리하다")
	_check(TimeLoanCore.FORCED_RATE < TimeLoanCore.REPAY_RATE, "회복률 비교")
	var voluntary := TimeLoanCore.new()
	voluntary.t = -4.0
	voluntary.forced = false
	voluntary.mode = TimeLoanCore.Mode.REPAY
	var forced_core := TimeLoanCore.new()
	forced_core.t = -4.0
	forced_core.forced = true
	forced_core.mode = TimeLoanCore.Mode.REPAY
	var v_t: float = voluntary.t
	var f_t: float = forced_core.t
	for i in range(10):          # 같은 0.5초
		voluntary.update(0.05, false, true)
		forced_core.update(0.05, false, false)
	_check(forced_core.t - f_t < voluntary.t - v_t, "같은 시간에 강제 상환이 덜 회복")

func test_input_blocked_during_repay() -> void:
	print("[5] 상환 구간에서는 실시간 입력을 받지 않는다")
	var c := TimeLoanCore.new()
	c.update(0.1, true, false)
	_check(c.can_queue_input(), "BORROW 중: 입력 가능")
	c.mode = TimeLoanCore.Mode.REPAY
	_check(not c.can_queue_input(), "REPAY 중: 입력 차단")
