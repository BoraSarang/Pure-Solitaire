# PLAN v3.20 — Winnable 딜 (macos)

> platform: macos · 버전: 3.20.0 · 작성: 2026-08-12 · 근거: docs/RESEARCH.md §3-2 / §5 후보 2 (v3.16에서 제외, 후속 재검토 → 사용자 선택: FreeCell 계열 4종)

## 1. 개요

게임 번호로 시작한 FreeCell 계열 딜이 **실제로 풀리는(승리 도달 가능한) 번호만** 시작되도록 보장한다.

- **범위**: FreeCell 계열 4종 — `freecell`, `bakersGame`, `seaTower`, `superFreeCell`. 전부 앞면 카드라 풀이(솔버)가 확정적·정확.
- **솔버**: GameCore에 `FreeCellSolver` — 현재 상태에서 승리 가능 여부를 **결정적 DFS + 휴리스틱**으로 판정. FreeCell은 고전적으로 거의 모든 딜이 풀리지만(마이크로소프트 연구 ~99.99%), 일부 번호는 불가능. Winnable 옵션이 켜지면 풀리지 않는 번호를 건너뛰고 다음 풀리는 번호로 이동.
- **옵션**: FreeCell 계열 4종에 `winnable` 토글 옵션("승리 보장") 추가 — `GameVariant.optionDefinitions` + GameOptionsStore 자동 반영. 새 게임 시작 시 적용.
- **비용 가드**: 솔버는 노드 예산 + 시간 예산 제한. 예산 초과는 "풀림 미확정"으로 처리(불필요한 긴 대기 방지). 다음 풀리는 번호 탐색은 최대 200번까지.

## 2. 결정 사항

- **솔버 알고리즘**: 상태공간 탐색(DFS) + 휴리스틱 순서 + 방문 상태 집합(사이클 방지).
  - 이동 생성: 열→열(그룹), 열→프리셀, 프리셀→열, 열→홈, 프리셀→홈, 홈→열(되돌리기, 드물게 필요). `FreeCellGame.canMove/apply` 재사용.
  - 휴리스틱: 홈 이동 우선(안전 규칙), 프리셀/빈 열 확보 우선. FreeCell 정통 전략.
  - 종료: `isWon` 도달 = 풀림. 노드 예산(기본 300,000) 또는 시간 예산(기본 2.0s) 초과 = 미확정.
- **Winnable 탐색**: `FreeCellSolver.firstWinnableGameNumber(from:variant:)` — 시작 번호부터 +1씩 풀리는 번호 검색(최대 200개, 예산 초과·불가 판정 시 다음 번호). 시작 번호가 풀리면 그대로.
- **옵션 저장**: 기존 GameOptionsStore 경유(별도 저장 구조 불필요). `GameVariant.optionDefinitions`에 `winnable` 옵션 추가 시 게임 번호 시트/설정에 자동 렌더링.
- **게임 번호 표시**: Winnable 적용 후 실제 시작된 번호로 표시·저장(사용자가 입력한 번호와 다를 수 있음 — 시트 안내문구에 명시).
- **자동 완성·오토플레이 상호작용**: Winnable은 딜 생성 단계에만 영향. 이후 흐름(오토플레이/자동완성/점수)은 그대로.
- **롤백**: `git revert` + FreeCellSolver/Winnable 탐색 제거. 저장 구조 무변경(옵션 ID 하나뿐).

## 3. 아키텍처

```
Sources/GameCore/FreeCellSolver.swift             승리 가능 판정 DFS + firstWinnableGameNumber (+ 테스트)
Sources/GameCore/GameVariant.swift                optionDefinitions에 winnable 토글 추가 (FreeCell 계열 4종)
Sources/PureSolitaire/ViewModels/FreeCellViewModel.swift  winnable 옵션 읽기 + newGame 진입점에서 탐색 적용
Sources/PureSolitaire/Views/GameNumberSheet.swift         안내 문구에 "승리 보장" 설명
Sources/PureSolitaire/Views/SettingsView.swift            (optionDefinitions 자동 반영 — 코드 불필요 가능)
```

## 4. 구현 단계

- [x] T-202: `FreeCellSolver` — 상태공간 DFS(휴리스틱 + 방문 집합 + 노드/시간/깊이 예산) + `isWinnable(gameNumber:variant:)` + `firstWinnableGameNumber(from:variant:)` + 단위 테스트 5개(대표 MS 딜 풀림/예산 내 판정/예산 0 미확정/미지원 변형/첫 Winnable 번호). **깊이 예산 초과를 가지치기(continue)로 처리** — 기존 `return false`는 백트래킹 차단으로 오판 유발. 기본 예산 nodeLimit 400k/timeLimit 4.0s/depthLimit 20k. 알려진 한계: #1/#50/#500 예산 내 미확정.
- [x] T-203: `GameVariant.optionDefinitions` — FreeCell 계열 4종에 `winnable` 옵션("일반"/"승리 보장") 추가 (GameOptionTests +1)
- [x] T-204: VM — `isWinnableEnabled(for:)`(옵션 읽기) + `newGame(number:variant:)`에서 적용: 풀리는 번호 탐색(WinnableSearchBudget 100k/1.0s, maxAttempts 50) 후 그 번호로 실제 시작(표시·저장·통계 반영)
- [x] T-205: 게임 번호 시트 안내 문구 + 회귀(220) + `swift build`(경고 0) + 문서

## 5. 테스트 계획

- **자동**:
  - FreeCellSolverTests: FreeCell 게임 번호 1 시작(풀림 기대, MS 정통) / Bakers/Sea Tower/Super FreeCell 각 1샘플(풀림) / 명시적으로 불가 판정 케이스(예산 초과 포함) / firstWinnableGameNumber가 항상 풀리는 번호 반환(솔버로 재확인) / 예산 0이면 미확정
  - 기존 214개 전부 통과(회귀).
- **수동 (일괄, v3.15~v3.20 마지막에)**: 각 4종에서 "승리 보장" ON → 시작 후 실제로 풀림(직접 플레이/자동완성), OFF → 기존 동작 그대로, 게임 번호 표시가 탐색된 번호로 갱신되는지.

## 6. 롤백 계획

- `git revert`. FreeCellSolver.swift 제거 + optionDefinitions에서 winnable 제거 + VM 탐색 코드 제거. 저장 구조 무변경.

## 7. 성능/영향

- 솔버 호출은 게임 시작 시 1회(최대 수초)뿐. 게임 진행에는 무관.
- 노드 예산 300,000 / 시간 예산 2.0s — 대부분 딜은 수천 노드 내 판정. 초과 시 "미확정" 처리로 체감 지연 제한.
- GameCore 결정론 유지(시드 기반 탐색이므로 결과 재현 가능).
