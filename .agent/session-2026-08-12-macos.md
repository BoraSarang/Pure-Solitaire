# 세션 로그 — 2026-08-12 (macos)

## v3.18 Scorpion 변형 구현 (T-192~T-196)

### 1. 무엇을 (T-192~T-196)
- **T-192**: `Sources/GameCore/ScorpionGame.swift` 생성 — 7열×7장 + 예비 3장, 같은 수트+1랭크/그룹 이동/빈 열 K만/승리 K→A 4열, `Move.dealReserve` 1회 딜, undo/redo/hint. `DealGenerator.scorpionDeal`. `ScorpionGameTests.swift` 9개.
- **T-193**: `GameVariant.swift`에 `.scorpion`(displayName "Scorpion"). GameVariant 전환 switch 전부 갱신 — FreeCellRule(같은 수트), FreeCellGame(freeCellCount 0 + dealReserve false), TriPeaks/Pyramid/Golf/FortyThieves(canMove false), ChallengeStore(timeTarget 600/moveTarget 240).
- **T-194**: VM — `scorpion` 프로퍼티, init 복원, variant/current*/canUndo/canRedo, apply/applyRaw, undo/redo, persist, clearSave, canMove, makeScorpionMove, currentHintCandidates, checkState hasAnyMove, 자동 플레이 가드, moveDescription(.dealReserve), tapScorpionStock/Column/isScorpionSelected.
- **T-195**: GameSaver — `persistence.savedScorpion` save/restore/clear.
- **T-196**: GameBoardView — scorpionTopRow(완성 n/4 + 예비 더미 탭), scorpionColumnView, columnView/cardSize/maxColumnCards/columnCount 분기, handleScorpionCardTap, isScorpionHintSource, dragSource(열 그룹), hintSourceDestination(.dealReserve nil), GamePreviewCard(.scorpion 열형+예비).

### 2. 플랫폼
- macos (SwiftUI + GameCore)

### 3. 빌드/테스트 결과
- `swift build` 경고 0건
- 단위 테스트 **207개 통과** = 기존 198 + Scorpion 9 (딜 레이아웃/배치 규칙/그룹 이동/예비 1회 딜/승리 4열/승리 3열 아님/undo·redo/canAutoFinish/hint)
- 수정 중 시행착오: Card initializer non-optional(if let 제거), reserveDealt private(set)(테스트에서 직접 할당 제거), handleColumnTap 4인자 시그니처, CardSource에 stock 없음(tapScorpionStock 직접 apply), GameVariant switch exhaustiveness 다수 파일, 빈 열 테스트 상태 직접 조작.

### 4. 남은 TODO (v3.18)
- [ ] T-197: 회귀(207) + swift build 경고 0 (완료 확인됨) + 문서 (PLAN/TODO/CHANGELOG/DESIGN 완료, 커밋 대기)
- v3.19 (점수 체계) 진행 예정

### 5. 다음 에이전트 전달 로그
- 커밋 대기 중: `feat(macos): v3.18 Scorpion 변형`
- 커밋 전 `git status`로 미추적 파일(ScorpionGame.swift, ScorpionGameTests.swift, PLAN_v3.18) 포함 확인
- 수동 검증은 v3.15~v3.19 일괄 지연 (사용자 지시)
- 에러코드 없음

### 6. 문서 업데이트 목록
- PLAN_v3.18_macos.md (T-192~197 체크), TODO.md (v3.18 섹션), CHANGELOG.md ([3.18.0]), DESIGN.md (§3.20)

### 7. 오프라인 큐 상태
- 해당 없음 (macOS 앱, 서버 없음)

### 8. E2E/k6
- 해당 없음 (macOS 앱)
