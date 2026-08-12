# PLAN v3.18 — Scorpion 변형 추가 (macos)

> platform: macos · 버전: 3.18.0 · 작성: 2026-08-12 · 근거: docs/RESEARCH.md §5 후보 5 (사용자 선택: Scorpion) + 표준 규칙 확인

## 1. 개요

**Scorpion** 1덱 변형을 추가한다. Yukon(그룹 이동) + Spider(같은 수트 빌드, 완성 K→A 시퀀스)의 혼합이며 홈셀 없이 타블로에서 승리한다.

1. **T-192 GameCore**: `ScorpionGame` (7열×7장, 예비 3장, 홈 없음) + `DealGenerator.scorpionDeal` + 단위 테스트.
2. **T-193 GameVariant**: `.scorpion` 케이스(displayName "Scorpion", 옵션 없음).
3. **T-194 VM**: scorpion 상태 + init 복원 + newGame/apply/undo/redo/hint/자동완성/드래그 연동.
4. **T-195 GameSaver**: scorpion 저장/복원.
5. **T-196 GameBoardView**: 열/예비(스톡) 렌더 + 탭/드래그/힌트 연동.
6. **T-197 회귀 + 테스트 + 빌드 + 문서**.

## 2. 결정 사항 (표준 Scorpion 규칙)

### 2.1 딜 (GameCore)
- **딜**: 52장 셔플 → **7열 × 7장(49장)**, 나머지 **3장은 예비(reserve)**.
  - **앞 4열(0~3)**: 밑 **3장 뒤집힘** + 위 **4장 앞면**.
  - **뒤 3열(4~6)**: 전부 **앞면 7장**.
  - `DealGenerator.scorpionDeal(gameNumber:)` → `(columns: [[ColumnCard]], reserve: [Card])`.
- **예비 딜**: 스톡 클릭 시 **1회만** 예비 3장을 순서대로 열 0,1,2 위에 앞면으로 얹는다(`dealReserve` Move).

### 2.2 규칙
- **이동**: 같은 수트 + 정확히 한 단계 낮은 카드 위로만. **앞면 카드 1장과 그 위 전부를 그룹으로 이동**(Yukon식, 위 카드 순서 무관). 뒤집힌 카드는 노출 시 자동 앞면.
- **빈 열**: **K(또는 K가 맨 아래인 그룹)만** 놓을 수 있음.
- **승리**: 홈셀 없음 — **열 4개가 각각 같은 수트 K→A 완성 시퀀스**(13장)로 정렬되면 승리. `isWon` = 완성 시퀀스 4개 존재.
- **canAutoFinish = false**: 홈셀 기반 자동완성(v3.13)은 스콜피온에서 동작 안 함(호환 유지).

### 2.3 Move 확장
- 신규 `case dealReserve` 추가(스콜피온 전용, 1회 딜). 기존 `columnToColumn`/`flipColumnCard`(자동 앞면이라 사실상 불필요) 재사용.
- 홈 관련 Move(`columnToHome`/`wasteToFoundation` 등)는 false 반환.

### 2.4 VM/뷰
- `@Published private(set) var scorpion: ScorpionGame?` 추가. `variant == .scorpion`이면 scorpion 참조.
- `newGame`/`apply`/`undo`/`redo`/`canUndo`/`canRedo`/`currentGameNumber`/`currentMoveCount`/`currentIsWon`/`persist`/`restore` 연쇄에 추가.
- GameBoardView: `scorpionTopRow`(예비 스톡) + 열 렌더 — Klondike 열 렌더 재사용. `cardSize`/`maxColumnCards`/`topRow`/소스 헬퍼에 분기 추가.
- **a11y**: 예비 스톡/열에 기존 라벨 패턴 재사용.

## 3. 아키텍처

```
Sources/GameCore/ScorpionGame.swift                 게임 상태 + 이동 + undo/redo + hint
Sources/GameCore/Move.swift                         .dealReserve 케이스
Sources/GameCore/DealGenerator.swift                scorpionDeal 추가
Sources/GameCore/GameVariant.swift                  .scorpion 케이스
Sources/PureSolitaire/Persistence/GameSaver.swift   scorpion 저장/복원
Sources/PureSolitaire/ViewModels/FreeCellViewModel.swift  scorpion 연동
Sources/PureSolitaire/Views/GameBoardView.swift     렌더/탭/드래그 분기
Tests/GameCoreTests/ScorpionGameTests.swift         단위 테스트
```

## 4. 구현 단계

- [x] T-192: ScorpionGame + scorpionDeal + dealReserve + 단위 테스트
- [x] T-193: GameVariant .scorpion + displayName
- [x] T-194: VM 연동
- [x] T-195: GameSaver 저장/복원
- [x] T-196: GameBoardView 렌더/탭/드래그/힌트 분기
- [x] T-197: 회귀(207 = 198+9) + swift build 경고 0 + 문서

## 5. 테스트 계획

- **자동**:
  - 딜: 7열×7장 + 예비 3장 = 52장, 앞 4열 밑 3장 뒤집힘, 뒤 3열 전부 앞면.
  - 이동: 같은 수트 K→Q 놓기/다른 수트 거부/랭크 차이 2 거부/그룹 이동(위 카드 순서 무관)/빈 열 K만.
  - 예비 딜: 1회만(2회째 거부), 열 0,1,2에 앞면 1장씩.
  - 승리: 열 4개 완성 시퀀스 시 true, 일부만이면 false.
  - undo/redo, hintCandidates 우선순위, canAutoFinish false.
  - 기존 198개 전부 통과.
- **수동 (일괄, v3.15~v3.19 마지막에)**: 스콜피온 딜/이동/예비 딜/승리 + 설정·게임번호 시트 반영.

## 6. 롤백 계획

- `git revert`. GameVariant에 신규 케이스 추가 — 기존 저장 rawValue(기존 케이스 문자열) 무영향, 기존 데이터 무손상.

## 7. 성능/영향

- GameCore 신규 모듈(단일 덱), 다른 변형 무변경. VM/뷰 분기 추가 — 영향 미미.
