# 세션 로그 2026-08-14 (macos) — v3.21.0 릴리스 완료 (T-210~T-221)

## 1. 무엇을
- **A 자동 풀어 보기**: `FreeCellSolver.solve() -> SolveResult?` 이동 수집 DFS + 무효 이동 2건 수정 + stagnant 가지치기(80). `applyForReplay`/스냅샷 복원 + `PlaybackOverlayView`(속도 3단계/일시정지/중단) + ⇧⌘P.
- **내 이동 리플레이**: 전방 `moveHistory` 동기화 + 승리 시 확정, `startReplay` 시작 상태로 되돌려 재생, ⇧⌘R.
- **C 난이도**: `Difficulty`(노드 <20k/150k 경계) + `Difficulty.measure`(FreeCell 계열만, 예산 400k/8s/20k) + 판 목록 태그(백그라운드 순차 측정 캐시).
- **B 일일 도전 9판**: `DailyChallenge.deals(for:)`(12종 중 9개 날짜 시드 결정적 셔플) + ChallengeStore 9판 기록(`DayResult`/`recordDeal`, 단건→9판 호환).
- **3개월 달력 + 월 통계 + 월 배지(D)**: `CalendarMonth`/`MonthSummary`/`MonthBadge`(25/50/75/100%) + ChallengeView 전면 재작성(달력 ◀▶ + 9판 목록 + 통계 하단 + 배지 헤더).
- **T-221 릴리스**: v3.21.0 태그 + zip(4.3MB) + GitHub Actions Release 트리거.

## 2. 플랫폼
- macOS (GameCore 공통 + PureSolitaire SwiftUI).

## 3. 빌드 결과 + PERF
- `swift build -c release` 경고 0. `swift test -c release` **249개 전부 통과**(32.3s).
- `build_and_run.sh release` 설치·실행 성공(프로세스 기동 확인). **스크립트 테스트를 `swift test -c release`로 변경** — debug는 #50이 20s 시간 예산 초과로 실패(CI 워크플로우와 동일 조건).
- 난이도 측정: 판당 최대 8s(백그라운드), 9판 순차. 9판/달력/통계: 결정적 수 ms.

## 4. 남은 TODO
- 없음 — v3.21.0 완료. (후보: v3.22 Edge 호환/난이도 저장 영속화 등은 계획에 없음)

## 5. 다음 에이전트 전달 로그
- 테스트는 반드시 `swift test -c release` (debug는 FreeCell 예산 초과).
- 솔버: `replayBudget`(2M/20s/60k) — #50 유효 해 703 이동 16.6s, #10(2553 이동/134s)은 난이도 높음, #11982는 MS 유일 미해결. `maxStagnantDepth = 80`.
- 일일 도전은 **판별(variant+number) 매칭**으로 기록 — VM `activeChallengeDeal`. 기존 단건 API는 호환 유지 중.
- 난이도 측정은 `Task.detached` 순차 + `dealDifficultyCache`(세션) — 시트 onDisappear에서 `cancelDealDifficultyMeasurement()`.
- `build_and_run.sh`는 이제 release 테스트 사용.

## 6. 문서 업데이트
- `docs/plans/PLAN_v3.21_macos.md` (T-210~T-221 전부 [x])
- `docs/TODO.md` (v3.21 섹션 T-210~T-221)
- `docs/CHANGELOG.md` (v3.21.0 섹션 신설)
- `docs/DESIGN.md` (3.21 자동 풀어 보기 + 일일 도전 9판/달력 섹션)
- `docs/tests/v3.21_macos.md` (신규)

## 7. 오프라인 큐 상태
- 해당 없음 (macOS 로컬).

## 8. E2E/k6
- 해당 없음 (macOS 로컬 테스트만).