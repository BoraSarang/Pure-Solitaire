# PLAN v3.13 — 코어 QoL: 자동 완성 / 이동 수 통계 / Klondike 스톡 1·3장 (macos)

> platform: macos · 버전: 3.13.0 · 작성: 2026-08-09 · 근거: docs/RESEARCH.md (사용자 선택 후보 1·3·2)

## 1. 개요

사용자가 선택한 후보 기능 중 **코어 QoL 3건**을 한 버전에 반영한다.

1. **T-170 승리 자동 완성(Auto-finish)**: 승리 직전(모든 카드가 홈 이동 가능) 상태에서 남은 카드를 홈셀로 자동 정리.
2. **T-171 이동 수 통계**: 변형별/전체에 `leastMoves`(최소 이동)·`avgMoves`(평균 이동) 기록·표시. 승리 기록에 이동 수 저장.
3. **T-172 Klondike 스톡 1·3장 옵션**: `optionDefinitions` 기반으로 스톡 드로 1장/3장 선택.

> 대상: 3개 모두 기존 인프라 재사용(`AutoPlay`, `GameVariant.optionDefinitions`, `StatsStore`/`RecordStore`, `GameNumberSheet` 자동 렌더) → GameCore 변경 최소화.

## 2. 결정 사항

### 2.1 자동 완성 (T-170)
- **트리거**: `apply(_:)` 성공 직후와 `checkState()` 진입 시, **모든 잔여 카드가 홈으로 이동 가능** 상태(`canAutoFinish`)인 게임만 자동 완성.
- **대상 게임**: 홈셀 중심 게임 — freecell, bakersGame, seaTower, superFreeCell, klondike, yukon, fortyThieves. (spider/golf/pyramid/triPeaks 제외 — 홈 완성 구조 아님)
- **동작**: `runAutoPlay()`와 동일하게 `applyRaw`로 순수 홈 이동 반복 → 승리 검증 → 메시지/사운드/승리 연출.
- **설정**: `UserSettings.autoFinishEnabled`(@AppStorage, 기본 true). 게임플레이 설정 섹션 "승리 자동 완성" 토글.
- **undo**: 자동 완성 이동은 **undo 스택에 포함** (중간 복귀 가능). 승리 후 undo → `resetWinUIAfterUndoIfNeeded` 기존 흐름 사용.

### 2.2 이동 수 통계 (T-171)
- `StatsStore.Entry`에 `leastMoves: Int?`·`totalMoves: Int`·`avgMoves: Int`(반올림) 추가. 전체 합계에도 동일.
- 승리 시 `moveCount`를 기록 — VM이 승리 직전 `currentMoveCount` 읽어 저장.
- `RecordStore.GameRecord`에 `moves: Int` 추가 (기존 Codable 호환 — decode 실패 시 defaults 보존 위해 `modeVs: Int?`로 마이그레이션 또는 기본값; 기존 저장 데이터 무손상 Windows).
- `StatsView` 선택 요약/상세에 "최소 이동"·"평균 이동" 행 추가. 최근 승리 목록에 이동 수 표시.
- `StatsStore.resetAll`에 새 키 제거 포함.

### 2.3 Klondike 스톡 1·3장 (T-172)
- `GameVariant.klondike.optionDefinitions`에 `GameOption(id: "klondikeDraw")` 추가: choices 1장/3장.
- `KlondikeGame`에 `drawMode: Int`(1/3) 프로퍼티, Codable 호환(decodeIfPresent 기본 1).
- `drawFromStock` 적용 시 드로 장수 반영, `canMove`/`hintCandidates`의 드로 조건 동일. (3장은 표준: 스톡에서 3장 드로 → 웨이스트에 `reversed`로 쌓여 맨 위만 사용 가능 — 이 프로젝트의 기존 "1장 드로를 3장으로" 방식 유지)
- VM `newGame`/`restore`에서 옵션값 읽어 전달. GameNumberSheet/설정 자동 렌더.

## 3. 아키텍처

```
Sources/GameCore/KlondikeGame.swift       drawMode(1/3) + Codable + canMove/apply `drawFromStock`
Sources/GameCore/GameVariant.swift        klondike.optionDefinitions + `KlondikeGame.DrawMode`
Sources/GameCore/RecordStore.swift        GameRecord.moves
Sources/PureSolitaire/Persistence/StatsStore.swift   leastMoves/totalMoves/avgMoves (+리셋)
Sources/PureSolitaire/Persistence/UserSettings.swift autoFinishEnabled
Sources/PureSolitaire/ViewModels/FreeCellViewModel.swift  runAutoFinish() + 승리 시 moves 기록 + klondike drawMode
Sources/PureSolitaire/Views/StatsView.swift            이동 수 표시 + 최근 승리 이동 수
Sources/PureSolitaire/Views/SettingsView.swift         "승리 자동 완성" 토글
```

## 4. 구현 단계

- [x] T-170: 자동 완성 — VM `allHomeMoveableNow`/`runAutoFinish()` + UserSettings 토글 + apply/checkState 트리거
- [x] T-171: 이동 수 통계 — StatsStore 확장 + RecordStore.moves + VM 승리 기록 + StatsView 표시
- [x] T-172: Klondike 스톡 1/3장 — KlondikeGame.drawMode + GameVariant 옵션 + VM 전달
- [x] T-173: 테스트 추가(GameCore: 드로 모드, StatsStore 이동 수) + 회귀 + `swift build` 경고 0 + `swift test`
- [ ] T-174: release 설치·실행(VERSION 3.13.0) + 문서(PLAN/TODO/DESIGN/CHANGELOG/tests/session)

## 5. 테스트 계획

- **자동**: 기존 171개 + 신규(스톡 3장 드로 순서, 이동 수 기록왕복, autoFinish 판단 GameCore) 회귀
- **수동 (AX)**: 
  - 자동 완성: 홈셀 13장 완성 직전 카드까지 두고 마지막 이동 → 나머지 자동 정리 + 승리 연출
  - 이동 수: 게임 완료 시 평균/최소 이동 갱신, 통계 시트 표시 확인
  - Klondike 3장: 스톡 클릭 시 3장씩 드로, 웨이스트 맨 위만 조작, 재활용 정상

## 6. 롤백 계획
- `git revert` — StatsStore/RecordStore/UserSettings/KlondikeGame/VM/StatsView/SettingView 원복
- 저장 구조: StatsStore는 기존 키 유지 + 신규 키 `leastMoves`/`totalMoves`만 추가(기존 데이터 무손상), RecordStore의 `moves`없는 데이터가 default로 되돌아감. KlondikeGame 코머MODE는 decodeIfPresent(기본 1) → 무손상.

## 7. 성능/영향
- 자동 완성: `applyRaw` 재사용 — 무한 루프 방지를 위해 최대 실행 수 상한(예: 500회) 가드.
- 표시 계층만 추가 — GameCore/저장 immutable 구조 유지.