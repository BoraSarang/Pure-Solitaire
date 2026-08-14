# 세션 로그 2026-08-14 (macos) — T-210 솔버 solve() 코어 완료

## 1. 무엇을
- **T-210**: `FreeCellSolver.solve(gameNumber:variant:budget:) -> [Move]?` — 이동 수집 DFS. `isWinnable`은 `solve() != nil`로 재구현. `replayBudget`(2M/20s/60k).

## 2. 플랫폼
- macOS (GameCore — FreeCell 계열 4종 공통).

## 3. 빌드 결과 + PERF
- `swift build -c release` 성공, 경고 0 (기존 ScorpionGame `default will never be executed` 제외).
- `swift test -c release` 전체 통과 (전 Test Suite passed).
- FreeCellSolverTests 11개 전부 통과 (release 기준).
- **#1: 950~3130 이동 0.47s, #2: 415 이동 0.02s, #100: 3678 이동 0.12s — 전부 유효(실제 적용 시 승리).**
- **#50: 유효 해 703 이동, replayBudget에서 16.6s 해결.**
- #10: 유효 해 2553 이동 존재하나 **134초**(기본 400k 예산/재생 20s 예산 모두 밖) → 난이도 높음 분류.
- #11982: 20M/240s에서도 미해결(MS 유일 불가능 딜과 일치).

## 4. 남은 TODO
- T-210 마무리: 난이도 판정(T-211)용 `solve`의 노드/깊이 소요 반환 추가 → T-211부터 진행.
- 미커밋: `FreeCellSolver.swift`, `FreeCellSolverTests.swift`, `SettingsView.swift`(가로 여백), `PLAN_v3.21_macos.md`, `TODO.md`.

## 5. 다음 에이전트 전달 로그
- **무효 이동 버그 원인/수정**: `generalMoves` 열→열 검사가 `run.first`(전체 bottom) 기준이었음 → 단일 이동(1장)은 `run.last`(top), 그룹 이동은 `run[run.count-count]`(그룹 bottom) 기준으로 수정. 그룹 이동은 maxCount부터 2까지 유효한 최대 그룹만 생성.
- **IDDFS 실패**: FreeCell 상태 공간이 커서 단계별 fresh visited 재탐색이 시간 예산 소진 → 단일 DFS 유지.
- **진행 가지치기**: `Frame.homeCount`/`stagnantDepth` + `maxStagnantDepth = 80` — 홈 카드가 80 이동 이상 증가 없으면 그 경로 백트래킹. 40은 #2 실패, 80이 최적, 150은 경로가 길어짐.
- `movableRun`은 bottom→top 순서 반환(`run.first`=bottom). `Rank.next` = rawValue+1.
- 테스트는 반드시 `swift test -c release` (debug는 FreeCell #2 예산 초과).

## 6. 문서 업데이트
- `docs/plans/PLAN_v3.21_macos.md` (버그 수정 기록 1~5 + 재생 예산 15→20초)
- `docs/TODO.md` (T-206 갱신 + v3.21 섹션 신설, T-210 코어 완료)

## 7. 오프라인 큐 상태
- 해당 없음 (GameCore 솔버 작업).

## 8. E2E/k6
- 해당 없음 (macOS 로컬 테스트만).