# PLAN_v3.23_macos — 게임 흐름 버그 수정 (데일리 단일화 → 시작 전환 → 솔버 안전화)

> platform: macos · 규모: 중 (버그 수정 3단계, 구조 리팩토링 제외)
> 배경: 데일리 2중 경로·홈 전환 순서·솔버 블로킹 등 흐름 매끄럽지 않음 지적 → 분석 후 단계별 수정

## 1단계 — 데일리 단일화 + 기록 정합성 (T-229~T-233)
- T-229: `startDailyDeal` 폐지 → `startTodayDeal(variant:)` (오늘 9판 내 매핑, 없으면 DailyDeal 번호로 Deal 구성) 후 `startChallenge` 위임. 호출부 교체: SideBarView:62, GameCommands:27. ⌘D·버튼·메뉴 UX 유지.
- T-230: `activeChallengeDeal: Deal?` → `activeChallenge: (deal, startDate)?` 구조체화. `newGame` 진입 시 `nil` 리셋 + `pendingChallengeDeal`로 확인 다이얼로그 경로 대응. `cancelNewGame`에서 pending 파기.
- T-231: `recordChallengeIfToday` → 시작일 기준 기록으로 변경 (자정 경계 승리도 시작일에 기록). 챌린지 시작 시 Winnable 탐색 우회 (표시 번호 = 플레이 번호 = 기록 키).
- T-232: 미래 판정 `selectedDate > today` → `dateKey` 문자열 비교 (오전 오늘 비활성화 버그). ChallengeView:266-267.
- T-233: 측정 취소 시 `measuringDealKeys` 롤백 (태스크 종료 후 pending 키 정리). ChallengeTests 3개 추가.

## 2단계 — 시작·전환 매끄럽게 (T-234~T-238)
- T-234: 홈 이탈 순서 역전 — 확정 후 `onStartGame`, 취소 시 `showingHome` 복구 (HomeView:198-200).
- T-235: `applyGameNumber` 성공 시점에 VM 내부에서 `showingHome=false` (GameNumberSheet 경로).
- T-236: 시트→다이얼로그 2단계 상태머신 (`pendingDeal`, dismiss 연기).
- T-237: `persist` 시 타 변형 키 정리 + `restoredVariant` 1회 캐시.
- T-238: 복원 시 `elapsedSeconds` 저장·복구.

## 3단계 — 솔버·재생 안전화 (T-239~T-243)
- T-239: Winnable 탐색 비동기화 (Task.detached + 로딩 UI + 취소 토큰).
- T-240: 자동풀어보기 세대 토큰 (완료 시점 대조 후 파기).
- T-241: `dfs` 루프 `Task.checkCancellation` 주입.
- T-242: 변이 진입점 `guard !isAutoSolving && !isReplaying` 일괄 + `goHome` 재생 취소.
- T-243: 회귀 + `build_and_run.sh release` 수동 시나리오 + CHANGELOG/DESIGN 갱신.

## 검증
- 매 단계 `swift test -c release` 전체 통과 + 단계별 신규 테스트.
- DoD: 한국어 로그/주석, error_code 해당 시, `error_message_ko.json` 갱신 (사용자 메시지 변경 시).
