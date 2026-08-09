# PLAN v3.14 — 전체 힌트 강조: 유효 이동 전체를 한 번에 표시 (macos)

> platform: macos · 버전: 3.14.0 · 작성: 2026-08-09 · 근거: docs/RESEARCH.md §3.6 / §5 (사용자 선택 후보 1 코어 QoL 마무리)

## 1. 개요

현재 힌트(`⌘H`)는 후보 이동을 **하나씩 순환**하며 해당 소스만 강조한다. 벤치마크에서 여러 솔리테어 앱(MobilityWare "Show Moves", Solitaired 전체 힌트 등)이 채택한 **유효 이동 전체 강조**를 추가한다.

- **기능**: 토글 켜짐 동안 현재 보드의 **모든 유효 이동의 소스**를 동시에 강조(노란 테두리). 끄면 기존 단일 힌트로 복귀.
- **대상**: 모든 변형(11개)에 공통 적용 — `hintCandidates()` 재사용.
- **저장/설정**: 세션 상태(영구 저장 안 함). 단축키 `⇧⌘H` + 사이드바 + 메뉴 + 설정 토글.
- **기존 동작 유지**: `⌘H` 순환, `Enter` 적용, 왕복 애니메이션, 하이라이트 유지 모두 현행 유지.

## 2. 결정 사항

### 2.1 UX/진입점
- **토글 방식**: ON 상태에서 잉여 힌트(` highlightedMove`)도 함께 표시? → **독립 모드**. "전체 힌트" ON이면 전체 소스 강조를 최우선 표시, `⌘H`/Enter 동작은 그대로 독립(단, 전체 힌트가 켜 있으면 후보 순환에 영향 없음).
- **진입점**: 
  - 사이드바 힌트 버튼 옆에 **"전체 힌트"** 토글 버튼(`SideBarButton` 재사용, `isActive`)
  - 게임 메뉴 "전체 힌트"(⇧⌘H) — 켜짐 시 checkmark
  - 설정 "게임플레이" 섹션 기본값 토글은 없음(세션 상태, 기본 OFF)
- **해제 조건**: 이동 적용(apply) / 새 게임 / 게임 전환 / 취소(⇧⌘H 재토글) 시 자동 해제.

### 2.2 상태 모델 (VM)
- `@Published var showAllHints = false`
- `private var allHintSources: [Move]?` — 토글 시점 스냅샷 (게임 상태 변화 감지를 위해)
- `var effectiveHintMoves: [Move]`: 
  - `showAllHints == true` → 현재 게임의 `hintCandidates()` (게임 상태 재계산; 상태 변화 시 즉시 갱신)
  - 아니면 기존 단일 `[highlightedMove]`
- `func toggleAllHints()` / `func setAllHints(_:)`, `isSeen(showAllHints)`.

사실은 더 단순하게:
```
var displayedHintMoves: [Move] { showAllHints ? currentHintCandidates : highlightedMove.map { [$0] } }
```
- `currentHintCandidates` : 기존 `hint()`에 있는 candidates 산출 로직을 공용 함수로 추출 제출(불후 게임별).

### 2.3 뷰 강조 (GameBoardView)
- 기존 소스 헬퍼들(`isHintSource`, `isKlondikeHintSource`, … 12개)은 현재 `vm.highlightedMove` 단일만 검사.
- 이를 `vm.displayedHintMoves`(여러 Move)에 대해 "이동이 해당 위치를 **소스**로 하는지"로 일반화.
  - 각 헬퍼 내부를 `displayedHintMoves.contains { matchesSource($0, …) }` 로 변경. (12개 헬퍼 내부 수정, 시그니처 불변)
- 홈/프리셀/스톡/웨이스트 소스도 동일 적용 (홈 소스, Klondike 홈, Forty 홈 등).
- 강조색은 기존 노란 테두리 `isHintSource`와 동일 유지 (재사용). 차이는 소스이 확인 대상이 단일 vs 다중.
- `isXxx` 스타일은 색상 유지, `showAllHints`면 소스 강조가 더 진해지는 등 편차 없이 동일 색 사용(혼동 방지).

### 2.4 GameCommands 단축키
- "전체 힌트" 메뉴 항목 `⇧⌘H` (`keyboardShortcut("h", modifiers: [.command, .shift])`)

## 3. 아키텍처

```
Sources/PureSolitaire/ViewModels/FreeCellViewModel.swift
    + @Published showAllHints, displayedHintMoves, currentHintCandidates(), toggleAllHints(), clearAllHints()
Sources/PureSolitaire/Views/GameBoardView.swift
    13개 isXxxHintSource → displayedHintMoves 기반 contains 일반화
Sources/PureSolitaire/Views/SideBarView.swift     "전체 힌트" 토글 버튼 (isActive)
Sources/PureSolitaire/Views/GameCommands.swift    "전체 힌트"(⇧⌘H) 메뉴 + 체크
```

## 4. 구현 단계

- [x] T-175: VM 상태 — `showAllHints` + `currentHintCandidates()`(hint 후보 공용 추출) + `displayedHintMoves` + 토글/해제(이동·새 게임 시 해제)
- [x] T-176: GameBoardView 소스 헬퍼 13개(홈/프리셀/열/스톡·웨이스트)를 `displayedHintMoves` 기반으로 일반화
- [x] T-177: SideBar "전체 힌트" 토글 버튼(isActive) + GameCommands `⇧⌘H` 메뉴 + 빈 상태 처리
- [x] T-178: 회귀(178개 유지) + `swift build`(debug·release) 경고 0 + release 설치·실행(VERSION 3.14.0, PID 27391) + 문서(PLAN/TODO/DESIGN/CHANGELOG/tests/session)

## 5. 테스트 계획

- **자동**: 기존 178개 전부 통과(회귀). 표시 계층 변경이라 GameCore 단위 테스트 추가 최소화 — 후보 추출 헬퍼는 VM이라 테스트 범위 밖이나 회귀 수준 확인.
- **수동 (AX/txt)**: 
  - FreeCell/Klondike 등에서 ⇧⌘H → 유효한 소스가 여러 조각 동시 노랑 강조(단일 힌트와 구분)
  - ◙H 단일 순환/Enter는 현행대로 동작
  - 이동/새 게임/전환 시 해제, 재토글로 다시 표시
  - (텍스트 전용 모델: 스크린샷 대신 a11y/storage 덤프 + 프레임 로그 검증)

## 6. 롤백 계획
- `git revert` 해당 커밋. 표시 계층만 추가되고 저장/GameCore 무변경 → 롤백 안전.
- 해제 조건을 빠뜨리면 강조가 남을 수 있으니 apply() 연결 지점에 항상 `setAllHints(false)` 배치.

## 7. 성능/영향
- 전체 힌트 표시 시 후보 수만큼 contains 판정(≤ 최대 수백 그룹) — 보드 재렌더 시 loop정 간단한 비용. 힌트 애니메이션과 무관.
- GameCore/저장/약영향 없음.