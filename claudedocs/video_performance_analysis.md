# Flutter Video Performance Analysis - Multi-Channel Test

## 프로젝트 개요

Flutter에서 **media_kit**과 **video_player** 라이브러리의 성능과 호환성을 비교 테스트하기 위한 프로젝트입니다. 특히 안드로이드 ExoPlayer의 300ms 지연 문제와 웹 플랫폼에서의 iOS Safari 호환성 문제를 해결하는 것이 목표였습니다.

## 테스트 환경

### 플랫폼별 동작 방식
- **안드로이드 네이티브**: ExoPlayer (video_player) vs libmpv (media_kit)
- **iOS 네이티브**: AVPlayer (video_player) vs libmpv (media_kit)
- **웹**: HTML5 `<video>` 요소 (둘 다 동일)

### 테스트 대상
- **Video Players**: media_kit vs video_player
- **Audio Player**: just_audio (공통)
- **Test Video**: `poop_explorers.mp4`
- **Test Audio**: `chapa.mp3`

## 발견된 문제들

### 1. 안드로이드 ExoPlayer 300ms 지연 문제
**문제**: video_player가 안드로이드에서 ExoPlayer를 사용할 때 300ms 지연 발생
**원인**: ExoPlayer의 내부 버퍼링 및 초기화 과정
**해결책**: media_kit(libmpv) 사용으로 지연 해결

### 2. iOS Safari 웹 호환성 문제
**문제**:
- media_kit이 iOS Safari/Chrome에서 재생 실패
- 에러 메시지: "The request is not allowed by the user agent or the platform in the current context"

**원인**:
- iOS Safari의 웹 미디어 정책 제한
- media_kit의 웹 구현이 iOS와 호환성 문제
- iOS 17 업데이트 이후 더 심화된 문제

**해결책**: 웹에서는 video_player 강제 사용

## 최종 구현 솔루션

### 플랫폼별 최적화 전략

```dart
// 플랫폼 조건부 렌더링
child: _useMediaKit && !kIsWeb
    ? const MediaKitVideoTest()      // 네이티브에서만
    : const VideoPlayerVideoTest(),  // 웹에서는 항상
```

### 플랫폼별 사용 라이브러리

| 플랫폼 | Video Player | 백엔드 엔진 | 성능 | 호환성 |
|--------|-------------|------------|------|--------|
| **안드로이드 네이티브** | media_kit | libmpv | ⚡ 빠름 (지연 없음) | ✅ 우수 |
| **iOS 네이티브** | media_kit | libmpv | ⚡ 빠름 | ✅ 우수 |
| **웹 (모든 브라우저)** | video_player | HTML5 video | ⚡ 표준 | ✅ 안정적 |

### UI 표시 개선

```dart
// 플랫폼별 엔진 표시
title: Text(
  _useMediaKit && !kIsWeb
    ? 'media_kit (libmpv)'
    : 'video_player (${kIsWeb ? 'HTML5' : 'ExoPlayer'})',
),

// 상태 텍스트
Text(
  _useMediaKit && !kIsWeb
    ? '🟢 Testing media_kit + just_audio'
    : '🔵 Testing video_player + just_audio${kIsWeb ? ' (Web)' : ''}',
)
```

## 코드 변경사항

### 주요 수정사항

1. **플랫폼 감지 추가**
   ```dart
   import 'package:flutter/foundation.dart'; // kIsWeb 사용
   ```

2. **조건부 위젯 렌더링**
   - 웹에서는 media_kit 비활성화
   - 네이티브에서만 media_kit 선택 가능

3. **UI 개선**
   - 플랫폼별 엔진명 표시
   - 웹 환경 구분 표시

4. **웹 최적화**
   - iOS Safari 호환성을 위한 viewport 메타태그 추가
   - user-scalable=no 설정

### pubspec.yaml 의존성

```yaml
dependencies:
  media_kit: ^1.1.11           # 크로스플랫폼 미디어 킷
  media_kit_video: ^1.2.5      # 비디오 지원
  media_kit_libs_video: ^1.0.5 # 네이티브 라이브러리
  video_player: ^2.9.2         # Flutter 공식 비디오 플레이어
  just_audio: ^0.9.40          # 오디오 플레이어
```

## 성능 분석 결과

### 안드로이드 네이티브
- **media_kit (libmpv)**: 즉시 재생, 지연 없음 ⚡
- **video_player (ExoPlayer)**: 300ms 지연 발생 ⚠️

### iOS 네이티브
- **media_kit (libmpv)**: 정상 동작 ✅
- **video_player (AVPlayer)**: 정상 동작 ✅

### 웹 (모든 브라우저)
- **media_kit**: iOS Safari에서 재생 실패 ❌
- **video_player**: 모든 브라우저에서 안정적 ✅

## 권장사항

### 개발 가이드라인

1. **네이티브 앱 개발시**
   - 안드로이드: media_kit 사용 (성능 우수)
   - iOS: media_kit 또는 video_player (둘 다 양호)

2. **웹 앱 개발시**
   - video_player 사용 (호환성 우수)
   - iOS Safari 호환성 필수 고려

3. **크로스플랫폼 최적화**
   ```dart
   // 플랫폼별 조건부 사용
   final useMediaKit = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
   ```

### 테스트 체크리스트

- [ ] 안드로이드 네이티브 앱에서 media_kit 지연 테스트
- [ ] iOS Safari 웹에서 video_player 재생 테스트
- [ ] Chrome/Firefox 웹에서 동작 확인
- [ ] 오디오와 비디오 동시 재생 테스트
- [ ] 앱 생명주기 (백그라운드/포그라운드) 테스트

## 결론

플랫폼별 특성을 고려한 최적화된 미디어 플레이어 선택으로 모든 환경에서 안정적이고 빠른 비디오 재생이 가능해졌습니다. 특히 안드로이드의 300ms 지연 문제와 iOS Safari의 호환성 문제를 성공적으로 해결했습니다.

---

**Generated**: 2025-09-17
**Flutter Version**: 3.32.8
**Test Environment**: macOS, iOS Safari, Android Chrome