# PLAN_v3.24_macos — 일반/확장 모드 분리

> platform: macos · 결정: 일반 데일리 4판 · 전환 시 게임 유지 · 기록 통합 유지

## T-244 GameCore 모델
- `GameMode` enum (`standard`="일반"/`extended`="확장").
- `GameVariant.standardVariants = [.freecell, .klondike, .spider, .pyramid]`.
- `visibleVariants(mode:)` 일원화 헬퍼.
- `DailyChallenge.deals(for:calendar:mode:)` — 일반: 4종 고정 순서 + 날짜별 번호, 확장: 기존 9판 셔플. `dealsPerDay(mode)` 4/9.

## T-245 설정
- `@AppStorage("settings.gameMode")` + SettingsView 게임플레이 섹션 세그먼트 Picker.

## T-246 선택 UI 필터
- HomeView (빈 카테고리 숨김), GameSelectorView, `switchToRandomGame`, `startTodayDeal`.

## T-247 데일리 연동
- ChallengeView에 Settings 주입 + 모드 전달. `recordChallengeIfToday` 모드 전달.

## T-248 전환 정책
- 진행 중 게임 유지, 복원 게임은 모드 예외 허용 (코드 변경 없음, 명시만).

## T-249 검증
- 신규 테스트: 모드별 구성/결정성/필터. `swift test -c release` + `build_and_run.sh release` 수동.

## T-250 문서
- TODO/CHANGELOG/DESIGN 갱신 후 커밋·푸시.
