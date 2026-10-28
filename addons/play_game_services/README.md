# Play Games AAR 연결

Godot Play Game Services **v3.4.0** release의 debug/release AAR를 변경 없이 보존했다.
Source: https://github.com/godot-sdk-integrations/godot-play-game-services/releases/tag/v3.4.0
License: MIT, 함께 보존한 `LICENSE` 참고.

`plugin.gd`는 이 템플릿의 export adapter이며 upstream GDScript autoload는 포함하지 않는다.
Native dependencies (2026-10-21): `com.google.android.gms:play-services-games-v2:22.1.0`, `com.google.code.gson:gson:2.14.0`.
upstream AAR는 21.0.0 / 2.11.0 기준이며 이 템플릿의 exporter가 새 버전을 명시적으로 선택한다.
체크섬·라이선스·호환성 증거는 [DEPENDENCIES.md](../../docs/DEPENDENCIES.md), 설정은 [ANDROID_PLAY_GAMES.md](../../docs/ANDROID_PLAY_GAMES.md) 참고.
Godot 4.7.2에서 Debug/Release 기기 로딩은 통과했다. 계정 기능은 Console 설정 후 검증해야 한다.
