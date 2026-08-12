# PLAN v3.15 — 커스텀 배경/카드면 (macos)

> platform: macos · 버전: 3.15.0 · 작성: 2026-08-09 · 근거: docs/RESEARCH.md §3.5 / §5 (사용자 선택 후보 4)

## 1. 개요

벤치마크(MobilityWare/Brainium/Solitaire Plus!)가 공통 제공하는 **커스텀 배경(사진 업로드) + 카드면 다변화**를 추가한다.

1. **T-180 커스텀 배경**: 사용자 사진을 배경으로 업로드. 파일 선택 → 앱 지원 폴더에 저장 → 보드/창 배경 렌더.
2. **T-181 카드 뒷면 확장**: 기존 3종(클래식/블루/골드)에 2종 추가(오션/숲).
3. **T-182 카드 앞면 스타일 확장**: 기존 2종(클래식/심플)에 2종 추가(레트로/딥).
4. **T-183 회귀 + 빌드 + 릴리스 + 문서**.

> 설정 UI는 기존 `SettingPreviewViews`(미리보기 픽커) 패턴 재사용. 배경 렌더는 `UserSettings.color(for:)`가 Color를 반환하는 구조 → 커스텀 배경은 Image 경로를 추가 분기로 처리.

## 2. 결정 사항

### 2.1 커스텀 배경 (T-180)
- **저장**: 파일을 `Application Support/Pure Solitaire/custom-background.*`로 복사(원본과 분리). `UserSettings.customBackgroundPath: String?`(@AppStorage는 경로 문자열 — 파일 이동 시 대비 `FileManager.fileExists` 가드).
- **선택**: 설정 "배경" 픽커에 **"커스텀…"** 항목 추가 → `NSOpenPanel`(이미지 필터) → 선택 즉시 복사+적용. 현재 커스텀 배경은 "배경 제거" 버튼으로 되돌리기.
- **렌더**: `BackgroundStyle.custom` 추가. `UserSettings.backgroundColor(for:)`는 커스텀인 경우 투명/기본색을 반환하고, `GameBoardView`/`ContentView`의 `.background`가 커스텀 경로 이미지면 `Image(nsImage:)` 렌더. feltTextBase는 커스텀 시 흰색 유지.
- **a11y**: 픽커 셀에 파일명 미리보기 대신 "커스텀" 라벨 + 축소된 이미지 렌더.
- **롤백**: 커스텀 배경 파일 삭제 + 설정 초기화.

### 2.2 카드 뒷면 확장 (T-181)
- `CardBack` enum에 `ocean`, `forest` 추가. `tint`/`accent`만 추가하면 `CardView.backView`/`CardBackArtwork`가 자동 반영(기존 패턴).

### 2.3 카드 앞면 확장 (T-182)
- `CardStyle` enum에 `retro`, `deep` 추가. CardView 폰트/색 파라미터를 스타일별 분기 확장.
- `CardStylePicker` 미리보기 셀에 `MiniCardFaceView` 재사용(자동).

## 3. 아키텍처

```
Sources/PureSolitaire/Persistence/UserSettings.swift
    BackgroundStyle.custom + customBackgroundPath(@AppStorage) + 커스텀 이미지 로드 헬퍼 + 카드 스타일/뒷면 케이스 추가
Sources/PureSolitaire/Views/SettingPreviewViews.swift   "커스텀…" 픽커 항목 + 이미지 미리보기
Sources/PureSolitaire/Views/SettingsView.swift         커스텀 배경 선택/제거 버튼
Sources/PureSolitaire/Views/GameBoardView.swift        배경 렌더 커스텀 이미지 분기
Sources/PureSolitaire/Views/ContentView.swift          동일 배경 렌더
Sources/PureSolitaire/Views/CardView.swift             카드 스타일 4종 분기 (레트로/딥)
```

## 4. 구현 단계

- [x] T-180: 커스텀 배경 — 저장/선택/제거/렌더(경로→Image) + feltTextBase 처리 + GameBoardView/ContentView 분기
- [x] T-181: 카드 뒷면 2종(오션/숲) tint/accent + 미리보기 자동 반영
- [x] T-182: 카드 앞면 2종(레트로/딥) CardView 스타일 분기 + 픽커 자동 반영
- [x] T-183: 회귀(178개 유지) + swift build(debug·release) 경고 0 + release 설치·실행(VERSION 3.20.0 빌드본, 창+보드 a11y 요소 렌더 확인) + 문서

## 5. 테스트 계획

- **자동**: 기존 178개 전부 통과(회귀). 표시/설정 계층 — GameCore 무변경.
- **수동 (일괄, v3.15~v3.19 마지막에)**: 
  - 커스텀 배경 선택/제거/재시작 유지, 카드 뒷면 5종, 카드 앞면 4종 렌더 확인.

## 6. 롤백 계획
- `git revert`. 커스텀 배경 파일은 Application Support에서 삭제로 복구. 저장 구조는 경로 문자열 + enum 케이스 추가 — 기존 데이터 무손상.
- 커스텀 경로 파일이 사라졌을 때 폴백(기본 그린) 처리 필수.

## 7. 성능/영향
- 커스텀 배경 이미지는 렌더 시 NSImage 로드(선택 시 1회, 캐시). 보드 크기 스케일 안에서 평탄화 — 메모리 영향 미미.
- GameCore/저장 구조 무변경.