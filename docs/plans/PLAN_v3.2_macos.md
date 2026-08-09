# PLAN v3.2 — Sea Tower + Super FreeCell 추가 — macOS

> 작성일: 2026-08-06 | platform: macos | 상태: 진행중

## 1. 개요

보류(T-030)되어 있던 변형 프리셀 2종을 추가한다. 두 게임 모두 FreeCellGame 계열(프리셀+홈셀+타블로+수퍼무브)이므로 **FreeCellGame variant 확장**으로 구현한다 (Klondike/Spider처럼 병렬 struct가 아닌, `game.variant` 분기).

1. **Sea Tower** (Sea Towers/Seahaven Towers) — 1덱 52장, 10열×5장(50장)+프리셀 2장 시작 배치, 같은 수트 내림차순, 빈 열 K만, 프리셀 4개
2. **Super FreeCell** (Double FreeCell) — 2덱 104장, 10열, 교대색 내림차순, 빈 열 아무 카드, 프리셀 6개, 홈셀 수트당 26장(A→K×2)

## 2. 결정 사항

### D3.2-1 게임 변형 추가 방식
- `GameVariant.seaTower` / `GameVariant.superFreeCell` 추가. `FreeCellGame`이 variant로 딜/규칙 분기.
- ViewModel `game: FreeCellGame` 단일 보유 유지 (Klondike/Spider는 병렬 보유, FreeCell 계열은 기존처럼 variant 공유).

### D3.2-2 Sea Tower 규칙 (사용자 확인 완료)
- 딜: 52장 셔플 → 10열에 교대로 50장(각 5장), 카드 51·52번째 2장은 **프리셀 0, 1에 시작 배치**
- 빌드: **같은 수트** 내림차순 (K→Q→...)
- 빈 열: **K만** (K 또는 K로 시작하는 시퀀스)
- 프리셀 4개 (각 1장), 홈셀 4개 (A→K 같은 무늬)
- 수퍼무브: 빈 열을 임시 저장으로 못 쓰므로 **용량 = 빈 프리셀 + 1** (빈 열 기여 없음)

### D3.2-3 Super FreeCell 규칙 (사용자 선택: 2덱+10열+6프리셀)
- 딜: **2덱 104장** 셔플 → 10열 교대 배치 (첫 4열 11장, 다음 6열 10장)
- 빌드: **교대색** 내림차순 (표준 프리셀과 동일)
- 빈 열: 아무 카드/시퀀스
- 프리셀 6개 (각 1장), 홈셀 4개 — **각 홈 수트 고정, 26장** (A→K 후 다시 A→K)
- 수퍼무브: 표준 공식 (빈 프리셀+1) × 2^(빈 열), 프리셀 최대 6

### D3.2-4 Card ID 중복 대응 (Super FreeCell 2덱)
- 2덱이면 동일 카드가 2장 존재 → SwiftUI `ForEach(id: \.element.id)` 충돌 위험
- `freeCellColumnView`·`dragOverlay`의 ForEach id를 **`\.offset`** 로 변경 (Klondike/Spider와 동일 패턴)

### D3.2-5 홈셀 인덱스 (Super FreeCell)
- 홈셀 4개를 **수트 인덱스(suit.rawValue)에 고정**. `canMoveToHome`: top이 K이면 A 허용(2세트).
- Sea Tower는 기존 freecell 방식 유지 (빈 홈 아무거나 + suit 매칭)

### D3.2-6 자동 저장
- Sea Tower / Super FreeCell은 FreeCellGame 계열이지만 기존 freecell/bakers 저장을 덮어쓰지 않도록 **variant별 별도 키** 사용:
  - `persistence.savedSeaTower`, `persistence.savedSuperFreeCell`
- ViewModel init에서 restore 순서: spider → klondike → seaTower → superFreeCell → freecell

## 3. 구현 단계

### 1단계: GameCore
- [x] T-070: `GameVariant.seaTower`/`.superFreeCell` + `DealGenerator` 확장 (`seaTowerDeal`: 10열×5장+프리셀2장, `superFreeCellDeal`: 2덱 104장)
- [x] T-071: `FreeCellRule` 확장 — `canMoveToColumn`(seaTower 같은 수트+빈 열 K만, superFreeCell 교대색+빈 열 아무카드), `movableRun`(seaTower 같은 수트)
- [x] T-072: `FreeCellGame` 확장 — `columnCount(for:)`(seaTower/super=10), `freeCellCount(for:)`(seaTower=4, super=6), init variant별 딜(seaTower 프리셀 2장 배치), `supermoveCapacity`(seaTower 빈 열 무시), `isWon`(super 홈 26장), `canMoveToHome`/`homeIndex(for:)`(super 수트 고정+K→A 허용), Baker's 1장 제한 분기
- [x] T-073: 테스트 — `SeaTowerGameTests` (딜 구성/같은 수트/빈 열 K/수퍼무브 프리셀만/시작 프리셀 2장/승리/undo/Codable) + `SuperFreeCellGameTests` (104장/10열/프리셀6/홈26장/교대색/수퍼무브/승리/undo/Codable)

### 2단계: ViewModel/저장
- [x] T-074: `GameSaver` 확장 — `saveSeaTower`/`restoreSeaTower`/`clearSeaTower` + `saveSuperFreeCell`/`restoreSuperFreeCell`/`clearSuperFreeCell`
- [x] T-075: ViewModel — init restore 분기(seaTower→super→freecell), `persist()`/`clearSave()` variant 분기, 탭/드래그/힌트는 `game` 경유라 자동 적용

### 3단계: 보드/UI
- [x] T-076: `GameBoardView` — `columnCount`(variant 기반), `colFactor`(10.7), 상단행 프리셀 렌더를 `freeCellCount(for:)`로, `dragSource`/`dropTarget`/`cardBoardOrigin`/`freeCell` 프리셀 개수 파라미터화, `ForEach` id `\.offset` 변경
- [x] T-077: SideBar 게임 전환 6개 순환 + GameNumberSheet (allCases 자동) + moveDescription 없음(신규 Move 없음)
- [x] T-078: 회귀 + 신규 테스트, release 빌드/설치/실행 + 문서 갱신

## 4. 테스트 계획

- [x] TC-3.2-01: Sea Tower 딜 — 10열 각 5장, 프리셀 2장, 총 52장, 무중복
- [x] TC-3.2-02: Sea Tower 규칙 — 같은 수트만 쌓기, 다른 수트 거부, 빈 열 K만(비K 거부), K 시퀀스 허용
- [x] TC-3.2-03: Sea Tower 수퍼무브 — 빈 열이어도 용량 = 빈 프리셀+1 (빈 열 미반영)
- [x] TC-3.2-04: Sea Tower 승리/undo/redo/Codable
- [x] TC-3.2-05: Super FreeCell 딜 — 104장, 10열(11/11/11/11/10×6), 프리셀 6개, 중복 카드 2장씩
- [x] TC-3.2-06: Super FreeCell 규칙 — 교대색, 빈 열 아무 카드, 홈셀 26장(수트 고정, K 위에 A)
- [x] TC-3.2-07: Super FreeCell 수퍼무브 — (빈 프리셀+1)×2^(빈 열)
- [x] TC-3.2-08: Super FreeCell 승리/undo/redo/Codable
- [x] TC-3.2-09: 기존 72개 회귀 무손상

## 5. 롤백 계획

- GameCore/ViewModel/Board 모두 variant 분기 추가 → 기존 4개 게임 동작 무영향
- git revert + `swift build`/`swift test` + release 재설치
- 자동 저장 신규 키(seaTower/superFreeCell)만 추가 → 기존 키 무손상, 키 삭제로 롤백

## 6. 성능 예산

- Super FreeCell 104장: 열 최대 11장 → 높이 제한 동일(maxStackFactor 12 기준), 메모리 미미
- FreeCellGame Codable 크기 2배(2덱) — UserDefaults 용량 한도(1MB) 내 충분
- 힌트/수퍼무브 O(n²) 유지 (열 10개) — 미미

## 7. 에러코드

- 신규 에러코드 없음 (규칙 로직만 추가, 사용자 메시지 변화 없음)
