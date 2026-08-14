# PLAN v3.22 — 홈 화면 + 게임 카테고리/난이도 그룹화 + 게임 중 난이도 표시 (macos)

> platform: macos · 버전: 3.22.0 · 작성: 2026-08-14 · 근거: 사용자 피드백 "처음 화면이 없네, 골라서 갈 수 있는 게 있어야지" + "카테고리/난이도 순서" + "게임 중 난이도 표시" → 사용자 결정 반영

## 1. 개요

현재 앱은 실행 즉시 게임판(SideBar + GameBoard)이 표시되어 게임을 "골라서 시작"하는 화면이 없다. v3.22에서는:

- **A. 홈 화면**: 앱 시작 시 게임 선택 화면이 먼저 표시. 12종 게임을 카테고리 4그룹 + 그룹 내 난이도순으로 나열. 타일 클릭 시 해당 변형 게임 진입. 사이드바 "홈" 버튼으로 언제든 복귀.
- **B. 카테고리/난이도 정렬**: `GameVariant`에 표시 전용 속성(`category`/`baseDifficulty`/`categoryOrder`) 추가. `allCases` 순서(enum 선언 순서)는 데일리 셔플/단건 순환 매핑이 의존하므로 변경하지 않는다.
- **C. 게임 중 난이도 표시**: 게임판 정보 영역(게임 번호 아래)에 변형 고정 난이도 뱃지 표시.

## 2. 결정 사항

1. 홈 화면은 **앱 시작 시 항상 먼저** 표시 (사용자 선택)
2. 홈 진입 항목은 **전체 포함**: 게임 그리드 + 데일리 도전 + 게임 번호 + 무작위 + 통계/업적/설정
3. 게임 타일 순서는 **카테고리 4그룹 + 그룹 내 난이도순** (사용자 선택)
4. 난이도 값은 **변형별 고정값**(`baseDifficulty`) (사용자 선택)
5. `allCases` 순서 변경 금지 — 표시 전용 정렬 속성만 추가
6. 게임 중 난이도는 **변형 고정값** 표시 (FreeCell 계열 실측 `Difficulty.measure`는 판당 최대 8s라 게임 중 표시에 부적합)

## 3. 아키텍처

### 3.1 GameVariant 표시 전용 속성 (GameCore/GameVariant.swift)

```swift
public enum GameCategory: String, CaseIterable, Sendable {
    case freeCell   // FreeCell 계열
    case stock      // 스톡 계열
    case spider     // 스파이더 계열
    case removal    // 카드 제거
}

extension GameVariant {
    var category: GameCategory
    var baseDifficulty: Difficulty   // 변형별 고정 난이도 (easy/medium/hard)
    var categoryOrder: Int           // 동일 난이도 보조 정렬 (개발순)
}
```

### 3.2 난이도 매핑 (확정)

| 카테고리 | 게임 | 난이도 | categoryOrder |
|----------|------|--------|---------------|
| freeCell | FreeCell | medium | 0 |
| freeCell | Baker's Game | medium | 1 |
| freeCell | Sea Tower | hard | 2 |
| freeCell | Super FreeCell | hard | 3 |
| stock | Klondike | medium | 0 |
| stock | Yukon | hard | 1 |
| spider | Scorpion | easy | 0 |
| spider | Spider | medium | 1 |
| spider | Forty Thieves | hard | 2 |
| removal | Golf | easy | 0 |
| removal | Pyramid | medium | 1 |
| removal | TriPeaks | medium | 2 |

표시 순서: category(freeCell→stock→spider→removal) → difficulty(easy→medium→hard) → categoryOrder

### 3.3 화면 구성

```
Sources/PureSolitaire/Views/HomeView.swift          (신규) 홈 화면 — 카테고리 섹션 + 진입 항목
Sources/PureSolitaire/Views/GameSelectorView.swift  카테고리 섹션화 + 난이도 뱃지
Sources/PureSolitaire/Views/ContentView.swift       홈/게임 전환 (showingHome, 시작 시 홈)
Sources/PureSolitaire/Views/GameBoardView.swift     gameInfoView 난이도 뱃지
Sources/PureSolitaire/Views/SideBarView.swift       "홈" 버튼 추가
Sources/PureSolitaire/Views/GameCommands.swift      홈 단축키
```

## 4. 구현 단계 (T-번호)

- [x] T-222: `GameVariant` 표시 전용 속성 — `GameCategory` enum(4그룹) + `category`/`baseDifficulty`/`categoryOrder` + `homeOrderedVariants`(카테고리→난이도→순서 정렬). `allCases` 순서 변경 없음. GameVariantDisplayTests 4개 통과.
- [x] T-223: `GameSelectorView` 카테고리 섹션화 — `ForEach(GameCategory.allCases)` 섹션, 섹션 내 난이도순 정렬 + 난이도 뱃지(쉬움/보통/어려움 색상). 게임 번호 시트 재사용.
- [x] T-224: `HomeView` 신규 — 타이틀 헤더 + 빠른 진입(데일리 도전 ⌥⌘D / 게임 번호 ⌘G / 무작위 / 통계·업적·설정) + 카테고리 섹션 그리드(4열, 난이도 뱃지). 타일 클릭 → `onStartGame()` + `requestNewGame(variant:)`.
- [x] T-224a: 홈 "하던 게임 이어하기" 카드 — VM `restoredVariant`(init 복원 우선순위와 동일 순서로 저장 게임 형식 확인) + HomeView 상단 카드(게임명/번호/이동 표시, 클릭 → `onStartGame()`만 호출 = 복원된 게임 그대로 표시).
- [x] T-225: `ContentView` 홈/게임 전환 — VM `showingHome` 플래그(기본 true), `showingHome ? HomeView : SideBar+GameBoard`, opacity 전환 애니메이션, 시트/다이얼로그 상위 유지. 홈에서 창 타이틀 "Pure Solitaire".
- [x] T-226: 게임 중 난이도 표시 — `gameInfoView` 게임 번호 아래 난이도 뱃지(`vm.variant.baseDifficulty`), 접근성 라벨 포함.
- [x] T-227: 사이드바 "홈" 버튼(house, ⌘1) + GameCommands "게임" 메뉴 홈(⌘1) + VM `goHome()`.
- [ ] T-228: 회귀(`swift test -c release` 253개) + `swift build`(경고 0) + `build_and_run.sh release` 설치·실행(창 타이틀 "Pure Solitaire" = 홈 표시 확인) + 문서(CHANGELOG/TODO/DESIGN) + 릴리스 v3.22.0.

## 5. 테스트 계획

- **자동**: `GameVariant.category`/`baseDifficulty`/`categoryOrder` 매핑 테스트(신규), 정렬 순서 테스트. 기존 회귀 249개 (데일리 셔플/순환 매핑 무영향 확인).
- **수동**: 앱 시작 시 홈 표시, 카테고리/난이도순 나열, 타일 클릭 진입, 홈 복귀 버튼, 게임 중 난이도 뱃지.

## 6. 롤백 계획

- `git revert`. 신규 파일(HomeView) 제거, `showingHome` 제거, GameVariant 속성 제거(표시 전용이라 기존 로직 무영향).

## 7. 성능/영향

- 홈 화면: 정적 속성 정렬 — 수 ms.
- 게임 중 난이도: 고정값 표시 — 추가 계산 없음.
- 데일리 9판 구성/단건 순환 매핑: `allCases` 원본 유지로 무영향.