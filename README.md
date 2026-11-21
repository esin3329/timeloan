# 타임론 (Time Loan)

시간을 **빌려 쓰고 미래에서 갚는** 2D 퍼즐 액션 프로토타입.

- 기획: [`GDD.md`](GDD.md)
- 레벨 초안: [`design/levels.md`](design/levels.md)
- UI 와이어프레임: [`design/ui-wireframe.md`](design/ui-wireframe.md)
- 상태: 기획 단계 (구현 전)

## 조작 (예정)

| 입력 | 동작 |
|---|---|
| `Shift` 홀드 | **Borrow** — 월드가 0.25배로 느려지고 시간 게이지가 줄어든다 (빌림) |
| `R` 홀드 | **Repay** — 2.5배속으로 흐르며 빚을 갚는다. 실시간 입력은 무시됨 |
| `Q` / 클릭 | 예약 입력 배치 (Repay 구간에서 실행될 커맨드) |
| `WASD` / 방향키 | 이동 |
| `Space` | 대시 |
| 좌클릭 | 사격 |

## 개발

Godot 4.7 이상 필요.

```bash
# 코어 회계 검증 (헤드리스, 화면 없음)
godot --headless --path . -s res://tests/test_core.gd

# 에디터로 열기
godot --path . --editor
```

조작은 README 상단 표 참고. `project.godot` 에는 `TimeDirector`, `InputQueue` 두 autoload가 등록되어 있다.

| 스크립트 | 역할 |
|---|---|
| `scripts/time_loan_core.gd` | 시간 대출 경제의 순수 로직 (씬 의존 없음, 테스트 대상) |
| `scripts/time_director.gd` | 실시간 delta로 경제를 갱신하고 `Engine.time_scale` 반영 |
| `scripts/input_queue.gd` | 게임시간 기준 예약 입력 큐 (슬롯 4개) |

## 규칙 요약

> 게이지가 0 아래로 내려가면 강제 상환이 발동하고, 이자는 1.5배.
> 빚을 안고 전투에 들어갈지, 안전한 곳에서 미리 갚을지가 이 게임의 핵심 판단이다.

## 실행

Godot 4 프로젝트 스캐폴딩 예정.
