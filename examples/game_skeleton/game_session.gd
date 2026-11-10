## 장면 사이에 넘기는 라운드 결과와 저장된 진행 기록을 다룬다. Autoload를 추가하지 않는다.
extends RefCounted

## 이 예제의 위치. game/으로 복사할 때 함께 바꾼다.
const ROOT := "res://examples/game_skeleton"
const SAVE_KEY := "skeleton"
static var last_score := 0
static var last_was_best := false

## 예제 폴더 안의 장면 경로를 만든다.
static func scene(file: String) -> String:
	return ROOT + "/" + file

## 저장된 최고 점수. JSON 숫자는 float로 읽히므로 int로 변환한다.
static func best_score() -> int:
	return int(_progress().get("best_score", 0))

## 저장된 누적 플레이 횟수.
static func rounds_played() -> int:
	return int(_progress().get("rounds_played", 0))

## 라운드 결과를 기록하고 즉시 저장한다. 저장 실패 시 오류 코드를 반환한다.
static func finish_round(score: int) -> Error:
	last_score = score
	last_was_best = score > best_score()
	SaveManager.set_value(SAVE_KEY, {
		"best_score": maxi(score, best_score()),
		"rounds_played": rounds_played() + 1,
	})
	return SaveManager.flush()

static func _progress() -> Dictionary:
	var stored: Variant = SaveManager.data.get(SAVE_KEY)
	return stored if stored is Dictionary else {}
