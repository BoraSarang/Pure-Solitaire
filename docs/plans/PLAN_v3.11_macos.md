# PLAN v3.11 — 설정에 색상/패턴 미리보기 적용 (macos)

> platform: macos · 버전: 3.11.0 · 작성: 2026-08-06

## 1. 개요
설정 시트의 세 선택 옵션(카드 스타일/배경/카드 뒷면)이 현재 **텍스트만** `.segmented`로 표시된다.
기존 디자인 토큰(`BackgroundStyle.backgroundColor(for:)`, `CardBack.tint/accent`, `CardStyle`)을 활용해
각 선택지에 **실제 색·패턴 미리보기 스와치**를 표시하는 선택 UI로 교체한다. (사용자 확정: "설정에 색상/패턴 미리보기 추가")

## 2. 결정 사항
1. **범위**: 설정 시트의 3개 픽커만 교체 — 게임 화면 렌더링 로직 불변.
2. **배경(4종)**: 그린/블루/다크/화이트 실제 색 스와치 — `settings.backgroundColor(for:)` 재사용.
3. **카드 뒷면(3종)**: 클래식/블루/골드 미니 카드 뒷면 패턴 — `CardView.backView`의 패턴을 `CardBackArtwork`로 추출해 재사용(`tint`/`accent`).
4. **카드 스타일(2종)**: 클래식/심플 미니 카드 앞면 — `CardView`와 동일 색/폰트(serif/rounded) 재현.
5. **선택 UI**: 탭 가능한 미리보기 카드 행 — 선택 시 파랑 테두리 + 파랑 라벨 (v3.10 게임 선택 그리드와 동일 시맨틱), `HStack` 1행.
6. **접근성**: 각 셀 `.accessibilityLabel(옵션명)` + 선택 시 `.isSelected` 트레잇.

## 3. 아키텍처
```
PureFreeCell/Views/SettingPreviewViews.swift (신규)  CardBackArtwork + PreviewCell + MiniCardFaceView + 3종 픽커
Views/CardView.swift                                  backView → CardBackArtwork 재사용 (중복 제거)
Views/SettingsView.swift                              segmented 3개 → 미리보기 픽커 3개 교체
```

## 4. 구현 단계
- [x] T-149: `SettingPreviewViews` 신규 — `CardBackArtwork`(CardView에서 추출) + 공용 `PreviewCell` + `MiniCardFaceView` + `CardStylePicker`/`BackgroundStylePicker`/`CardBackPicker`
- [x] T-150: SettingsView 3개 `.segmented` → 미리보기 픽커 교체 (레이아웃/간격/폭 460 적합), CardView `backView` 리팩터
- [x] T-151: `swift build`(경고 0) + `swift test` 171개 + release 설치·실행(VERSION 3.11.0) + 문서(PLAN/TODO/DESIGN/CHANGELOG/테스트/세션)

## 4-1. 검증 결과 (2026-08-06)
- `swift build`(debug·release) 경고 0건, `swift test` **171개** 통과
- release 설치·실행: `~/Applications/Pure FreeCell.app` (PID 47350, VERSION 3.11.0)
- AX 덤프: 설정 시트에 **카드 스타일 2셀(클래식/심플) + 배경 4셀(그린/블루/다크/화이트) + 카드 뒷면 3셀(클래식/블루/골드)** 렌더, segmented(AXRadioGroup) 제거 확인
- 픽셀 검증: 배경 스와치(그린(41,95,55)/블루(43,88,136)/다크(34,36,43)/화이트(237,237,230)), 카드 스타일(클래식 흰색/심플 연회색), 카드 뒷면(tint 색 3종) 모두 정확
- 블루 스와치 클릭 → 보드 felt가 **블루(43,88,136)로 실시간 변경** 확인 (y=280 스트립 207개 블루), 이후 다크로 복원 (스트립 66개 다크)

## 5. 테스트 계획
- **자동**: `swift test` 171개 유지 (표시 계층만, GameCore 불변)
- **수동 (AX)**:
  - 설정 열기(`⌘,`) → 카드 스타일/배경/카드 뒷면 각각 미리보기 셀 표시 확인
  - 배경 그린 선택 → 셀 파랑 하이라이트 이동, 게임 보드 배경이 그린으로 변경
  - 카드 뒷면 골드 선택 → 게임에서 뒷면이 골드 패턴으로 표시
  - 카드 스타일 심플 선택 → 게임 카드가 심플 스타일로 변경
  - 각 선택값 재시작 후 유지 (UserDefaults)

## 6. 롤백 계획
- `git revert` — SettingsView는 기존 `.segmented` 버전으로 복구, 신규 SettingPreviewViews.swift 제거
- UserDefaults 키 불변(`settings.cardStyle`/`settings.background`/`settings.cardBackRaw`) — 데이터 무손상

## 7. 성능/영향
- 표시 계층(Views)만 변경 — GameCore/저장 불변
- 미리보기 셀 9개(2+4+3) 정적 Shape/색 — 성능 예산 영향 없음
