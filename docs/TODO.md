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

## v3.15 — 커스텀 배경/카드면 (진행중 — 2026-08-09, PLAN_v3.15_macos.md)
- [x] T-180: 커스텀 배경 — 저장/선택/제거/렌더(경로→Image) + feltTextBase 처리 + GameBoardView/ContentView 분기
- [x] T-181: 카드 뒷면 2종(오션/숲) tint/accent + 미리보기 자동 반영
- [x] T-182: 카드 앞면 2종(레트로/딥) CardView 스타일 분기 + 픽커 자동 반영
- [ ] T-183: 회귀(178개 유지) + swift build(debug·release) 경고 0 + release 설치·실행(VERSION 3.15.0) + 문서

## v3.16 — 데일리 딜 (진행중 — 2026-08-12, PLAN_v3.16_macos.md)
- [x] T-184: DailyDeal 날짜→시드 매핑 + 단위 테스트 5개
- [x] T-185: startDailyDeal() VM 진입점
- [x] T-186: 사이드바 "데일리 딜" 버튼(⌘D) + 게임 메뉴 항목
- [ ] T-187: 회귀(178+5) + swift build(debug·release) 경고 0 + release 설치·실행(VERSION 3.16.0) + 문서

## v3.17 — 데일리 챌린지 + 업적 (진행중 — 2026-08-12, PLAN_v3.17_macos.md)
- [x] T-188: DailyChallenge(변형/시드/별점) + ChallengeStore(완료 저장) + 테스트
- [x] T-189: Achievement 모델 + 판정 + AchievementStore + 테스트
- [x] T-190: VM + ChallengeView/AchievementsView + 사이드바/메뉴/시트 연결
- [ ] T-191: 회귀(183+15) + swift build(debug·release) 경고 0 + release 설치·실행(VERSION 3.17.0) + 문서

## v3.18 — Scorpion 변형 (진행중 — 2026-08-12, PLAN_v3.18_macos.md)
- [x] T-192: ScorpionGame(7열×7장+예비 3장, 그룹 이동, 빈 열 K, 승리 K→A 4열) + scorpionDeal + dealReserve + 단위 테스트 9개
- [x] T-193: GameVariant .scorpion(displayName "Scorpion", 옵션 없음)
- [x] T-194: VM scorpion 상태 + init 복원 + newGame/apply/applyRaw/undo/redo/canUndo/canRedo/current*/persist/hint/자동완성 가드
- [x] T-195: GameSaver scorpion 저장/복원(clear 포함)
- [x] T-196: GameBoardView scorpionTopRow(예비 더미) + 열 렌더/탭/드래그/힌트 소스 분기 + GamePreviewCard
- [ ] T-197: 회귀(207 = 198+9) + swift build 경고 0 + 문서

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
