## 제한 시간 안에 탭한 횟수를 세는 예제 규칙. 장면과 분리해 테스트한다.
extends RefCounted

const ROUND_SECONDS := 10.0
var score := 0
var time_left := ROUND_SECONDS

## 남은 시간을 줄인다. 라운드가 끝난 뒤에는 변하지 않는다.
func tick(delta: float) -> void:
	time_left = maxf(0.0, time_left - maxf(0.0, delta))

## 탭 한 번을 점수로 반영한다. 라운드가 끝났으면 false를 반환한다.
func tap() -> bool:
	if is_over():
		return false
	score += 1
	return true

## 제한 시간이 모두 지났는지 반환한다.
func is_over() -> bool:
	return time_left <= 0.0
