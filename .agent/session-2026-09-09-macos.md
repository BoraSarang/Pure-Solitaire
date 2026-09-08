# Session 2026-09-09 — macOS

## 요약
- 무엇을: ① T-253 보드 탭 라우터 이중 발화 차단 커밋·푸시 (`8aef99f`). ② 코드베이스 리팩토링 4건 전부 완료 — A1 스톡 탭 중복 가드 일원화(`abb7284`), B undo/redo `UndoHistory<Snapshot>` 제네릭 공용화+커스텀 Codable 저장 호환(`38182db`), A2' 카드 무늬 색상 `Suit.uiColor` 통일(`5070461`), C GameSaver 27개 메서드 → variant→key 제네릭 슬롯+clearAll(`c1e28d3`). 문서 커밋(`e378ab0`).
- 플랫폼: macOS (Pure Solitaire, SwiftUI)
- 빌드+테스트: `swift build -c release` 성공, `swift test -c release` **267개 전부 통과** (커밋 4건 각각).
- PERF/CACHE: 해당 없음 (무동작 리팩토링. 저장 키·형식 불변 → 이어하기 호환 유지).
- 남은 TODO: T-253 GUI 라이브 검증 보류(FreeCell/Klondike 등 변형 탭·드래그) — 디스플레이 슬립/잠금 상태로 미검증. 문서(TODO.md v3.26)는 리팩토링 완료로 마킹.
- 전달 로그: 화면 상태가 어두움(백라이트 0 추정). cliclick·AXPress·키보드 합성 이벤트가 앱에 전달되지 않으므로 GUI 테스트 재개 시 화면 밝기/모니터 정상 확인 먼저. 홈 타일 실좌표는 AX로 취득 가능(scroll area 버튼, 창 위치 독립).
- 문서 갱신: TODO.md(T-253 보류 사유 + v3.26 리팩토링 완료), CHANGELOG.md(리팩토링 항목), PLAN 불필요(완전 무동작 리팩토링).
- 큐 상태: 좋음.
- E2E: 해당 없음(추후 GUI 검증 시 그룹).

## 갱신 — v3.27 (Pyramid 재활용 1회 + Spider 스톡 표시, 커밋 8ec749e)
- 무엇을: ① Pyramid 스톡 재활용 1회(Par Pyramid) — `didRecycle` 상태 + `canMove(.recycleStock)`(스톡 비고 웨이스트 있고 미사용) + `applyUnchecked`(웨이스트 역순→스톡 복귀) + Snapshot/Codable(`decodeIfPresent ?? false`로 기존 저장 호환) + hint 후보 + VM `tapPyramidStock` 분기 + 스톡 자리 유턴 아이콘. ② Spider 스톡 더미 소진 표시 수정 — `cardsLeft > index * 10`(클릭 1회=10장 딜, 더미당 10장): 전부 사라질 때까지 유지되던 문제 해결. 문서 PLAN_v3.27/TODO(T-254~257)/CHANGELOG/DESIGN 갱신.
- 플랫폼: macOS (Pure Solitaire, SwiftUI)
- 빌드+테스트: `swift build -c release` 성공(기존 Scorpion dead-code 경고만), `swift test -c release` **274개 전부 통과**(267 + Pyramid 7개).
- PERF/CACHE: 해당 없음. 저장 형식 호환 유지(새 `didRecycle` 키, 없으면 false).
- 남은 TODO: T-253 GUI 라이브 검증(FreeCell/Klondike/FortyThieves 등 변형 탭·드래그) + T-243 잔여 `build_and_run.sh release` 수동 시나리오 + T-058/T-068 수동 검증 — 디스플레이 정상이면 사용자가 직접 확인. 보류 유지: T-206(솔버 휴리스틱), T-030(변형 프리셀 추가).
- 전달 로그: **사용자 실기 확인 완료 (2026-09-09, 재실행 설치본)** — ① 피라미드 스톡 재활용 1회(유턴 아이콘 → 탭 → 재활용) ② 스파이더 스톡 더미 클릭마다 1개씩 소진. 남은 GUI 검증: FreeCell/Klondike 등 변형.
- 전달 로그: GUI 검증 조건 그대로(디스플레이 밝기 정상화 선행). Spider 스톡은 클릭마다 더미 1개씩 비워지는지 사용자 확인 필요.
- 문서 갱신: PLAN_v3.27_macos.md, TODO.md(T-254~257 완료), CHANGELOG.md, DESIGN.md(3.9 Pyramid 재활용 기술).
- 큐 상태: 좋음.
- E2E: 해당 없음.