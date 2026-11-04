#!/usr/bin/env bash
# GodotOneStoreIap AAR를 JDK만으로 만든다. Android Gradle Plugin은 필요하지 않다.
# 출력: addons/android_services/onestore/bin/GodotOneStoreIap.aar (Git 제외, 기기 검증 전 Unverified)
#
# 필요:
#   - JDK 17 이상 (javac, jar)
#   - ANDROID_JAR: Android SDK의 platforms/android-36/android.jar
#   - GODOT_AAR: Godot 4.7.2 Android build template의 godot-lib AAR
#       (Project → Install Android Build Template 후 android/build/libs/release/godot-lib.template_release.aar)
#   - 네트워크: Maven Central에서 ONE store SDK 3개를 받아 SHA-256을 확인한다.
#     이미 받은 파일이 있으면 ONESTORE_SDK_DIR에 sdk-iap/sdk-auth/sdk-base AAR를 둔다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SRC="$ROOT/native/android/onestore_iap/src/main"
OUT="$ROOT/addons/android_services/onestore/bin/GodotOneStoreIap.aar"
MAVEN="${MAVEN_CENTRAL:-https://repo1.maven.org/maven2}"

: "${ANDROID_JAR:?Set ANDROID_JAR to <Android SDK>/platforms/android-36/android.jar}"
: "${GODOT_AAR:?Set GODOT_AAR to the Godot 4.7.2 godot-lib template AAR}"

WORK="$(mktemp -d)"
trap 'rm -rf -- "$WORK"' EXIT
SDK_DIR="${ONESTORE_SDK_DIR:-$WORK/sdk}"
mkdir -p "$SDK_DIR" "$WORK/classes" "$WORK/aar" "$WORK/jars"

# name|maven path|sha256 — DEPENDENCIES.md의 ONE store 항목과 같은 고정값이다.
SDKS=(
  "sdk-iap|com/onestorecorp/sdk/sdk-iap/21.04.00/sdk-iap-21.04.00.aar|608777efe504c99956f51f7714e528ba35bd8cc41f865681d6da353b48c437ec"
  "sdk-auth|com/onestorecorp/sdk/sdk-auth/1.2.2/sdk-auth-1.2.2.aar|410adca2d7f747a6b131e0bc0708c4fc1cb3acefc115f06c716a83246dce11ac"
  "sdk-base|com/onestorecorp/sdk/sdk-base/1.2.2/sdk-base-1.2.2.aar|3a3684727c6a6a60fe36be5b871df2f5b29dc893d0ea365defd334ba435cd12c"
)

sha256() {
  if command -v sha256sum >/dev/null; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

CLASSPATH="$ANDROID_JAR"
for entry in "${SDKS[@]}"; do
  IFS='|' read -r name path expected <<<"$entry"
  file="$SDK_DIR/$name.aar"
  if [[ ! -f "$file" ]]; then
    curl -fsSL -o "$file" "$MAVEN/$path"
  fi
  actual="$(sha256 "$file")"
  if [[ "$actual" != "$expected" ]]; then
    echo "SHA-256 mismatch for $name: $actual" >&2
    exit 1
  fi
  mkdir -p "$WORK/jars/$name"
  unzip -q -o "$file" classes.jar -d "$WORK/jars/$name"
  CLASSPATH="$CLASSPATH:$WORK/jars/$name/classes.jar"
done
mkdir -p "$WORK/jars/godot"
unzip -q -o "$GODOT_AAR" classes.jar -d "$WORK/jars/godot"
CLASSPATH="$CLASSPATH:$WORK/jars/godot/classes.jar"

# SDK·Godot 클래스는 compile classpath로만 쓰고 AAR에는 플러그인 클래스만 넣는다.
javac --release 17 -Xlint:deprecation -cp "$CLASSPATH" -d "$WORK/classes" \
  $(find "$SRC/java" -name '*.java')
jar --create --file "$WORK/aar/classes.jar" -C "$WORK/classes" .
cp "$SRC/AndroidManifest.xml" "$WORK/aar/AndroidManifest.xml"
: > "$WORK/aar/R.txt"

mkdir -p "$(dirname "$OUT")"
rm -f -- "$OUT"
(cd "$WORK/aar" && jar --create --no-manifest --file "$OUT" AndroidManifest.xml classes.jar R.txt)
echo "Built $OUT"
echo "SHA-256 $(sha256 "$OUT")"
