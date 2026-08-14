# 세션 로그 2026-08-14 (macos) — v3.22.0 릴리스 (T-222~T-228)

## 1. 무엇을
- **홈 화면 (A)**: 앱 시작 시 게임 선택 화면 먼저 표시(`showingHome` 기본 true). 타이틀 헤더 + 빠른 진입(데일리 ⌥⌘D/게임 번호 ⌘G/무작위/통계·업적·설정) + 카테고리 4그룹 게임 그리드. 타일 클릭 → `requestNewGame(variant:)`. 사이드바 "홈"(⌘1) + 게임 메뉴 홈(⌘1) 복귀.
- **카테고리/난이도 정렬 (B)**: `GameVariant` 표시 전용 속성 — `GameCategory`(freeCell/stock/spider/removal) + `baseDifficulty` + `categoryOrder` + `homeOrderedVariants`. **`allCases` 순서 유지**(데일리 셔플/단건 순환 매핑 무영향).
- **난이도 매핑**: 쉬움(Golf/Scorpion) · 보통(FreeCell/Baker's/Klondike/Spider/Pyramid/TriPeaks) · 어려움(Sea Tower/Super FreeCell/Yukon/Forty Thieves).
- **게임 중 난이도 (C)**: `gameInfoView` 게임 번호 아래 뱃지(`vm.variant.baseDifficulty`) + 접근성 라벨. `GameSelectorView`도 카테고리 섹션 + 뱃지 개편.

## 2. 플랫폼
- macOS (GameCore 표시 속성 + PureSolitaire SwiftUI).

## 3. 빌드 결과 + PERF
- `swift build -c release` 경고 0(기존 ScorpionGame 제외). `swift test -c release` **253개 전부 통과**(16.7s) — 기존 249 + GameVariantDisplayTests 4개.
- `build_and_run.sh release` 설치·실행 — 창 타이틀 "Pure Solitaire"(홈 표시 확인). 이 모델은 이미지 미지원이라 스크린샷 대신 창 타이틀/a11y로 검증.

## 4. 남은 TODO
- T-228 릴리스 마무리(태그 v3.22.0 푸시 완료, Release 워크플로우 대기).

## 5. 다음 에이전트 전달 로그
- 홈/게임 전환은 VM `showingHome`(시트 플래그와 동일 패턴) — ContentView에서 `showingHome ? HomeView : SideBar+GameBoard`.
- `GameVariant.allCases` 순서를 바꾸지 말 것 — 데일리 셔플/`variant(for:)` 인덱스 매핑이 의존. 정렬은 표시 전용 속성으로만.
- 게임 중 난이도는 변형 고정값. FreeCell 실측(`Difficulty.measure`, 판당 8s)은 데일리 판별 목록에만 사용.
- 테스트는 반드시 `swift test -c release`.

## 6. 문서 업데이트
- `docs/plans/PLAN_v3.22_macos.md` (T-222~T-227 [x])
- `docs/TODO.md` (v3.22 섹션 신설, v3.21 완료 표시)
- `docs/CHANGELOG.md` (v3.22.0 섹션)
- `docs/DESIGN.md` (3.22 홈 화면/카테고리 섹션)

## 7. 오프라인 큐 상태
- 해당 없음 (macOS 로컬).

## 8. E2E/k6
- 해당 없음 (macOS 로컬 테스트만).