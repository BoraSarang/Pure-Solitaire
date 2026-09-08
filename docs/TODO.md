# TODO — 작업 추적

> platform: macos

## 진행 상태 범례
- [ ] 대기 / [x] 완료 / (진행중) 표시

## v3.12.1 — 리브랜딩 (완료 — 2026-08-09)
- [x] T-169: Pure FreeCell → Pure Solitaire / 순수한 솔리테어

## v3.13 — 코어 QoL: 자동 완성 / 이동 수 통계 / Klondike 스톡 1·3장 (완료 — 2026-08-09, PLAN_v3.13_macos.md)
- [x] T-170: 승리 자동 완성 — GameCore 판단(canAutoFinish) + VM runAutoFinish + UserSettings 토글 + apply 연결
- [x] T-171: 이동 수 통계 — StatsStore(least/max/avg) 확장 + RecordStore.moves + VM 승리 기록 + StatsView 표시
- [x] T-172: Klondike 스톡 1/3장 — KlondikeGame.drawMode + optionDefinitions 옵션 + VM 전달·복원
- [x] T-173: 테스트 추가 + 회귀(178개 통과) + swift build(debug·release) 경고 0
- [x] T-174: release 설치·실행(VERSION 3.13.0, PID 90472) + 문서 갱신 (PLAN/TODO/DESIGN/CHANGELOG)

## v3.14 — 전체 힌트 강조 (완료 — 2026-08-09, PLAN_v3.14_macos.md)
- [x] T-175: VM 상태 — showAllHints + currentHintCandidates()(hint 후보 공용 추출) + displayedHintMoves + 토글/해제(이동·새 게임 시)
- [x] T-176: GameBoardView 소스 헬퍼 13개(홈/프리셀/열/스톡·웨이스트)를 displayedHintMoves 기반으로 일반화
- [x] T-177: SideBar "전체 힌트" 토글 버튼(isActive) + GameCommands ⇧⌘H 메뉴 + 빈 상태 처리
- [x] T-178: 회귀(178개 유지) + swift build(debug·release) 경고 0 + release 설치·실행(VERSION 3.14.0, PID 27391) + 문서

## v3.15 — 커스텀 배경/카드면 (완료 — 2026-08-12, PLAN_v3.15_macos.md)
- [x] T-180: 커스텀 배경 — 저장/선택/제거/렌더(경로→Image) + feltTextBase 처리 + GameBoardView/ContentView 분기
- [x] T-181: 카드 뒷면 2종(오션/숲) tint/accent + 미리보기 자동 반영
- [x] T-182: 카드 앞면 2종(레트로/딥) CardView 스타일 분기 + 픽커 자동 반영
- [x] T-183: 회귀(178개 유지) + swift build(debug·release) 경고 0 + release 설치·실행(VERSION 3.20.0 빌드본) + 문서

## v3.16 — 데일리 딜 (완료 — 2026-08-12, PLAN_v3.16_macos.md)
- [x] T-184: DailyDeal 날짜→시드 매핑 + 단위 테스트 5개
- [x] T-185: startDailyDeal() VM 진입점
- [x] T-186: 사이드바 "데일리 딜" 버튼(⌘D) + 게임 메뉴 항목
- [x] T-187: 회귀(178+5) + swift build(debug·release) 경고 0 + release 설치·실행(VERSION 3.20.0 빌드본) + 문서

## v3.17 — 데일리 챌린지 + 업적 (완료 — 2026-08-12, PLAN_v3.17_macos.md)
- [x] T-188: DailyChallenge(변형/시드/별점) + ChallengeStore(완료 저장) + 테스트
- [x] T-189: Achievement 모델 + 판정 + AchievementStore + 테스트
- [x] T-190: VM + ChallengeView/AchievementsView + 사이드바/메뉴/시트 연결
- [x] T-191: 회귀(183+15) + swift build(debug·release) 경고 0 + release 설치·실행(VERSION 3.20.0 빌드본) + 문서

## v3.18 — Scorpion 변형 (완료 — 2026-08-12, PLAN_v3.18_macos.md)
- [x] T-192: ScorpionGame(7열×7장+예비 3장, 그룹 이동, 빈 열 K, 승리 K→A 4열) + scorpionDeal + dealReserve + 단위 테스트 9개
- [x] T-193: GameVariant .scorpion(displayName "Scorpion", 옵션 없음)
- [x] T-194: VM scorpion 상태 + init 복원 + newGame/apply/applyRaw/undo/redo/canUndo/canRedo/current*/persist/hint/자동완성 가드
- [x] T-195: GameSaver scorpion 저장/복원(clear 포함)
- [x] T-196: GameBoardView scorpionTopRow(예비 더미) + 열 렌더/탭/드래그/힌트 소스 분기 + GamePreviewCard
- [x] T-197: 회귀(207 = 198+9) + swift build 경고 0 + 문서

## v3.19 — 점수 체계 (완료 — 2026-08-12, PLAN_v3.19_macos.md)
- [x] T-198: Scoring(이동/승리/시간 점수, 변형별 상수) + ScoringTests 7개
- [x] T-199: VM score 누적(이동+스파이더 완성 보너스) + finalScore + undo/redo 롤백 + 새 게임 초기화
- [x] T-200: gameInfoView 현재 점수 + WinBanner 최종 점수 + StatsView 기록 점수
- [x] T-201: 회귀(214 = 207+7) + swift build 경고 0 + 문서

## v3.20 — Winnable 딜 (완료 — 2026-08-12, PLAN_v3.20_macos.md, 릴리스 v3.20.0)
- [x] T-202: `FreeCellSolver` — 상태공간 DFS(휴리스틱 + 방문 집합 + 노드/시간/깊이 예산) + `isWinnable(gameNumber:variant:)` + `firstWinnableGameNumber(from:variant:)` + FreeCellSolverTests 5개 — **솔버 완료 (깊이 예산 가지치기 버그 수정, 기본 예산 400k/4s 상향, 휴리스틱 개선으로 #1/#2 해결 — 11/13 true)**, #50은 해 존재(1.5M/10s 확인)하나 기본 예산 초과, #500은 5M/60s에서도 미해결 — 후속 과제
- [x] T-203: `GameVariant.optionDefinitions` — FreeCell 계열 4종에 `winnable` 옵션("일반"/"승리 보장") 추가 + GameOptionTests 갱신
- [x] T-204: VM — `isWinnableEnabled(for:)`(옵션 읽기) + `newGame(number:variant:)`에서 적용: 풀리는 번호 탐색(WinnableSearchBudget 100k/1.0s) 후 그 번호로 실제 시작(표시·저장·통계 반영)
- [x] T-205: 게임 번호 시트 안내 문구 + 회귀(220) + `swift build`(경고 0) + 문서
- [x] CI 수정: `DailyDealTests` 타임존 독립화(UTC 캘린더 고정 — KST/UTC 회귀값 불일치 해소) + `release.yml` 테스트를 `swift test -c release`로 변경(debug에서 FreeCell #2 예산 초과 회피)
- [x] 릴리스 v3.20.0: 태그 + GitHub Release (`Pure-Solitaire-3.20.0-macos.zip` 4.2MB, Release 워크플로우 성공)
- [ ] T-206: 솔버 휴리스틱 추가 개선 — #50(기본 예산 초과, 해는 존재) / #500(난제) 기본 예산 내 해결 — 예산 유지 결정으로 보류.
  - **2026-08-14 진행 중 갱신**: T-210 과정에서 무효 이동 버그 2건 수정(단일/그룹 bottom 카드 기준 + 유효 최대 그룹 탐색) + 진행(홈 카드) 없는 경로 가지치기(`maxStagnantDepth 80`)로 **#50 유효 해 703 이동이 재생 예산(2M/20s) 내 16.6s 해결**, **#500은 이제 기본 예산으로도 풀리는 게임으로 판명** — T-206 목표 대부분 해소됨.

## v3.24 — 일반/확장 모드 분리 (완료 — 2026-09-09, 커밋 e098d2b + 문서/푸시)
- [x] T-244: `GameMode` + `standardVariants`/`visibleVariants(mode:)` + 모드별 `deals` (일반 4판 고정/확장 9판 셔플).
- [x] T-245: 설정 모드 Picker (`settings.gameMode`, 기본 일반).
- [x] T-246: 선택 UI 필터 (홈/번호시트/랜덤/오늘딜).
- [x] T-247: 데일리 연동 (ChallengeView 모드 전달 + 기록 경로).
- [x] T-248: 전환 정책 명시 (게임 유지, 복원 예외 허용 — 코드 변경 없음).
- [x] T-249: 테스트 3개 + 회귀 263개 통과.
- [x] T-250: 문서/커밋/푸시 마무리 — 커밋 e098d2b에 CHANGELOG·PLAN_v3.24 포함, 푸시 완료.

## v3.25 — 보드 탭 라우팅 (진행중)
- [x] T-252: 보드 내 카드/스톡 탭 불능 해결 — 상위 `SpatialTapGesture` 좌표 라우팅 (Pyramid 실동작 확인, 회귀 267개 통과, 커밋 6c3d872).
- [x] T-253: 이중 발화 차단 — 자식 계층(카드/스톡/피라미드·트라이픽스 body) 히트 테스트 차단으로 포인터 탭은 라우터만, 접근성 활성화는 기존 유지 (회귀 267개 통과).
  - 남은 작업: FreeCell/Klondike 등 남은 변형 라이브 검증 — 디스플레이 슬립/잠금 상태로 GUI 검증 보류.

## v3.26 — 코드베이스 리팩토링 (완료 — 2026-09-09, 무동작 변경)
- [x] 스톡 탭 3종 중복 가드 제거 — FreeCellViewModel `tapGolfStock`/`tapPyramidStock`/`tapTriPeaksStock` → `apply(.drawFromStock)` 일원화 (커밋 abb7284).
- [x] undo/redo 중복 제거 — `UndoHistory<Snapshot>` 제네릭 공용화 (9개 게임: canUndo/canRedo/undo/redo/apply 기록 로직 축소). 저장 호환 유지 위해 각 게임 커스텀 Codable에서 기존 `undoStack`/`redoStack` 키 그대로 직렬화 (커밋 38182db).
- [x] 카드 무늬 색상 하드코딩 통일 — `Suit.uiColor` View 확장 (SuitSymbolView/미니카드/faceColor 값 통일) (커밋 5070461).
- [x] GameSaver 27개 보일러플레이트 축소 — variant→key 매핑 + 제네릭 `save/restore/hasData/clear` + `clearAll()`. 호출부(restoredVariant 캐시/init 11분기/persist/clearSave) 단일화 (커밋 c1e28d3).
- [x] 검증: `swift test -c release` 267개 전부 통과 (커밋별 267개 고정), 빌드 성공.

## v3.27 — Pyramid 스톡 재활용 1회 + Spider 스톡 표시 (완료 — 2026-09-09, 커밋 8ec749e, PLAN_v3.27_macos.md)
- [x] T-254: PyramidGame 재활용 1회 — `didRecycle` 상태 + `canMove(.recycleStock)`(스톡 비고 웨이스트 있고 미사용) + `applyUnchecked`(웨이스트 역순→스톡 복귀) + Snapshot/Codable(기존 저장 호환) + hint 후보.
- [x] T-255: VM `tapPyramidStock` 클론다이크 패턴 분기 (스톡 없으면 재활용) + View 재활용 오버레이(유턴 아이콘).
- [x] T-256: 테스트(재활용 1회/순서 복원/스톡 존재 시 거부/undo-redo 복원/레거시 호환) + 회귀 274개 통과.
- [x] T-257: Spider 스톡 더미 표시 — 스톡 50장 × 클릭 1회(10장 딜) 로 더미당 10장씩 소진 표현 (`cardsLeft > index * 10`). 전체 비었을 때만 전부 사라지던 문제 수정, 회귀 274개 유지. **사용자 실기 확인 완료 (2026-09-09).**

## v3.23 — 게임 흐름 버그 수정 (완료 — 2026-09-09, 커밋 4b4e1e5)
- [x] T-229: 데일리 단일화 — `startDailyDeal` 폐지 → `startTodayDeal(variant:)` (9판 매핑 후 `startChallenge` 위임). SideBarView:62, GameCommands:27 교체.
- [x] T-230: `activeChallenge: (deal, startDate)?` 구조체화 + `newGame` 진입 리셋 + `pendingChallengeDeal` (확인 다이얼로그 경로).
- [x] T-231: 시작일 기준 기록 + 챌린지 Winnable 우회 (표시=플레이=기록 번호 일치).
- [x] T-232: 미래 판정 `dateKey` 문자열 비교 (오전 버그). 측정 취소 시 `measuringDealKeys` 롤백.
- [x] T-233: 1단계 테스트 (ChallengeTests 3개: dateKey 순서/별개 판/번호 일치) + 회귀 256개 통과.
- [x] T-234: 홈 이탈 순서 역전 — `gameSessionID` 확정 이벤트 + ContentView onChange 자동 전환, 취소 시 홈 유지. HomeView 타일/무작위 onStartGame 선행 제거.
- [x] T-235: 번호시트·챌린지시트 시작도 gameSessionID 전환으로 통합 (VM 수정 불필요).
- [x] T-236: 시트→다이얼로그 2단계 — `needsNewGameConfirmation` 공용화 + 확인 필요 시 시트 유지, `confirmNewGame`에서 시트 닫기.
- [x] T-237: `newGame` 진입 `clearSave()` (stale 키 정리) + `restoredVariant` 캐시 (persist/clearSave 갱신).
- [x] T-238: 경과 시간 저장·복구 — GameSaver elapsed 키 + `beginRestoredSession` 헬퍼 + init 11분기 교체.
- [x] T-240: 자동풀어보기 세대 토큰 (`autoSolveGeneration`, 완료 시점 대조 후 파기).
- [x] T-241: `Budget.isCancelled` + DFS 루프 조기 종료 + startAutoSolve 취소 전달. FreeCellSolverTests 2개 추가.
- [x] T-242: `isBoardLocked` 가드 (apply/undo/redo) + 재생 중 경과시간 정지 + `goHome` 재생 취소.
- [x] T-239: Winnable 탐색 비동기화 — newGame/startGame 분리 + 로딩 UI + 세대 취소. FreeCellSolverTests 2개 추가.
- [x] T-239a (버그 수정): `gameSessionID` @Published 누락 수정 + dealRow 항상 dismiss (시트 위 다이얼로그 충돌 회피) + 측정 QoS utility.
- [x] T-243: 회귀 + CHANGELOG/DESIGN 갱신 (커밋 4b4e1e5 — 258개 통과, DESIGN 4.4 흐름 규칙 + 저장 키 기록). build_and_run.sh release 수동 시나리오는 GUI 검증 블록(T-253)과 묶어 대기.

## v3.22 — 홈 화면 + 게임 카테고리/난이도 그룹화 + 게임 중 난이도 (완료 — 2026-08-14, 릴리스 v3.22.0)
- [x] T-222: `GameVariant` 표시 전용 속성 — `GameCategory`(4그룹) + `baseDifficulty`/`categoryOrder` + `homeOrderedVariants`. `allCases` 순서 유지(데일리 셔플/순환 매핑 무영향). GameVariantDisplayTests 4개 통과.
- [x] T-223: `GameSelectorView` 카테고리 섹션화 + 난이도 뱃지.
- [x] T-224: `HomeView` 신규 — 타이틀 헤더 + 빠른 진입(데일리/게임 번호/무작위/통계·업적·설정) + 카테고리 그리드.
- [x] T-224a: 홈 "하던 게임 이어하기" 카드 — VM `restoredVariant` + 클릭 시 복원 게임 표시.
- [x] T-225: `ContentView` 홈/게임 전환 — VM `showingHome`(기본 true, 앱 시작 시 홈 먼저). 홈에서 창 타이틀 "Pure Solitaire".
- [x] T-226: 게임 중 난이도 뱃지 — `gameInfoView` 게임 번호 아래 (`vm.variant.baseDifficulty`).
- [x] T-227: 사이드바 "홈" 버튼(house, ⌘1) + 게임 메뉴 홈(⌘1) + VM `goHome()`.
- [x] T-228: 회귀 + 설치·실행 검증 + 문서 + 릴리스 v3.22.0 (태그 · GitHub Release + CI 통과). T-228 후속 수정 2건 커밋 0116bcf(난이도 예산 20s) / 23e94a7(자동풀어보기 리셋).

## v3.21 — 자동 풀어 보기 + 일일 도전 9판/3개월 달력 (완료)
- [x] v3.21.0 릴리스: 태그 + Release 워크플로우 성공 (`Pure-Solitaire-3.21.0-macos.zip` 4.3MB). CI 안정화: `replayBudget` 20→30s, #50 테스트를 빠른 #2로 교체(시간 의존성 제거). 전체 249개 통과.
- [x] T-210 (진행·코어 완료): `FreeCellSolver.solve(gameNumber:variant:budget:) -> [Move]?` — 이동 수집 DFS + `isWinnable`을 `solve() != nil`로 재구현 + `replayBudget`(2M/20s/60k). **핵심 완료**: 버그 수정(무효 이동) + 진행 가지치기로 유효한 단기 해 생성 — #1 950~3130 / #2 415 / #100 3678 이동 전부 유효, #50 703 이동(replayBudget 16.6s). #10은 유효 해 2553 이동 존재하나 134초 소요(난이도 높음 분류, 재생 예산 밖). #11982(MS 유일 미해결)는 20M/240s에서도 nil 확인. FreeCellSolverTests 11개 전부 통과.
- [x] T-211: 난이도 판정 — `SolveResult`(moves+nodeCount+depth)로 solve 확장 + `Difficulty`(쉬움/보통/어려움/미측정, 노드 <20k/150k 경계). DifficultyTests 4개 통과.
- [x] T-212: VM 자동 풀어 보기 — `startAutoSolve`(백그라운드 solve + 타이머 순차 재생) / `pause`/`resume`/`cancel`, `FreeCellGame.applyForReplay`(기록 오염 없음), 스냅샷 복원, 속도 3단계, 진행률. 단위 테스트 + 전체 231개 회귀 통과.
- [x] T-213: 내 이동 리플레이 — 전방 `moveHistory`(자동 플레이/완성 포함) 동기화 + 승리 시 확정, `startReplay`(시작 상태로 되돌려 재생)/`pause`/`resume`/`cancel` + 스냅샷 복원. 빌드 검증 + 전체 231개 회귀 통과.
- [x] T-214: 재생 오버레이 UI — `PlaybackOverlayView`(진행률/속도/일시정지/중단) + 재생 중 조작 잠금 + 사이드바·메뉴 버튼(⇧⌘P/⇧⌘R). 빌드 검증 + 전체 231개 회귀 통과. **남은 것**: A 완료 — T-215부터 B(일일 도전 9판).
- [x] T-215: DailyChallenge 9판 — `deals(for:) -> [Deal]`(12종 중 9개 날짜 시드 결정적 셔플·중복 없음) + 단건 API 호환 유지. 테스트 5개 추가 — DailyChallengeTests 9개 통과.
- [x] T-216: ChallengeStore 판별 기록 — `DealResult`/`DayResult`(dateKey별 9판 배열) + `recordDeal`(별점 업그레이드만) + 기존 단건→9판 호환. 테스트 4개 추가 — 8개 통과.
- [x] T-217: 3개월 달력/월 통계 — `CalendarMonth`(월·연 경계/firstWeekday/dayCount/dailyResults) + `MonthSummary`(완료/별/변형 분포) + `MonthBadge`(25/50/75/100%). 테스트 7개 통과.
- [x] T-218: 챌린지 시트 UI 개편 — 달력(◀▶ 3개월, 날짜별 ★완료) + 날짜 선택 9판 목록 + 월 통계 하단. VM `startChallenge(deal:)`(특정 판 시작, `activeChallengeDeal`) + `recordChallengeIfToday` 판별 매칭 + `todayChallengeStars` 9판 합계. 빌드(경고 0) + 전체 249개 통과.
- [x] T-219: C 난이도 태그 UI — `Difficulty.measure`(FreeCell 계열만, 예산 400k/8s/20k, 그 외 unmeasured) + VM 백그라운드 순차 측정 캐시(`ensureDealDifficulties`, onAppear/선택 변경/onDisappear 취소) + 판 목록 난이도 태그(쉬움/보통/어려움/미측정). DifficultyTests 6개 통과.
- [x] T-220: D 월간 배지 — 달력 헤더에 월 완료율 배지(브론즈/실버/골드/다이아) 표시. T-218 달력 헤더에 포함 구현. 전체 249개 회귀 통과.
- [x] T-221: 회귀(`swift test -c release` 249개) + `swift build`(경고 0) + `build_and_run.sh release` 설치·실행 + `docs/tests/v3.21_macos.md` + CHANGELOG/TODO/DESIGN 갱신 + `Pure-Solitaire-3.21.0-macos.zip`(4.3MB) 패키징. `build_and_run.sh` 테스트를 `swift test -c release`로 변경(debug는 #50 시간 초과). **v3.21.0 릴리스 준비 완료.**

## v1.0 — 프리셀 MVP

### Phase 1: GameCore (플랫폼 독립 로직)
- [x] T-001: Package.swift 생성 (GameCore + PureFreeCell + GameCoreTests 타깃)
- [x] T-002: 카드 모델 구현 (Suit/Rank/Card/Deck) + 테스트
- [x] T-003: MicrosoftRNG + DealGenerator (게임 #1/#617/#11982 딜 검증 테스트)
- [x] T-004: FreeCellRule 구현 (이동 검증, 수퍼무브 용량 공식, 승리 판정) + 테스트
- [x] T-005: FreeCellGame 상태 관리 (Move/Undo/Redo) + AutoPlay + 테스트

### Phase 2: SwiftUI 앱
- [x] T-006: 앱 스캐폴딩 (App/Scene/AppState) + 게임 보드 레이아웃
- [x] T-007: CardView 커스텀 벡터 렌더링 (클래식/심플 스타일)
- [x] T-008: 상호작용 (드래그&드롭 + 클릭 이동 + 더블클릭 홈 이동)
- [x] T-009: 메뉴/단축키 + 게임 번호 선택 시트 + 새 게임
- [x] T-010: 승리 처리 + 애니메이션 + 자동 플레이 적용
- [x] T-011: 통계 저장 (UserDefaults) + StatsView
- [x] T-012: 설정 (카드 스타일/배경/오토플레이/애니메이션) + SettingsView

### Phase 3: 배포
- [x] T-013: 앱 아이콘 생성 (AppIcon.icns)
- [x] T-014: scripts/build_and_run.sh (.app 번들 생성 + ~/Applications 설치)
- [x] T-015: 빌드/설치/실행 검증 + 자동 플레이 테스트 + 스크린샷/a11y 덤프 (release 빌드, 28개 테스트 통과, 창 1000×732, 카드 52장 렌더링 확인)

## v1.1 — 안정화 (진행중)
- [x] T-016: 수동 플레이 피드백 반영 (v1.0.6 커스텀 드래그 오버레이 + 좌표 정밀화로 커서 정확 추종 "굿" 확인, 자동 이동 연쇄/더블클릭/오버레이 겹침 수정, undo 스냅샷 전환으로 실행취소 크래시 수정 — 2026-08-05 완료)
- [x] T-017: 자동 저장(중간 복구) (Codable 직렬화 + GameSaver + scenePhase 안전 저장, 30개 테스트 통과, 사용자 재시작 복구 확인 완료 — 2026-08-05)
- [x] T-018: 접근성(VoiceOver) 개선 (구현 완료 — 카드 힌트/값 + 보드 그룹 + 버튼 라벨 + 드래그 오버레이 hidden. 열 상단 고정도 함께 반영해 사용자 확인 완료. VoiceOver 실제 동작은 추후 보류)

## v2.0 — 두 번째 게임 (진행중)
- [x] T-019: 게임 형식 결정 및 GameRule 확장 (Baker's Game 선택, PLAN_v2.0_macos.md 작성 완료)
- [x] T-020: GameVariant enum + FreeCellRule 같은-수트/수퍼무브 분기 + 테스트
- [x] T-021: FreeCellGame variant 통합 (freeCellCount, canMove, apply, Codable decodeIfPresent)
- [x] T-022: ViewModel variant 연동 (newGame(variant:), switchVariant, freeCell 인덱스 방어)
- [x] T-023: GameBoardView/SideBar 프리셀 조건부 렌더 + 접근성 유지 + 창 제목에 게임명 표시
- [x] T-024: 자동저장 variant 호환 (decodeIfPresent 기본 freecell, legacy 무손상 테스트)
- [x] T-025: 빌드/수동 검증 + 설정 섹션 정리 (사용자 확인 완료 — Baker's 동작 OK, 설정 3섹션 OK)

## v2.2 — 애니메이션/시간/확인/사이드바/회귀테스트 (완료 — 2026-08-05)
- [x] T-031: 딜 애니메이션 (withAnimation + 카드 하강)
- [x] T-032: 시간 측정 + StatsStore bestTime + StatsView 표시
- [x] T-033: 새 게임 확인 다이얼로그 + 승리 후 다음 게임 버튼
- [x] T-034: 사이드바 게임 형식 전환 버튼
- [x] T-035: 회귀 테스트 보강 (오토플레이 수렴/중복 카드, 빈 열·프리셀 경계, 더블클릭, Baker's 수퍼무브)

## v2.3 — 기록/승리연출/BGM/보드줌 (완료 — 2026-08-05)
- [x] T-036: 승리 기록 RecordStore (변형별, 최대 50건) + 통계 최근 승리 목록
- [x] T-037: 승리 연출 (홈 도착 카드 펄스 + 승리 배너)
- [x] T-038: 배경음악 (bgm.wav 생성 + 루프 재생 + 설정 토글)
- [x] T-039: 보드 줌 (슬라이더 + ⌘+/⌘- 단축키)
- [x] T-040: 사용자 수동 검증 완료 ("다 잘됨")

## v2.4 — 볼륨/창기억/승리연출/카드뒷면/타이머/통계초기화 (완료 — 2026-08-06, 빌드/테스트/설치 확인, 사용자 검증 대기)
- [x] T-041: 효과음/BGM 볼륨 조절 (슬라이더 + SoundPlayer/BGMPLayer 볼륨 적용)
- [x] T-042: 창 크기·위치 기억 (WindowAccessor + setFrameAutosaveName)
- [x] T-043: 승리 사운드/효과 확장 (사운드 시퀀스 + ConfettiView 파티클)
- [x] T-044: 카드 뒷면 패턴 선택 (CardBack enum + 딜 중 뒷면 표시)
- [x] T-045: 게임 중 경과 시간 표시 + 중지/재개
- [x] T-046: 통계/기록 초기화 (StatsStore.resetAll + RecordStore.clearAll)

## v3.0 — Klondike 추가 (진행중 — 2026-08-06)
- [x] T-050: KlondikeGame 구현 (GameCore, 병렬 추가)
- [x] T-051: Move에 Klondike 케이스 추가
- [x] T-052: GameVariant.klondike 추가
- [x] T-053: KlondikeGameTests 작성
- [x] T-054: ViewModel klondike 분기 (init 복원/newGame/이동/탭/드래그/힌트/오토/undo/checkState/persist 분기)
- [x] T-055: GameSaver Klondike 저장/복원
- [x] T-056: GameBoardView Klondike 레이아웃 (스톡/웨이스트/홈셀 + 7열 faceUp 분기)
- [x] T-057: 드래그/드롭/탭 파라미터화 + 스톡/웨이스트 (waste 소스, 컬럼 카운트 파라미터화, 게임 전환 3개 순환)
- [ ] T-058: 회귀 + Klondike 테스트, release 검증 (빌드/설치 완료 — 수동 검증 대기)

## v3.1 — Spider 추가 (진행중 — 2026-08-06)
- [x] T-060: DealGenerator spiderCards (104장 셔플, 수트 구성)
- [x] T-061: Move.dealFromStock + GameVariant.spider + SpiderDifficulty
- [x] T-062: SpiderGame 구현 (10열+스톡+완성수트)
- [x] T-063: SpiderGameTests 작성
- [x] T-064: ViewModel spider 분기
- [x] T-065: GameSaver spider 저장/복원
- [x] T-066: GameBoardView spider 레이아웃 (10열+스톡+완성표시)
- [x] T-067: 게임 번호 시트 난이도 선택 + 게임 전환 순환
- [ ] T-068: 회귀 + Spider 테스트, release 검증 (빌드/설치/실행 완료, 72개 테스트 통과 — 수동 검증 대기)

## 보류
- [ ] T-030: 변형 프리셀 추가 (Sea Tower / Super FreeCell) — 아주 나중으로 보류

## v3.2 — Sea Tower + Super FreeCell 추가 (완료 — 2026-08-06)
- [x] T-070: GameVariant + DealGenerator (seaTowerDeal 10열×5+프리셀2, superFreeCellDeal 2덱 104장)
- [x] T-071: FreeCellRule 확장 (seaTower 같은 수트+빈 열 K만, superFreeCell 교대색+빈 열 아무카드)
- [x] T-072: FreeCellGame 확장 (columnCount/freeCellCount/딜/supermove/isWon/canMoveToHome/homeIndex)
- [x] T-073: SeaTowerGameTests + SuperFreeCellGameTests
- [x] T-074: GameSaver variant별 키 (savedSeaTower/savedSuperFreeCell)
- [x] T-075: ViewModel restore/persist/clearSave 분기
- [x] T-076: GameBoardView (columnCount/colFactor/프리셀 개수 파라미터화/ForEach \.offset)
- [x] T-077: SideBar 6개 순환 + 게임 번호 시트 (allCases 자동)
- [x] T-078: 회귀 + 신규 테스트, release 검증 + 문서
- 보류 T-030 해제됨 (6개 게임 모두 추가 완료) — 수동 검증은 차례대로 진행 예정

## v3.3 — Yukon 추가 (진행중 — 2026-08-06)
- [x] T-080: GameVariant.yukon + DealGenerator.yukonDeal (7열 1/6/7/8/9/10/11, 뒤집힌 카드)
- [x] T-081: YukonGame 구현 (유콘 이동: 앞면 카드+위 전부 그룹 이동, 노출 자동 앞면)
- [x] T-082: 기존 GameCore 스위치 case .yukon 분기 + GameSaver 키
- [x] T-083: YukonGameTests (딜/유콘 이동/빈 열 K/홈셀/자동 앞면/승리/undo/Codable)
- [x] T-084: ViewModel yukon 분기 (init/newGame/이동/탭/힌트/undo/persist)
- [x] T-085: GameSaver savedYukon
- [x] T-086: GameBoardView yukon 분기 (7열 렌더/드래그/탭)
- [x] T-087: SideBar 7개 순환 + 게임 번호 시트
- [x] T-088: 회귀 + 신규 테스트, release 검증 + 문서

## v3.3 — 안정화 리팩토링 (완료 — 2026-08-06)
- [x] T-089: B1~B8 예상 버그 수정 (Yukon 오토플레이 홈 이동 / 웨이스트 탭 고정열 / 뒷면 a11y 노출 / 시트 즉시 시작 / 승리 undo UI / Yukon 홈 강조 / 미사용 변수 / 빌드 VERSION)
- [x] T-090: R1 열 클릭 함수 `handleColumnTap` 통합
- [x] T-091: R2 GameSaver 제네릭 헬퍼 통합
- [x] T-092: 힌트 첫 호출 최우선 후보부터 표시 + 데드 코드 제거 (DragPayload/CardSource.description/newGame(spiderDifficulty:))
- [x] T-093: swift build 경고 0건 + 단위 테스트 101개 통과
- [x] T-094: release 빌드/설치/실행 검증 (PID 확인)
- [x] T-095: 수동 테스트 가이드 `docs/tests/v3.3_macos.md` 작성

## v3.4 — Klondike 스톡 재활용 (완료 — 2026-08-06)
- [x] T-096: Move.recycleStock + KlondikeGame canMove/apply/hintCandidates
- [x] T-097: ViewModel tapKlondikeStock 분기 + moveDescription
- [x] T-098: 테스트 추가(5개) + 회귀(106개 통과), release 검증

## v3.4 — 드래그 오버레이 grab offset (완료 — 2026-08-06)
- [x] T-099: 드래그 오버레이가 잡은 카드를 정확히 커서에 추종하도록 위치 보정 (DragState.topIndex + dx/dy)

## v3.5 — Forty Thieves 추가 (완료 — 2026-08-06, PLAN_v3.5_macos.md)
- [x] T-100: GameVariant.fortyThieves + DealGenerator.fortyThievesDeal + 테스트
- [x] T-101: FortyThievesGame + 테스트 (canMove 그룹 검증 버그 수정 포함)
- [x] T-102: GameSaver + ViewModel 분기
- [x] T-103: GameBoardView 분기
- [x] T-104: SideBar 8개 순환 + 회귀 + release 검증

## 보류 (다음 버전 후보)
- [x] ~~Golf 추가~~ — 스톡+웨이스트+7열, 1차이/같은 랭크 제거 (v3.6 완료)
- [x] ~~Pyramid 추가~~ — 피라미드 28장+스톡, 합 13 제거 (v3.7 완료)
- [x] ~~TriPeaks 추가~~ — 3봉우리, 합 13 제거 (v3.8 완료)
- [x] ~~Forty Thieves 추가~~ (v3.5 완료)

## v3.8 — TriPeaks 추가 (완료 — 2026-08-06, PLAN_v3.8_macos.md)
- [x] T-130: GameVariant.triPeaks + DealGenerator.triPeaksDeal + 테스트
- [x] T-131: Move.triPeaksRemove + TriPeaksGame + 테스트
- [x] T-132: GameSaver + ViewModel 분기
- [x] T-133: GameBoardView 분기
- [x] T-134: SideBar 11개 순환 + 회귀 + release 검증 + 문서

## v3.7 — Pyramid 추가 (완료 — 2026-08-06, PLAN_v3.7_macos.md)
- [x] T-120: GameVariant.pyramid + DealGenerator.pyramidDeal + 테스트
- [x] T-121: Move 3케이스 + PyramidGame + 테스트
- [x] T-122: GameSaver + ViewModel 분기
- [x] T-123: GameBoardView 분기
- [x] T-124: SideBar 10개 순환 + 회귀 + release 검증 + 문서

## v3.6 — Golf 추가 (완료 — 2026-08-06, PLAN_v3.6_macos.md)
- [x] T-110: GameVariant.golf + DealGenerator.golfDeal + 테스트
- [x] T-111: Move.columnToWaste + GolfGame + 테스트
- [x] T-112: GameSaver + ViewModel 분기
- [x] T-113: GameBoardView 분기
- [x] T-114: SideBar 9개 순환 + 회귀 + release 검증 + 문서

## v3.9 — 랜덤 게임 전환 + 유동적 게임번호/통계/설정 (완료 — 2026-08-06, PLAN_v3.9_macos.md)
- [x] T-140: GameCore `GameOption`/`GameOptionChoice` + `GameVariant.optionDefinitions` + 테스트
- [x] T-141: `GameOptionsStore` 신설 + ViewModel `spiderDifficulty` 스토어 이전 + `switchToRandomGame` + `winRecords(for:)`
- [x] T-142: SideBarView 게임 전환 → 랜덤 + GameNumberSheet 옵션 자동 렌더링/문구 일반화
- [x] T-143: SettingsView "게임별 옵션" 섹션 + StatsView 스크롤 List 재작성
- [x] T-144: 회귀(신규 테스트) + `swift build`(경고 0) + release 설치·실행(VERSION 3.9.0) + 문서

## v3.11 — 설정에 색상/패턴 미리보기 적용 (완료 — 2026-08-06, PLAN_v3.11_macos.md)
- [x] T-149: `SettingPreviewViews` 신규 — `CardBackArtwork`(CardView 추출) + 공용 `PreviewCell` + `MiniCardFaceView` + 3종 픽커(CardStyle/BackgroundStyle/CardBack)
- [x] T-150: SettingsView 3개 `.segmented` → 미리보기 픽커 교체 + CardView `backView` 리팩터
- [x] T-151: `swift build`(경고 0) + `swift test` 171개 + release 설치·실행(VERSION 3.11.0) + 문서

## v3.10 — 게임 형식 선택을 대표 카드 이미지 그리드로 교체 (완료 — 2026-08-06, PLAN_v3.10_macos.md)
- [x] T-145: `GamePreviewLayout` + `GamePreviewCard` 신규 (11종 미니 보드 레이아웃 렌더)
- [x] T-146: `GameSelectorView`(3열 그리드) + GameNumberSheet "게임 형식" 픽커 교체
- [x] T-147: 시트 레이아웃/크기/a11y 정리 + 문서(PLAN/TODO/DESIGN/CHANGELOG/테스트 가이드/세션)
- [x] T-148: `swift build`(경고 0) + `swift test` 171개 + release 설치·실행(VERSION 3.10.0)

## v3.12 — 통계 선택 요약 / 힌트 드래그 애니메이션 / 자동 플레이 상태 표시 (완료 — 2026-08-06, PLAN_v3.12_macos.md)
- [x] T-152: StatsView 상단 세그먼트("전체|선택") + 선택 게임 요약 카드(최단 승리 포함), 행 탭 시 상단 갱신
- [x] T-153: VM `hintAnimationMove/Tick` + GameBoardView 힌트 왕복 2회 애니메이션 + `destinationOrigin`/`hintGeometry` 매핑, 하이라이트 유지
- [x] T-154: SideBarButton `isActive` + 자동 플레이 버튼 토글/상태 표시, GameCommands 메뉴 토글 통일
- [x] T-155: `swift build`(경고 0) + `swift test` 171개 + release 설치·실행(VERSION 3.12.0) + 문서(PLAN/TODO/DESIGN/CHANGELOG/tests/세션)
- [x] T-163: `GameBoardView.dragOverlay` ZStack `.frame` 고정(offset 카드가 레이아웃에 포함) + `dx/dy` padding 보정 + `.frame` `alignment: .topLeading` → 그룹 드래그 시 오버레이가 `(count-1)*step/2`만큼 아래로 어긋나던 버그 최종 수정
- [x] T-164: `maxColumnCards()` + `effectiveStep()` 신설, 열이 화면을 넘을 때 카드 겹침 자동 조정(최대 70%), 열 렌더/드래그/오버레이/힌트 좌표계에 동일 step 적용
- [x] T-165: `FreeCellViewModel.hint()` `candidates[hintIndex]` 인덱스 가드(hintIndex>=count → 0) + `newGame` 시 힌트 상태 리셋 → 힌트 호출 크래시(Index out of range) 수정
- [x] T-166: `UserSettings.feltTextBase`(화이트 배경 시 검정) 추가 + GameBoardView 하드코딩 `.white` 9곳 교체 → 화이트 배경 가시성 개선
- [x] T-167: SideBarView 상단 그룹/Spacer/하단 그룹 배치로 `.padding(.top, 132)` 하드코딩 제거 + 하단 그룹 바닥 정렬
- [x] T-168: Golf/Pyramid/TriPeaks `isHintSource` 하이라이트 추가(열 맨 아래/노출 카드) — 힌트 소스 표시 보강
