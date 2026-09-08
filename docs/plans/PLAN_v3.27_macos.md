# PLAN_v3.27_macos — Pyramid 스톡 재활용 1회 + Spider 스톡 표시

> platform: macos · 결정: Par Pyramid 표준 — 재활용 1회 제한 · 기존 저장 데이터 호환 유지
> 배경: strict(재활용 0회) 승률 ~5%로 현저히 어려움. 재활용 1회 시 승률 ~15~25% 구간.

## T-254 GameCore — PyramidGame
- 상태: `public private(set) var didRecycle = false` (1회 제한).
- `canMove(.recycleStock)`: `stock.isEmpty && !waste.isEmpty && !didRecycle` (거부 목록에서 분리).
- `applyUnchecked(.recycleStock)`: `stock = waste.reversed(); waste.removeAll(); didRecycle = true` (KlondikeGame 패턴).
- `Snapshot`/`currentSnapshot`/`restore`에 `didRecycle` 포함 (undo/redo 보존).
- Codable: `didRecycle` encode + `decodeIfPresent ?? false` (기존 저장 호환).
- `hintCandidates()`: 스톡 비고 웨이스트 있고 미사용이면 `.recycleStock` 후보 추가 (자동풀어보기 없음 → 루프 위험 없음).

## T-255 VM/View
- `tapPyramidStock`: 스톡 비면 `.recycleStock`, 아니면 `.drawFromStock` (tapKlondikeStock 패턴).
- `pyramidStockView`: 스톡 비고 재활용 가능 시 `arrow.uturn.left.circle` 오버레이 + 접근성 힌트 "누르면 1회 재활용". didRecycle 이후엔 기존 반투명 빈 슬롯.

## T-256 검증/문서
- 테스트: 기존 `testDrawFromStockNoRecycle` → `testDrawFromStockEmptyStockRejected` 개명. 신규 재활용 1회/순서 복원/스톡 존재 시 거부/undo-redo · Codable 복원/레거시 호환.
- `swift build -c release` + `swift test -c release` 회귀 274개 통과. TODO/CHANGELOG/DESIGN 갱신 후 커밋.

## T-257 Spider 스톡 더미 표시
- 문제: `spiderStockPile`이 index와 무관하게 스톡 전체 존재만으로 렌더 → 클릭해도 5더미 유지되다 다 소진 시 한꺼번에 사라짐.
- 수정: 스톡 50장·클릭 1회 = 10장 딜이므로 더미당 10장 연동 — `cardsLeft > index * 10`이면 해당 더미 표시. 클릭마다 더미 하나씩 비워짐.