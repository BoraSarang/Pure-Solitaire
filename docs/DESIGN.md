# Pure FreeCell — 기술 설계 문서 (DESIGN)

## 1. 아키텍처 개요

```
┌─────────────────────────────────────────────────────┐
│                  Pure FreeCell.app                   │
│                                                     │
│  ┌───────────────────────────────────────────────┐  │
│  │  PureFreeCell (SwiftUI 앱 계층)               │  │
│  │  - 앱/씬, 뷰, 뷰모델, 상호작용(드래그), 설정   │  │
│  └──────────────────┬────────────────────────────┘  │
│                     │ (GameRule 프로토콜)           │
│  ┌──────────────────▼────────────────────────────┐  │
│  │  GameCore (플랫폼 독립 게임 엔진)             │  │
│  │  - Card / Suit / Rank / Deck                  │  │
│  │  - MicrosoftRNG + DealGenerator (시드 딜)     │  │
│  │  - GameRule 프로토콜 + FreeCellRule           │  │
│  │  - Move/Undo/Hint/AutoPlay                    │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

- **GameCore**: 순수 로직 계층 (SwiftUI/AppKit 미사용, 플랫폼 독립, 단위 테스트 대상)
- **PureFreeCell**: macOS SwiftUI 앱 계층 (GameCore를 소비)
- 추후 다른 게임 형식(스파이더/솔리테어 등)은 `GameRule` 프로토콜 구현체로 추가

## 2. 모듈 구조 (SwiftPM)

```
Package.swift
Sources/
  GameCore/
    Card.swift          # 카드 모델
    Suit.swift          # 무늬 (♣ ♦ ♥ ♠, 색 판별)
    Rank.swift          # 랭크 (A~K, 순서, 다음/이전 랭크)
    Deck.swift          # 52장 덱 생성
    MicrosoftRNG.swift  # MS LCG (state*214013+2531011) mod 2^31, >>16
    DealGenerator.swift # 게임 번호 → 셔플 → 8열 배치
    GameRule.swift      # 게임 규칙 추상 프로토콜
    FreeCellRule.swift  # 프리셀 규칙 구현 (이동 검증/수퍼무브/승리/힌트)
    FreeCellGame.swift  # 게임 상태 + Undo 스택 + 상태 전이
    AutoPlay.swift      # 안전 카드 홈셀 자동 이동 판정
  PureFreeCell/
    PureFreeCellApp.swift
    Models/AppState.swift          # 전역 상태 (Observable)
    ViewModels/FreeCellViewModel.swift
    Views/GameBoardView.swift
    Views/CardView.swift           # 커스텀 벡터 카드 렌더링
    Views/PileViews.swift          # 타블로/프리셀/홈셀 뷰
    Views/GameNumberSheet.swift    # 게임 번호 선택
    Views/StatsView.swift
    Views/SettingsView.swift
    Interaction/DragModel.swift    # 드래그 앤 드롭 + 클릭 이동
    Persistence/UserSettings.swift # UserDefaults
    Persistence/StatsStore.swift   # 통계 저장
Resources/ (AppIcon 등)
Tests/
  GameCoreTests/
    MicrosoftRNGTests.swift        # 게임 #1/#617 딜 검증
    FreeCellRuleTests.swift        # 이동 규칙/수퍼무브/승리 판정
    DealGeneratorTests.swift
```

## 3. 게임 코어 설계

### 3.1 카드 모델
```swift
enum Suit: Int, CaseIterable { case clubs, diamonds, hearts, spades
  var color: CardColor { .red/.black }
}
enum Rank: Int, CaseIterable { case ace=1, two, ... king
  var next: Rank?; var previous: Rank?
}
struct Card: Equatable, Hashable, Identifiable { let suit: Suit; let rank: Rank }
```

### 3.2 마이크로소프트 RNG + 딜
- LCG: `state = (state * 214013 + 2531011) & 0x7FFFFFFF`, `rand = state >> 16`
- 셔플: 카드 배열 `[51...0]`, `for i in 0..<51: j = 51 - (rand % (52 - i)); swap(cards[i], cards[j])`
- 게임 번호 범위: 1 ~ 1,000,000
- 딜: 셔플된 순서를 8열에 위→아래, 왼→오 교대로 배치 (4열 7장, 4열 6장)
- **검증**: 게임 #1, #617의 딜 결과 문자열을 하드코딩 기대값과 비교하는 테스트

### 3.3 FreeCellRule (이동 검증)
- `canMove(card, to tableauColumn)`: 내림차순 + 교대 색 (빈 열 허용)
- `canMove(card, to home)`: 같은 무늬 + A 시작 + 이전 랭크 존재
- `canMove(card, to freeCell)`: 빈 칸만
- `moveableRun(from column, length)`: 맨 아래에서 연속 내림차순+교대색 시퀀스
- `supermoveCapacity(emptyFreeCells, emptyColumns, destinationIsEmpty) = (F+1) × 2^C`
- 홈셀에서 다시 꺼내기 허용 (MS 규칙)

### 3.4 게임 상태 + 실행 취소
```swift
final class FreeCellGame {
  var columns: [Column]  // 8개, Column = [Card]
  var freeCells: [Card?] // 4칸
  var homes: [Home]      // 4칸, Home = [Card]
  private var undoStack: [Move] = []
  private var redoStack: [Move] = []
  var moveCount: Int
  func apply(_ move: Move) throws
  func undo(); func redo()
}
```
- 모든 이동은 `Move` 값으로 기록 → 실행 취소/다시 실행이 역연산으로 동작
- 이동은 홈셀에서 꺼내는 것까지 포함 (역연산 가능)

### 3.5 자동 플레이(AutoPlay) 안전 판정
- MS 규칙: 에이스는 항상 안전. 특정 카드 위에 겹칠 수 있는 카드(다음 랭크, 반대 색)가 모두 이미 홈셀에 있거나 곧 갈 수 있는 경우 안전
- `AutoPlay.autoMovableCards(game) -> [Card]` — 안전한 카드만 반환

### 3.6 변형 게임 구조 (병렬)
- FreeCell/Baker's/Sea Tower/Super FreeCell은 `FreeCellGame` + `variant` 분기 (프리셀+홈셀+타블로+수퍼무브 공유)
- Klondike/Spider/Yukon/Forty Thieves는 각각 독립 struct (`KlondikeGame`/`SpiderGame`/`YukonGame`/`FortyThievesGame`) — ViewModel `@Published` 5-way 분기로 디스패치
- 공통 `Move` 케이스 재사용 (Forty Thieves: `columnToColumn`/`columnToHome`/`drawFromStock`/`wasteToColumn`/`wasteToFoundation`)

### 3.7 Forty Thieves (v3.5)
- **규칙**: 2덱 104장, 10열×4장(전부 앞면) + 스톡 64장, 탭=1장 드로→웨이스트(**재활용 없음**), 홈셀 8개(2덱 수트당 2홈) A→K, 같은 수트 K→A 내림차순, 빈 열엔 아무 카드
- `columns: [[Card]]` (전부 앞면이라 `faceUp` 불필요) — `canPlaceOnColumn(card, column) = card == last.previous && card.suit == last.suit || last == nil`
- `homeIndex(card)`: A=빈 홈 우선, 그 외 같은 수트 `top.rank.next == card.rank`인 홈
- **그룹 이동 검증**: `canMove(.columnToColumn)`은 `moving[moving.count - cardCount]`(이동할 그룹의 맨 위)로 검증 (시퀀스 맨 위 `moving[0]`가 아님 — T-101 테스트가 발견한 버그)
- hint 우선순위: 홈 > 웨이스트→열 > 열→열 > 드로
- GameSaver `persistence.savedFortyThieves` 별도 키, 통계/기록은 `variant.rawValue` 자동 분리

### 3.8 Golf (v3.6)
- **규칙**: 1덱 52장, 7열×5장(전부 앞면) + 스톡 16장 + 웨이스트 1장, 웨이스트 맨 위와 **1 차이/같은 랭크**(수트 무관, **K↔A 인접 순환**)인 열 맨 아래 카드를 웨이스트로 제거, 열 간 이동 없음, 빈 열 재사용 없음, 스톡 재활용 없음
- **이동**: `Move.columnToWaste(columnIndex:card:)` + `Destination.waste` (드래그 목적지) 추가
- `isAdjacent(card, to top)`: `|a-b| == 1 || a == b || (13,1)/(1,13)`
- **승리** = 7열 모두 비어있음, **종료 판정** = `hint() == nil` (스톡 소진 + 제거 불가)
- 자동 플레이 없음 (제거 기반)
- GameSaver `persistence.savedGolf` 별도 키

### 3.9 Pyramid (v3.7)
- **규칙**: 1덱 52장, **피라미드 28장**(7줄: 1+2+3+4+5+6+7) + 스톡 24장(웨이스트 0장 시작), 카드 값 A=1~K=13, 노출 카드만 이동
- **노출 판정**: `pyramid: [Card?]` 28슬롯 — row r은 r+1장, `rowStart(r) = r*(r+1)/2`. 카드 i는 남아있고 아래 두 자식(`rowStart(row+1)+pos`, `+1`, row<6일 때)이 모두 nil이면 노출. 7번째 줄은 항상 노출
- **이동**: 합이 **13**인 노출 카드 제거 — `Move.pyramidRemovePair(first:second:)`(피라미드 2장) / `.pyramidRemoveWastePair(card:)`(피라미드+웨이스트) / `.pyramidRemoveSingle(card:)`(**K 단독**), `drawFromStock` 재사용(재활용 없음)
- **승리** = 피라미드 전부 nil, **종료 판정** = `hint() == nil`
- `CardSource.pyramid(Int)` 추가 — 선택/드래그에 사용. hint 우선순위: K 단독 > 피라미드 짝 > 웨이스트 짝 > 드로
- 자동 플레이 없음 (제거 기반)
- GameSaver `persistence.savedPyramid` 별도 키

### 3.10 TriPeaks (v3.8)
- **규칙**: 1덱 52장, **3개 피크**(각 4줄: 1+2+3+4 = 10장 × 3 = 30장) + 웨이스트 1장(딜 시 오픈) + 스톡 21장, 노출 카드만 이동
- **노출 판정**: `peaks: [Card?]` 30슬롯(peak*10+local), 피크 내 `rowStart = [0,1,3,6]`. 카드 local i는 남아있고 아래 두 자식이 모두 nil이면 노출. 마지막 줄(로컬 6~9)은 항상 노출
- **이동**: 노출 카드가 **웨이스트 맨 위와 정확히 1 랭크 차이**(수트 무관, 같은 랭크·K↔A 순환 제외)면 웨이스트로 제거 — `Move.triPeaksRemove(card:)`, `drawFromStock` 재사용(재활용 없음)
  - Golf(`1 차이|같은 랭크|K↔A`)와 달리 **1 차이만** — 표준 TriPeaks 규칙
- **승리** = 3개 피크 전부 nil, **종료 판정** = `hint() == nil`
- `CardSource.triPeaks(Int)` 추가 — 탭 즉시 제거(선택 개념 없음) + 드래그=웨이스트 드롭. hint 우선순위: 피크 제거 > 드로
- 자동 플레이 없음 (제거 기반)
- GameSaver `persistence.savedTriPeaks` 별도 키

### 3.11 유동적 게임 전환/옵션/통계 (v3.9)
- **랜덤 게임 전환**: `ViewModel.switchToRandomGame()` — `GameVariant.allCases.filter { $0 != variant }.randomElement()` → `requestNewGame(variant:)` (진행 중이면 확인 다이얼로그 재사용). 사이드바 "게임 전환"이 하드코딩 순환 switch 대신 사용. 게임이 늘어나도 자동 확장
- **선언적 변형 옵션 모델**: GameCore `GameOption`(id/title/choices) + `GameOptionChoice`(id/title) — `GameVariant.optionDefinitions`에 각 게임이 필요한 옵션을 선언 (현재 유일: Spider 난이도 1/2/4수트). 게임 번호 시트와 설정 "게임별 옵션"이 `optionDefinitions`를 순회해 자동 렌더링
- **GameOptionsStore** (UserDefaults, 키 `gameOptions.{variant}.{optionID}`): 옵션 선택값 영구 저장. `spiderDifficulty`를 `@Published`에서 스토어 기반 computed로 이전 (단일 진실 소스, 다음 게임부터 적용)
- **통계 뷰**: `.segmented` 12세그먼트 → 스크롤 List — 상단 전체 요약 고정 + `GameVariant.allCases` 게임별 요약 행(선택 시 최단 승리/최근 승리 10건 펼침), 기본 선택 = 현재 게임. `StatsStore`는 변형별 키(`stats.{variant}.{key}`) + `resetAll`이 `allCases` 순회 — 게임 추가 시 자동 확장

### 3.12 게임 선택 미리보기 그리드 (v3.10)
- **범위**: 게임번호 시트의 "게임 형식" 픽커만 교체. 사이드바 랜덤 전환/설정 유지.
- `GamePreviewKind`(.columns/.pyramid/.triPeaks) + `GamePreviewLayout`(columns/homes/freeCells/hasStock/hasWaste/hasFaceDown/stockPiles): `layout(for:)`가 게임 클래스 static 상수 재사용 (`FreeCellGame.columnCount(for:)/freeCellCount/homeCount`, `KlondikeGame.columnCount/homeCount`, `SpiderGame.columnCount/stockPiles`, `YukonGame.columnCount`, `FortyThievesGame.columnCount/homeCount`, `GolfGame.columnCount`, `TriPeaksGame.rowsPerPeak`) — 새 게임 자동 확장, 중복 없음
- `GamePreviewCard`: 0.7 비율 카드 타일(흰 면 + 선택 시 파랑 3px 테두리) 안에 `boardColor`(현재 배경색) 펠트 + `MiniBoard` 미니 카드/슬롯 배치
- `MiniBoard`: 열 기반(상단 슬롯 = 스톡/웨이스트/홈/프리셀/완성 + 하단 열 카드), 피라미드(7줄), 트리피크(3피크×4줄) 3종 레이아웃
- `GameSelectorView`: `LazyVGrid` 3열(flexible, spacing 14/16) + ScrollView, `GameVariant.allCases` 순회. `GameTile`(호버 scale 1.04, 선택 시 파랑 게임명/테두리, `.isSelected` 트레잇) 탭 → `selection = variant` (선택만 변경, 게임 시작 아님)
- GameNumberSheet: `GameSelectorView(selection:boardColor:)` `.frame(width: 440, height: 420)` 삽입. 옵션(`optionDefinitions`)은 기존 자동 렌더링 유지

### 3.13 설정 색상/패턴 미리보기 (v3.11)
- **범위**: 설정 시트의 카드 스타일/배경/카드 뒷면 3개 선택을 텍스트 `.segmented` → **실제 색·패턴 미리보기 셀**로 교체. 게임 화면 렌더링 로직 불변.
- `SettingPreviewViews.swift`(신규):
  - `CardBackArtwork(tint:accent:)` — 카드 뒷면 패턴(중앙 다이아몬드 + 원). `CardView.backView`에서 추출해 게임 보드와 설정 미리보기가 **동일 패턴** 사용 (중복 제거)
  - `PreviewCell` — 공용 탭 셀: 콘텐츠 + 파랑 테두리(선택 3pt/비선택 1pt) + 라벨 + `.accessibilityLabel`/`.isSelected` 트레잇
  - `MiniCardFaceView(style:)` — 카드 스타일 미리보기용 미니 앞면 (클래식=흰색+serif+회색 테두리, 심플=연회색+rounded — `CardView`와 동일 색/폰트 재현)
  - `CardStylePicker`(2셀) / `BackgroundStylePicker`(4셀) / `CardBackPicker`(3셀) — `HStack` 1행, 셀 콘텐츠 사전 프레임
- `UserSettings.backgroundColor(for:)`를 `static func color(for style:)`로 분리해 설정 미리보기/보드 렌더 공용 (단일 진실 소스). 선택 변경은 `@AppStorage` 즉시 반영 → 보드/카드 실시간 갱신
- 디자인 토큰 체계: `BackgroundStyle.color(for:)` / `CardBack.tint/accent` / `CardStyle`(폰트·색) — 설정 UI와 게임 화면이 동일 토큰 참조

### 3.14 통계 선택 요약 / 힌트 드래그 애니메이션 / 자동 플레이 상태 표시 (v3.12)
- **통계 상단 요약 대상 토글** (`StatsView`): 상단 `Picker("요약 대상", .segmented)` "전체 | 선택" 추가. 기본 `.selected`. 선택 모드에서는 `selected == vm.variant`(시트 onAppear에서 현재 게임 미리 선택) 요약 카드에 **최단 승리**(`bestTime`) 포함, 전체 모드에서는 `allTotalGames` 등 합계 표시. 하단 게임 행 탭은 `selected` 토글(해제 시 전체로 폴백) — 행 아래 상세 펼침(최단 승리 + 최근 승리 10건) 현행 유지.
- **힌트 드래그 애니메이션** (`GameBoardView` + `FreeCellViewModel`):
  - VM에 `@Published hintAnimationMove: Move?` + `hintAnimationTick` 추가. `hint()`가 최우선 이동을 `hintAnimationMove`에 기록 후 `hintAnimationTick += 1`. 이동/취소/새 게임 시 `hintAnimationMove = nil`.
  - `GameBoardView.onChange(of: vm.hintAnimationTick)` → `runHintDragAnimation(boardSize:cardSize:)`: `hintGeometry(for:)`로 소스 카드 묶음(`hintCards`)·소스 원점(`cardBoardOrigin`)·목적지 원점(`destinationOrigin`) 계산해 `HintDragGeometry(cards:from:to:)` 생성, `hintDragTask`(Task)로 **소스→목적지 왕복 2회** 애니메이션(각 0.45s easeInOut + 180ms 간격). `apply` 호출 없음 → 보드 불변.
  - `hintSourceDestination(for:)`: `columnToColumn/columnToHome/freeCellToColumn/freeCellToHome/homeToColumn/columnToWaste/wasteToColumn/wasteToHome/pyramidRemove/triPeaksRemove`는 드래그 대상, 스톡/플립류(`drawFromStock`/`recycleStock`/`dealFromStock`/`flipColumnCard`)는 **nil**(하이라이트만 유지).
  - 오버레이: `hintDragOverlay`가 실제 카드 묶음을 스택으로 렌더(그림자, hitTest 불가, a11y hidden). `cancelHintDrag()`(이동/새 게임/시트 닫힘 시)가 Task 취소 후 정리.
- **자동 플레이 상태 표시** (`SideBarView` + `GameCommands`):
  - `SideBarButton`에 `isActive: Bool?`/`accessibilityValue` 파라미터 추가. `isActive == true`면 강조색(`Color.accentColor`) + `accessibilityValue "켜짐"`, `false`면 `opacity 0.5` + "꺼짐", 미지정이면 기존(비활성 흐림)과 동일.
  - 자동 플레이 버튼: `settings.autoPlayEnabled`로 상태 표시, 클릭 시 `.toggle()` + 켜지면 즉시 `vm.runAutoPlay()`. 설정 시트 "자동 이동" 스위치와 `@AppStorage` 자동 동기화.
  - `GameCommands` "자동 플레이"(⇧⌘A)도 같은 토글 동작으로 통일, 켜짐 시 `Label`에 `checkmark` 표시.

### 3.15 자동 완성 / 이동 수 통계 / Klondike 스톡 드로 (v3.13)
- **승리 자동 완성(Auto-finish)** (`FreeCellViewModel.runAutoFinish()`):
  - 트리거: `apply(_:)` 성공 직후 — `settings.autoFinishEnabled` && `autoFinishConditionHolds()`(홈셀 중심 게임이 **승리 직전 상태** `canAutoFinish`)면 `runAutoFinish()` 실행. spider/golf/pyramid/triPeaks는 제외.
  - 동작: `homeMovesOnlyFilter()`로 홈 이동 후보만 반복 적용(최대 500회 가드), `applyRaw` 경유 — `applyRaw`가 게임의 `apply`를 호출하므로 **undo 스택에 포함**(중간 복귀 가능). 종료 후 `checkState()`+`persist()`.
  - 후보: Klondike는 `columnToHome`+`wasteToFoundation`, Yukon은 `columnToHome`, FortyThieves는 `columnToHome`+`wasteToFoundation`, FreeCell 게임은 `AutoPlay.safeAutoPlayMoves`(안전 규칙) 우선, 비어 있으면 `hintCandidates().homeMove` 폴백.
  - 설정: `UserSettings.autoFinishEnabled`(@AppStorage, 기본 true) — 게임플레이 설정 "승리 자동 완성" 토글.
- **이동 수 통계** (`StatsStore` + `RecordStore`):
  - `StatsStore.Entry`에 `totalMoves: Int`·`leastMoves: Int?` 추가(`avgMoves`는 `totalMoves/wins` 반올림 computed). 전체 합계와 변형별 키(`stats.{variant}.{key}`) 모두 기록.
  - `StatsStore.recordWin(_:moves:)` — 승리 시 이동 수 집계 + 최소 갱신(0 제외). `resetAll`이 새 키 포함 제거.
  - `RecordStore.GameRecord`에 `moves: Int`(=0) 추가 — 기존 Codable `decodeIfPresent` 기본 0으로 하위 호환, VM이 승리 직전 `currentMoveCount` 저장 → StatsView에 최근 승리 이동 수 표시.
- **Klondike 스톡 1·3장** (`KlondikeGame.drawMode`):
  - `GameVariant.klondike.optionDefinitions`에 `GameOption(id: "klondikeDraw", choices: "1장"/"3장")` 추가 — 게임 번호 시트/설정의 `optionDefinitions` 자동 렌더 재사용.
  - `KlondikeGame.drawMode: Int`(init 기본 1, `==3 ? 3 : 1` 정규화) + Codable `decodeIfPresent ?? 1` — 기존 저장 호환.
  - `drawFromStock`: `min(drawMode, stock.count)`장을 스톡에서 웨이스트로 이동(잔량은 그 장수만). `canMove`/recycle 동일.
  - VM: `klondikeDrawMode` computed가 `gameOptions.selectedID(for:optionID:)`에서 읽음 → `newGame`에 전달, `restoreKlondike` 시 저장된 `drawMode`로 설정 옵션 동기화.

### 3.16 전체 힌트 강조 (v3.14)
- **목적**: 유효 이동 전체의 소스를 동시에 강조 — 기존 단일 힌트 순환(⌘H)과 병행하는 독립 모드.
- **VM 상태** (`FreeCellViewModel`):
  - `@Published showAllHints: Bool` — 전체 힌트 모드 토글(세션 상태, 영구 저장 안 함).
  - `currentHintCandidates()` — 기존 `hint()`/`runAutoPlay()` 내 게임별 후보 산출 로직을 공용 메서드로 추출(모든 변형의 `hintCandidates()` 재사용).
  - `displayedHintMoves: [Move]` — `showAllHints`면 `currentHintCandidates` 전체, 아니면 `[highlightedMove]`(또는 빈 배열). 뷰 소스 판정의 단일 진실 소스.
  - `toggleAllHints()`/`clearAllHints()` — 토글 시 메시지 표시, 해제 시 강조 제거. 이동 적용(`apply`)·새 게임(`newGame`) 경로에서 자동 해제.
- **뷰 소스 일반화** (`GameBoardView`): 소스 강조 판정 함수 13개(`isHintSource`/`isKlondikeHintSource`/…/홈·프리셀 소스)가 단일 `highlightedMove` 스위치에서 `displayedHintMoves` 기준 `contains` 검사로 변경 — 동일 로직(카드 위치 매칭)이 단일/전체에서 공용 동작.
- **진입점**: 사이드바 "전체 힌트" 토글 버튼(`isActive`) + 게임 메뉴 "전체 힌트"(⇧⌘H). 설정은 세션 토글로만(영구 기본값 없음).

### 3.17 커스텀 배경 / 카드면 (v3.15)
- **커스텀 배경** (`BackgroundStyle.custom`):
  - 저장: 선택 이미지를 `Application Support/Pure Solitaire/custom-background.png`로 PNG 변환 후 원자적 저장(`setCustomBackground(from:)`). 경로는 `@AppStorage("settings.customBackgroundPath")`로 유지, 파일 누락 시 `fileExists` 가드로 폴백.
  - 렌더: 공용 `BackgroundLayer` 뷰 — `.custom` + `customBackgroundImage`(NSImage 로드) 있으면 이미지(`scaledToFill`+`clipped`), 아니면 `UserSettings.color(for:)`. `GameBoardView`/`ContentView`의 `.background`에 공용 사용.
  - 제거: `removeCustomBackground()` — 파일 삭제 + 경로 초기화 + `.green` 복귀.
  - UI: `BackgroundStylePicker` 커스텀 셀(축소 이미지/`photo` 아이콘) + SettingsView "이미지 선택…"(NSOpenPanel)/"제거" 버튼.
- **카드 뒷면 5종** (`CardBack`): classic/blue/gold + ocean/forest. tint/accent 토큰만 추가 → `CardBackArtwork`/`CardView.backView` 자동 반영.
- **카드 앞면 4종** (`CardStyle`): classic/simple + retro(세리프+아이보리) / deep(다크 배경+밝은 면색). `CardView`의 background/borderColor/fontDesign/faceForeground 분기 + `SuitSymbolView(foreground:)` 주입, `MiniCardFaceView` 동일 재현.

### 3.18 데일리 딜 (v3.16)
- **목적**: 날짜를 결정적 시드로 변환해 하루 1개 고정 게임 제공 — 기존 게임 번호(시드) 파이프라인 재사용.
- **`GameCore/DailyDeal.gameNumber(for:variant:)`**: 날짜 순번(`Calendar.ordinality(of: .day, in: .era)`) + 변형 rawValue 해시(djb2)를 결정적 혼합(오버플로 XOR/곱)해 `1...DealGenerator.maxGameNumber` 범위 시드 생성. 같은 날짜+변형이면 항상 같은 번호, 변형별 독립.
- **VM `startDailyDeal()`**: `DailyDeal.gameNumber(for: Date(), variant:)` → `requestNewGame(number:variant:)` 경유(진행 중 확인 다이얼로그 + 통계/자동플레이/딜 연출 재사용).
- **진입점**: 사이드바 "데일리 딜"(calendar, ⌘D) + 게임 메뉴 "데일리 딜"(⌘D). 승리/통계는 일반 게임과 동일 처리(시드가 게임 번호로 기록).

## 4. UI 설계 (SwiftUI)

### 4.1 카드 커스텀 벡터 렌더링
- `CardView`: RoundedRectangle 배경 + 랭크 텍스트 + 무늬 심볼(커스텀 Shape)
- 무늬는 `♣ ♦ ♥ ♠` 글리프 또는 Shape로 그리기, 색은 빨강/검정
- 스타일: `클래식`(흰 배경, 검정/빨강) / `심플`(flat)
- 카드 크기는 보드 크기에 따라 비례 (GeometryReader + 카드 가로세로비 0.7)

### 4.2 게임 보드 레이아웃
- 상단 줄: 홈셀 4개(왼쪽) + 가변 공간(게임 번호 표시) + 프리셀 4개(오른쪽)
- 하단: 8개 타블로 열, 카드 겹침은 상단 10% 오버랩
- 카드 애니메이션: `withAnimation`으로 이동 전환
- 승리 시: 남은 카드가 홈셀로 순차 자동 이동 + 축하 표시

### 4.3 드래그 앤 드롭
- `.draggable` / `.dropDestination` (macOS 13+, SwiftUI 네이티브) 또는 커스텀 드래그
- 드래그 시작 시 선택된 카드 시퀀스 + 가능한 수퍼무브 길이 계산
- 유효한 드롭 대상은 하이라이트, 무효는 원위치
- 클릭 1회 선택 → 클릭 2회 목적지 (보조 조작)

### 4.4 상태 관리
- `@StateObject FreeCellViewModel` (ObservableObject, @Published)
- 뷰모델이 `FreeCellGame`(GameCore)를 감싸고 UI 상태(선택, 드래그, 애니메이션)를 관리

## 5. 영구 저장

| 데이터 | 저장소 | 키 |
|--------|--------|-----|
| 설정 | UserDefaults | `settings.cardStyle` 등 |
| 통계 | UserDefaults | `stats.*` |
| 현재 게임 (자동 저장) | UserDefaults | `game.state` (선택적) |
| 최근 게임 번호 | UserDefaults | `game.lastNumber` |

## 6. 빌드 / 배포 파이프라인

### 6.1 빌드
- `swift build -c release` (또는 debug) — SwiftPM
- `swift test` — GameCore 단위 테스트 (딜 검증 포함)

### 6.2 .app 번들 생성 (`scripts/build_and_run.sh`)
```
1. swift build -c release --arch arm64
2. 번들 디렉터리 구성:
   Pure FreeCell.app/
     Contents/
       Info.plist
       MacOS/PureFreeCell          # 실행 파일
       Resources/AppIcon.icns
3. ~/Applications/Pure FreeCell.app 설치 (기존 제거 후 복사)
4. open 앱
```

### 6.3 Info.plist 핵심
- `CFBundleName`: Pure FreeCell
- `CFBundleExecutable`: PureFreeCell
- `CFBundleIdentifier`: com.pure.freecell
- `CFBundlePackageType`: APPL
- `LSMinimumSystemVersion`: 13.0
- `NSHighResolutionCapable`: true
- `NSPrincipalClass`: NSApplication

## 7. 성능 예산

| 지표 | 목표 |
|------|------|
| Cold Start | ≤ 1.5s |
| 메모리 | ≤ 300MB |
| 프레임 | 60fps (카드 이동 애니메이션) |
| 게임 번호 딜 생성 | < 1ms |

## 8. 테스트 계획

| 테스트 | 내용 |
|--------|------|
| MicrosoftRNGTests | 게임 #1/#617 딜 문자열 == MS 원본 |
| FreeCellRuleTests | 이동 유효성, 교대색, 수퍼무브 용량 공식, 홈셀 꺼내기 |
| DealGeneratorTests | 52장 모두 배치, 각 열 7/6장 구조 |
| AutoPlayTests | 안전 판정 규칙 |

## 9. 롤백 계획
- 빌드 실패 시: `~/Applications/Pure FreeCell.app` 이전 버전 복원 (백업 후 교체)
- 규칙 버그 시: 게임 코어 테스트 수정 후 재배포
- 게임 번호 딜 불일치 시: RNG/셔플 로직 검토 (게임 #1/#617 테스트로 즉시 탐지)
