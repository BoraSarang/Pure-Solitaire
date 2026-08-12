# PLAN v3.19 — 점수 체계 (macos)

> platform: macos · 버전: 3.19.0 · 작성: 2026-08-12 · 근거: docs/RESEARCH.md §3 후보 7 + 사용자 결정(표준 점수 + 변형별 상수 / 게임 보드 + 승리 결과 표시)

## 1. 개요

변형별 점수 상수를 정의하고, 이동별 점수 누적 + 승리 보너스를 계산해 **게임 보드(현재 점수)** 와 **승리 배너(최종 점수)** 에 표시한다. GameCore에 순수 `Scoring` 타입을 두고 VM이 누적한다.

1. **T-198 GameCore**: `Scoring` — 이동별 점수 + 승리 보너스 + 시간 보너스(변형별 상수) + 단위 테스트.
2. **T-199 VM**: `score` 상태 + apply 성공 시 누적 + 승리 시 최종 점수 계산 + 초기화(새 게임).
3. **T-200 View**: 게임 정보에 현재 점수 표시 + 승리 배너에 최종 점수 표시.
4. **T-201 회귀 + 테스트 + 빌드 + 문서**.

## 2. 결정 사항

### 2.1 점수 규칙 (표준 Klondike 기준 + 변형별 상수)

**이동 점수** — `Scoring.moveScore(for:variant:)`:
| 이동 | 점수 | 비고 |
|------|------|------|
| `drawFromStock` (스톡→웨이스트) | +5 | Klondike 표준 |
| `recycleStock` | -100 | Klondike 표준 (웨이스트 재활용 패널티) |
| `flipColumnCard` | +5 | Klondike 표준 |
| `columnToHome` / `wasteToFoundation` / `freeCellToHome` | +10 | 홈셀 이동 |
| `homeToColumn` / `homeToFreeCell` | -15 | 홈셀에서 꺼내기 패널티 |
| `pyramidRemovePair` / `pyramidRemoveSingle` | +10 | 피라미드 제거 |
| `pyramidRemoveWastePair` | +5 | 피라미드+웨이스트 |
| `triPeaksRemove` | +5 | 피크 제거 |
| `columnToWaste` (Golf) | +5 | 골프 제거 |
| `columnToColumn` / `freeCellToColumn` / `wasteToColumn` | 0 | 타블로 내 이동 (스파이더 완성용 그룹 포함) |
| `dealFromStock` (Spider) | 0 | 스톡 딜 |
| `dealReserve` (Scorpion) | 0 | 예비 딜 |

- **스파이더 완성 보너스**: 열에서 K→A 13장 완성 시 **+100** (완성 시퀀스가 늘어난 만큼만). VM에서 apply 전후 `completedSuits` 증가분만큼 가산.
- **콤보 보너스**: 이번 버전에서 제외 (표준 점수 단순 유지).

**승리 보너스** — `Scoring.winBonus(for:)` (변형별 상수):
- Klondike/Yukon/FreeCell/SuperFreeCell/Bakers/SeaTower/FortyThieves/Scorpion: **+500**
- Spider: **+800** (난이도)
- Golf/Pyramid/TriPeaks: **+300** (제거 기반 — 짧은 게임)

**시간 보너스** — `Scoring.timeBonus(seconds:variant:)`:
- Klondike만 표준대로 **10초마다 -2** (왕복 처리로 소수점 반올림)
- 나머지 변형은 0 (시간 중립)

### 2.2 VM
- `@Published private(set) var score = 0` — 현재 게임 점수.
- `apply(move:)` 성공 시 `score += Scoring.moveScore(...)` + 스파이더 완성 보너스. `applyRaw` 경로(자동 플레이)는 스코어에 포함하지 않음.
- `newGame`/`requestNewGame`/`startDailyDeal`/`startChallenge`에서 `score = 0`.
- 승리 시 `currentScore` 계산 — `score + winBonus + timeBonus`. `nextGameAfterWin`/undo로 승리 해제 시 승리 보너스 제외 복원.
- 최종 점수는 `RecordStore.GameRecord`에 `score` 필드로 저장(변형별 최근 승리 목록에 표시, 기존 데이터 호환 — decodeIfPresent).

### 2.3 View
- **게임 보드**: `gameInfoView`(이동 수 옆)에 "점수 N" 표시.
- **승리 배너**: `WinBanner`에 최종 점수 + 승리 보너스 분해 표시. `vm.finalScore` 노출.
- **통계**: RecordStore 승리 목록에 점수 표시(선택적, StatsView 게임 기록 행).

### 2.4 저장/호환
- `GameRecord.score: Int?` — decodeIfPresent로 기존 데이터(score 없음) 호환. 새 기록은 score 포함.
- 점수는 런타임 계산값이므로 GameSaver(게임 진행)에는 저장 안 함 — 새 게임 시 0부터.

## 3. 아키텍처

```
Sources/GameCore/Scoring.swift                            점수 상수/계산 (순수)
Sources/GameCore/RecordStore.swift                        GameRecord.score 필드
Sources/PureSolitaire/ViewModels/FreeCellViewModel.swift  score 누적 + finalScore
Sources/PureSolitaire/Views/GameBoardView.swift           gameInfoView 점수 표시
Sources/PureSolitaire/Views/ContentView.swift             WinBanner 최종 점수
Tests/GameCoreTests/ScoringTests.swift                    단위 테스트
```

## 4. 구현 단계

- [x] T-198: Scoring(이동/승리/시간 점수, 변형별 상수) + ScoringTests
- [x] T-199: VM score 누적 + 스파이더 완성 보너스 + finalScore + 초기화
- [x] T-200: gameInfoView 점수 표시 + WinBanner 최종 점수 + StatsView 기록 점수
- [x] T-201: 회귀(214 = 207+7) + swift build 경고 0 + 문서

## 5. 테스트 계획

- **자동**:
  - 이동 점수: drawFromStock +5 / recycleStock -100 / flip +5 / 홈 이동 +10 / 홈에서 -15 / 피라미드·골프·트리피크스 제거 점수.
  - 변형별 승리 보너스: Klondike 500 / Spider 800 / Golf 300.
  - 시간 보너스: Klondike 10초당 -2 (예: 95초 → -20, 소수점 버림) / 나머지 0.
  - `GameRecord` score 필드 코딩/디코딩 호환(score 없는 기존 데이터 → 0).
  - 기존 207개 전부 통과.
- **수동 (일괄, v3.15~v3.19 마지막에)**: 게임 중 점수 누적/게임 정보 표시, 승리 배너 최종 점수, 새 게임 시 0.

## 6. 롤백 계획

- `git revert`. `GameRecord.score`는 optional 추가 — 기존 저장 데이터 호환, 무영향.

## 7. 성능/영향

- GameCore 신규 순수 타입(상수+계산), VM 점수 정수 누적 — 성능 영향 미미. 다른 변형 무변경.
