# CHANGELOG — 변경 이력

## [미배포] — 2026-09-08 — [macos] — 게임 흐름 버그 수정 (T-229~T-242, PLAN_v3.23)
### 변경
- **데일리 단일화**: `startDailyDeal` 폐지 → `startTodayDeal` (오늘 9판 매핑 후 `startChallenge` 위임, ⌘D UX 유지). 데일리 딜 승리도 달력/별점에 기록됨.
- **챌린지 기록 정합성**: `activeChallenge` (판+시작일) 구조체화, `pendingChallengeDeal`로 확인 다이얼로그 경로 대응, 시작일 기준 기록, 챌린지 Winnable 우회 (표시=플레이=기록 번호 일치).
- **달력 버그**: 미래 판정을 `dateKey` 문자열 비교로 변경 (오전 오늘 비활성화 해소). 측정 취소 시 키 롤백.
- **시작·전환**: `gameSessionID` 확정 이벤트로 홈→게임 자동 전환 (취소 시 홈 유지). `needsNewGameConfirmation` 공용화 + 확인 필요 시 시트 유지. `newGame` 진입 `clearSave()` + `restoredVariant` 캐시. 경과 시간 저장·복구 (`beginRestoredSession`).
- **솔버·재생 안전화**: 자동풀어보기 세대 토큰, `Budget.isCancelled` + DFS 조기 종료, `isBoardLocked` 가드 (apply/undo/redo), 재생 중 타이머 정지, `goHome` 재생 정리.
- **미완료**: T-239 Winnable 탐색 비동기화 (별도 단계).
### 검증
- `swift test -c release` **258개 전부 통과** (253 + ChallengeTests 3 + FreeCellSolverTests 2).
- `swift build -c release` 경고 0.
- 문서: PLAN_v3.23/TODO/CHANGELOG 갱신.

## [3.22.0] — 2026-08-14 — [macos] — 홈 화면 + 게임 카테고리/난이도 그룹화 + 게임 중 난이도 (T-222~T-228)
### 변경
- **홈 화면 (A)**: 앱 시작 시 게임 선택 화면이 먼저 표시(`showingHome`). 타이틀 헤더 + 빠른 진입(데일리 도전 ⌥⌘D / 게임 번호 ⌘G / 무작위 / 통계·업적·설정) + 카테고리 4그룹 게임 그리드. 타일 클릭 → 해당 변형 게임 진입. 사이드바 "홈"(house, ⌘1) + 게임 메뉴 홈(⌘1)으로 언제든 복귀. 홈에서는 창 타이틀 "Pure Solitaire".
- **카테고리/난이도 정렬 (B)**: `GameVariant` 표시 전용 속성 추가 — `GameCategory`(FreeCell/스톡/스파이더/카드 제거) + `baseDifficulty`(변형 고정 난이도) + `categoryOrder` + `homeOrderedVariants`(카테고리→난이도→순서). `allCases` 순서는 유지(데일리 셔플/단건 순환 매핑 무영향).
- **난이도 매핑**: 쉬움(Golf/Scorpion) · 보통(FreeCell/Baker's/Klondike/Spider/Pyramid/TriPeaks) · 어려움(Sea Tower/Super FreeCell/Yukon/Forty Thieves).
- **게임 중 난이도 표시 (C)**: 게임판 정보 영역 게임 번호 아래 난이도 뱃지(`vm.variant.baseDifficulty`, 쉬움=초록/보통=주황/어려움=빨강) + 접근성 라벨 포함. `GameSelectorView`도 카테고리 섹션 + 난이도 뱃지로 개편.
### 검증
- `swift test -c release` **253개 전부 통과**(16.7s) — 기존 249 + GameVariantDisplayTests 4개.
- `swift build -c release` 경고 0(기존 ScorpionGame 경고 제외). `build_and_run.sh release` 설치·실행 확인 — 창 타이틀 "Pure Solitaire"(홈 표시).
- 문서: PLAN_v3.22/TODO/CHANGELOG/DESIGN/session

## [3.21.0] — 2026-08-14 — [macos] — 자동 풀어 보기 + 내 이동 리플레이 + 일일 도전 9판/3개월 달력/난이도 태그/월 배지 (T-210~T-221)
### 변경
- **자동 풀어 보기 (A)**: `FreeCellSolver.solve(gameNumber:variant:budget:) -> SolveResult?` — DFS가 성공 경로 이동 시퀀스를 수집. 무효 이동 버그 2건 수정(단일/그룹 bottom 카드 기준) + 홈 카드 진행 없는 경로 가지치기(`maxStagnantDepth 80`). `isWinnable`은 `solve() != nil`로 재구현. 재생 예산 `replayBudget`(2M/20s/60k) — #50(703 이동/16.6s) 해결, #10은 난이도 높음으로 분류.
- **난이도 판정 (C)**: `SolveResult`(moves+nodeCount+depth) + `Difficulty`(쉬움 <20k / 보통 <150k / 어려움, 예산 초과 unmeasured) + `Difficulty.measure`(FreeCell 계열만, 백그라운드 순차 측정 캐시).
- **자동 풀어 보기/리플레이 재생 UI**: `PlaybackOverlayView`(진행률/속도 3단계/일시정지/중단) + 조작 잠금 + 사이드바/게임 메뉴 버튼(⇧⌘P 자동 풀어 보기, ⇧⌘R 내 이동 리플레이). 재생은 순수 시연 — 스냅샷 보존 후 종료/중단 시 원래 상태 복원.
- **일일 도전 9판 (B)**: `DailyChallenge.deals(for:) -> [Deal]` — 12종 중 9개를 날짜 시드 결정적 셔플(중복 없음), 각 변형은 `DailyDeal.gameNumber` 재사용. 기존 단건 API 호환 유지.
- **챌린지 시트 개편**: 3개월 달력(◀▶, 날짜별 ★완료 표시) + 날짜 선택 9판 목록(순번/변형/게임 번호/별/난이도 태그) + 월 통계(완료/별/완료율) + 월 배지(브론즈/실버/골드/다이아).
- **ChallengeStore 9판 기록**: `DealResult`/`DayResult`(dateKey별 9판 배열) 저장 + `recordDeal`(별점 업그레이드만) + 기존 단건→9판 호환 변환.
### 검증
- `swift test -c release` **249개 전부 통과**(32.3s): FreeCellSolver 11 / Difficulty 6 / DailyChallenge 9 / ChallengeStore 8 / CalendarMonth 7 / FreeCellGame 리플레이 등.
- `swift build -c release` 경고 0. (기존 ScorpionGame `default` 미도달 경고는 이번 버전 소관 아님)
- 문서: PLAN_v3.21/TODO/CHANGELOG/tests v3.21/session

## [3.20.0] — 2026-08-12 — [macos] — 릴리스 + CI 테스트 안정화
### 변경
- **GitHub Release v3.20.0 배포**: 태그 + GitHub Actions Release 워크플로우로 `Pure-Solitaire-3.20.0-macos.zip` (4.2MB) 생성.
- **DailyDealTests 타임존 독립화**: 회귀 테스트의 날짜 헬퍼를 UTC 그레고리안 캘린더로 고정하고 `gameNumber(for:variant:calendar:)`에 명시 전달 — 로컬(KST)에선 통과하지만 CI(UTC)에선 날짜 순번이 달라져 실패하던 문제 해소. 회귀값을 UTC 기준(31_149 freecell / 173_480 klondike)으로 갱신.
- **Release 워크플로우 테스트 모드 변경**: `swift test`(debug) → `swift test -c release`. debug 빌드는 최적화가 없어 FreeCell #2가 기본 예산(400k/4s)을 넘겨 `testWinnableStandardDeals`가 실패했음. release 모드는 로컬 검증과 동일 조건.
### 검증
- `swift test -c release` 220개 전부 통과(9.8s), DailyDealTests 5개 결정적 통과
- GitHub Actions Release 성공(2m9s), 랜딩 페이지 배포 성공(사용자 제공 보드 스크린샷 반영)
- 문서: PLAN_v3.20/TODO/CHANGELOG/session

## [3.20.0] — 2026-08-12 — [macos] — Winnable 딜 (솔버 코어)
### 변경 (T-202)
- **FreeCellSolver 추가** (`GameCore/FreeCellSolver.swift`): FreeCell 계열 4종(freecell/bakersGame/seaTower/superFreeCell) 승리 가능 여부 판정. 안전 홈 이동(AutoPlay 규칙) 자동 적용으로 상태 압축 + 반복 DFS(명시적 스택) + 휴리스틱 이동 순서(홈 이동 0 → 프리셀→열 → 빈 열 K → 그룹 2+ → 빈 열 비-K → 단일 → 열→프리셀 → 홈 꺼내기) + 방문 상태 집합(사이클 방지) + 수퍼무브(그룹) 이동 생성.
- **예산 게이트**: 노드/시간/깊이 예산. 예산 초과는 "미확정"(false) 처리로 긴 대기 방지. **깊이 예산 초과 시 가지치기(continue)로 수정** — 기존 `return false`(전체 탐색 즉시 포기)는 DFS 백트래킹을 막아 게임 #3/#10/#20을 오판하는 버그였음.
- **기본 예산 상향**: nodeLimit 400,000 / timeLimit 4.0s / depthLimit 20,000 (기존 200k/1.5s — 짧아 미확정 다발).
- **휴리스틱 개선**: 이동 우선순위를 연속 점수로 세분화(홈 0 → 프리셀→열 → 빈 열 K → 홈 카드 드러내기[빈 열 있을 때만, 드러난 카드 랭크에 비례 31..43] → 그룹 2+ → 빈 열 비-K → 단일 → 열→프리셀 → 홈 꺼내기). 빈 열 조건부 "드러내기 우선"으로 **MS 딜 #1과 #2를 기본 예산 내 동시 해결** — 기존 10/13 → 11/13 true.
- **API**: `isWinnable(gameNumber:variant:budget:)`, `firstWinnableGameNumber(from:variant:budget:maxAttempts:)`, `isFreeCellFamily(_:)`.
- **알려진 한계**: MS 딜 #50(해는 존재 — 1.5M/10s에서 확인)과 #500(5M/60s에서도 미해결)은 기본 예산 내 미확정 — 후속 과제.
### 검증
- `swift build`(debug) 경고 0건, 단위 테스트 **219개** 통과(FreeCellSolverTests 5개 신규 — 대표 MS 딜 풀림/예산 내 판정/예산 0 미확정/미지원 변형/첫 Winnable 번호) → 이후 휴리스틱 개선으로 대표 딜에 #1/#2 추가
- 문서: PLAN_v3.20/TODO
- T-203~T-205(옵션/VM/UI 연동)은 미완료 — 다음 커밋 예정

## [3.20.0] — 2026-08-12 — [macos] — Winnable 옵션 연동 (T-203~T-205)
### 변경
- **winnable 옵션 추가** (`GameVariant.optionDefinitions`): FreeCell 계열 4종에 "승리 보장" 토글("일반"/"승리 보장"). GameOptionsStore 자동 반영 — 게임 번호 시트에 세그먼트 자동 렌더링.
- **VM 연동** (`FreeCellViewModel`): `isWinnableEnabled(for:)`로 옵션 읽기. `newGame(number:variant:)`에서 승리 보장이 켜져 있으면 `FreeCellSolver.firstWinnableGameNumber(from:variant:budget:maxAttempts:)`(WinnableSearchBudget 100k/1.0s, 최대 50회)로 풀리지 않는 번호를 건너뛰고 다음 풀리는 번호로 시작. 실제 시작 번호가 표시·통계(`setLastGameNumber`)에 반영.
- **시트 안내 문구** (`GameNumberSheet`): 승리 보장 선택 시 "풀리지 않는 번호는 다음 풀리는 번호로 시작됩니다" 안내 표시.
### 검증
- `swift build`(debug) 경고 0건, 단위 테스트 **220개** 통과(GameOptionTests +1 — FreeCell 계열 winnable 옵션 정의)
- 문서: PLAN_v3.20/TODO

## [3.19.0] — 2026-08-12 — [macos] — 점수 체계
### 변경 (T-198~T-200)
- **점수 체계 추가**: 표준 Klondike 점수 기준 + 변형별 상수(`GameCore/Scoring.swift` 순수 계산). 이동 점수(스톡 드로 +5, 홈 이동 +10, 홈에서 꺼내기 -15, 웨이스트 재활용 -100, 뒤집기 +5, 피라미드/골프/트리피크스 제거 점수)를 이동마다 누적. 승리 보너스(Klondike 계열 500 / Spider 800 / 제거 기반 300) + Klondike 시간 패널티(10초당 -2).
- **스파이더 완성 보너스**: 열에서 K→A 13장 완성마다 +100(증가분 계산).
- **표시**: 게임 보드 게임 정보에 "점수 N"(현재 누적), 승리 배너에 "최종 점수 N점", 통계 상세의 최근 승리 목록에 승리 점수. undo/redo 시 점수 롤백, 새 게임 시 0 초기화.
- **저장**: 승리 기록(`GameRecord`)에 `score` 필드 추가 — 기존 데이터 호환(없으면 nil).
### 검증
- `swift build`(debug) 경고 0건, 단위 테스트 **214개** 통과(Scoring 7개 신규)
- 문서: PLAN_v3.19/TODO/CHANGELOG/DESIGN
- 수동 검증은 v3.15~v3.19 일괄로 지연

## [3.18.0] — 2026-08-12 — [macos] — Scorpion 변형
### 변경 (T-192~T-196)
- **Scorpion 게임 추가**: 1덱 52장. 7열×7장(49장) + 예비 3장. 앞 4열(0~3)은 밑 3장 뒤집힘 + 위 4장 앞면, 뒤 3열(4~6)은 전부 앞면. 홈셀 없음 — 승리 = 열 4개가 각각 같은 수트 K→A 완성 시퀀스.
- **규칙**: 같은 수트 + 정확히 한 단계 낮은 카드 위로만. 앞면 카드와 그 위 전부를 그룹 이동(Yukon식). 노출된 뒤집힌 카드 자동 앞면. 빈 열은 K만. 예비 3장은 스톡 클릭 시 1회만 열 0,1,2에 앞면 딜(`dealReserve` Move).
- **자동 완성 제외**: 홈셀 기반 autoFinish는 스콜피온에서 비활성(내부 판단). 자동 플레이도 제외.
- **연동**: GameVariant `.scorpion`(선택기/통계/챌린지 순환 자동 반영), VM 상태·이동·undo/redo·힌트·저장, GameBoardView 예비 더미/열 렌더·탭·드래그·힌트, 게임 미리보기 카드.
### 검증
- `swift build`(debug) 경고 0건, 단위 테스트 **207개** 통과(Scorpion 9개 신규)
- 문서: PLAN_v3.18/TODO/CHANGELOG
- 수동 검증은 v3.15~v3.19 일괄로 지연

## [3.17.0] — 2026-08-12 — [macos] — 데일리 챌린지 + 업적
### 변경 (T-188~T-190)
- **데일리 챌린지**: 매일 1개 고정 변형(전체 변형 순환) + 날짜 시드(v3.16 DailyDeal 재사용). 별점 3점 — 승리 1 + 시간 목표 1 + 이동 수 목표 1. 변형별 목표 기준표 제공. 완료 상태는 날짜별 UserDefaults 저장(더 높은 별점으로 갱신).
- **업적 10개**: 첫 승리 / 승리 10·50회 / 첫 연승 / 5연승 / 변형 1·5종 완주 / 게임 100판 / 1분 이내 승리 / 챌린지 별 3. 통계 스냅샷 기반 순수 판정 + UserDefaults 잠금 해제 저장(중복 방지).
- **진입**: 사이드바 "챌린지"(⌥⌘D) / "업적"(⌥⌘T) + 게임 메뉴 항목. ChallengeView(오늘 변형·시드·별점 목표·완료 표시)와 AchievementsView(배지 그리드, 잠금/해제 표시) 시트. 승리 시 활성 챌린지가 오늘 것이면 별점 자동 기록 + 업적 잠금 해제 갱신.
### 검증
- `swift build`(debug) 경고 0건, 단위 테스트 **198개** 통과(챌린지/업적 15개 신규)
- release 설치·실행 (VERSION 3.20.0 빌드본, 창 "Pure Solitaire — TriPeaks 586112" + 보드 a11y 요소 41개 렌더 확인)
- 문서: PLAN_v3.17/TODO/CHANGELOG/DESIGN

## [3.16.0] — 2026-08-12 — [macos] — 데일리 딜
### 변경 (T-184~T-186)
- **데일리 딜**: 날짜(YYYY-MM-DD)를 결정적 시드로 변환해 하루 1개 고정 게임. 같은 날짜+변형이면 항상 같은 배치, 변형마다 다른 시드(변형별 데일리 1개씩).
- **구현**: `GameCore/DailyDeal.gameNumber(for:variant:)` 신규 — 날짜 순번(era 기준)+변형 rawValue 해시를 결정적 혼합해 `1...1,000,000` 시드 생성. 기존 게임 번호 파이프라인 재사용.
- **진입**: 사이드바 "데일리 딜"(calendar, ⌘D) + 게임 메뉴 "데일리 딜"(⌘D). `startDailyDeal()`이 진행 중이면 기존 확인 다이얼로그를 띄우고, 게임 시작/통계 기록/자동플레이/딜 연출은 기존 경로 재사용.
- **Winnable**: 사용자 결정으로 v3.16에서 제외(후속 버전에서 재검토).
### 검증
- `swift build`(debug) 경고 0건, 단위 테스트 **183개** 통과(DailyDeal 5개 신규)
- release 설치·실행 (VERSION 3.20.0 빌드본 확인)
- 문서: PLAN_v3.16/TODO/CHANGELOG/DESIGN

## [3.15.0] — 2026-08-12 — [macos] — 커스텀 배경/카드면
### 변경 (T-180~T-182)
- **커스텀 배경 (T-180)**: 설정 "배경" 픽커에 **커스텀** 항목 추가. "이미지 선택…" 버튼(NSOpenPanel)으로 사진 업로드 → `Application Support/Pure Solitaire/custom-background.png`에 복사 저장 → 보드/창 배경으로 렌더. "제거" 버튼으로 원복. 공용 `BackgroundLayer` 뷰가 커스텀 이미지/색 분기 처리(GameBoardView·ContentView 공용). 누락 시 기본 그린 폴백.
- **카드 뒷면 2종 추가 (T-181)**: 클래식/블루/골드 + **오션/숲**. `CardBack`에 tint/accent만 추가해 기존 `CardBackArtwork`/`CardView.backView`에 자동 반영.
- **카드 앞면 2종 추가 (T-182)**: 클래식/심플 + **레트로/딥**. `CardStyle` 확장 — 레트로는 세리프+아이보리 배경, 딥은 다크 배경+밝은 면색(심볼/랭크 대비). `SuitSymbolView`에 foreground 주입, `MiniCardFaceView` 동일 분기.
### 검증
- `swift build`(debug) 경고 0건, 단위 테스트 **178개** 통과(표시/설정 계층 — GameCore 무변경)
- release 설치·실행 (VERSION 3.20.0 빌드본 확인)
- 문서: PLAN_v3.15/TODO/CHANGELOG/DESIGN

## [3.14.0] — 2026-08-09 — [macos] — 전체 힌트 강조
### 변경 (T-175~T-177)
- **전체 힌트 강조**: 유효 이동 전체의 소스를 한 번에 강조. `⇧⌘H`(또는 사이드바 "전체 힌트" 토글)로 켜짐/꺼짐. 켜지면 현재 보드의 모든 이동 가능한 소스 카드가 노란 테두리로 동시 표시되고, 이동/새 게임/게임 전환 시 자동 해제.
- **단일 힌트 유지**: 기존 `⌘H` 후보 순환 + `Enter` 적용 + 소스→목적지 왕복 2회 애니메이션은 그대로.
- **구현**: VM에 `showAllHints` + `displayedHintMoves`(전체 힌트 시 `currentHintCandidates` 전체, 아니면 하이라이트 1개) 추가. `hint()`의 게임별 후보 추출 로직을 `currentHintCandidates()`로 공용화. GameBoardView의 소스 하이라이트 판정 함수 13개(홈/프리셀/열 — FreeCell/Klondike/Yukon/FortyThieves/Golf/Pyramid/TriPeaks/Spider)를 단일 `highlightedMove` 대신 `displayedHintMoves` 기준으로 일반화.
### 검증
- `swift build`(debug·release) 경고 0건, 단위 테스트 **178개** 통과(표시 계층 변경, 기존 유지)
- release 설치·실행 (PID 27391, VERSION 3.14.0)
- 문서: PLAN_v3.14/TODO/DESIGN/CHANGELOG/테스트 가이드/세션 로그

## [3.13.0] — 2026-08-09 — [macos] — 코어 QoL 3종
### 변경 (T-170~T-172)
- **승리 자동 완성 (T-170)**: 승리 직전 상태(잔여 카드가 모두 홈 이동 가능)에서 남은 카드를 홈셀로 자동 정리. 홈셀 중심 게임(freecell/bakersGame/seaTower/superFreeCell/klondike/yukon/fortyThieves)만 적용, spider/golf/pyramid/triPeaks 제외. `applyRaw` 경유로 이동을 **undo 스택에 포함**(중간 복귀 가능), 최대 500회 가드, 완료 시 사운드+승리 연출. 설정 "승리 자동 완성" 토글(@AppStorage, 기본 켬).
- **이동 수 통계 (T-171)**: 전역/변형별로 `totalMoves`·`leastMoves`·`avgMoves`(반올림) 기록·표시. 승리 기록(`RecordStore.GameRecord.moves`)에 이동 수 저장(기존 데이터 호환, 기본 0). `StatsView` 선택/전체 요약 + 상세에 "최소 이동"·"평균 이동", 최근 승리 목록에 "N 이동" 표시.
- **Klondike 스톡 1·3장 (T-172)**: 설정/게임 번호 시트에 "스톡 드로" 옵션(1장/3장) 추가. `KlondikeGame.drawMode`(1/3, Codable 호환, 기본 1)로 드로 장수 반영 — 3장 드로 시 남은 1~2장은 그 장수만 웨이스트로, 재활용 순서 유지.
### 검증
- `swift build`(debug·release) 경고 0건, 단위 테스트 **178개** 통과(신규 7: Klondike 3장 드로 3 + 드로 모드 Codable + canAutoFinish 전수 + RecordStore moves 왕복 + Klondike 옵션 정의)
- release 설치·실행 (PID 90472, VERSION 3.13.0)
- 문서: PLAN_v3.13/TODO/DESIGN/CHANGELOG/테스트 가이드/세션 로그

## [3.12.1] — 2026-08-09 — [macos] — 리브랜딩
### 변경 (T-169)
- **앱 이름 변경**: `Pure FreeCell` → `Pure Solitaire`(순수한 솔리테어). 패키지/실행 타깃·소스 디렉터리 `PureFreeCell` → `PureSolitaire`, `PureFreeCellApp` → `PureSolitaireApp`.
- **번들 ID 변경**: `com.pure.freecell` → `com.borasarang.puresolitaire` (기존 UserDefaults 통계/저장 게임/설정은 새 도메인과 분리).
- **Dock 표시명**: `CFBundleDisplayName` = "순수한 솔리테어", Finder 파일명은 `Pure Solitaire.app` 유지.
- 설치 경로 `~/Applications/Pure FreeCell.app` → `~/Applications/Pure Solitaire.app`, 창 autosave 키 변경.
### 검증
- `swift build`(debug·release) 경고 0건, 단위 테스트 **171개** 통과, release 설치·실행 (VERSION 3.12.1)
### 버그 수정
- **드래그 오버레이 위치 어긋남 (T-163)**: 여러 장 묶음을 드래그하면 오버레이가 `(count-1)*step/2`만큼 아래로 어긋나 마우스 아래로 처져 보이던 문제 수정. `ZStack`의 `.offset`이 레이아웃 크기에 반영되지 않아 `.position` 중심 계산과 실제 프레임이 불일치했고, `.frame`의 기본 center 정렬이 이를 재현 → `.frame(alignment: .topLeading)` + `dx/dy` padding 보정으로 해결. 드래그 시작 시 오버레이가 원래 카드와 정확히 겹치고 잡은 카드가 마우스 포인트에 정확히 붙음.
- **화면 넘침 시 카드 겹침 자동 조정 (T-164)**: 열이 화면 아래로 넘칠 때 카드 겹침을 자동 증가(최대 70%)해 긴 열도 화면 안에 배치. `maxColumnCards()`/`effectiveStep()` 신설, 열 렌더·드래그 소스·카드 오리진·오버레이·힌트 좌표계에 동일 `step` 적용(드롭 정확도 유지). Pyramid/TriPeaks는 열 없음 → 제외.
- **힌트 호출 크래시 (T-165)**: 힌트 반복 후 게임 상태가 변하면 `candidates[hintIndex]`가 배열 인덱스 초과로 크래시(SIGTRAP). `hint()` 진입 시 인덱스 가드 + `newGame()` 시 힌트 상태 리셋으로 해결.
### 검증
- `swift build`(debug·release) 경고 0건, 단위 테스트 **171개** 통과, release 설치·재시작 (PID 64852, VERSION 3.12.0)
- 수동 확인: K~8 묶음 드래그가 마우스 포인트에 정확히 붙음, 긴 열이 화면에 들어옴, 힌트 반복·게임 전환 크래시 없음
- 문서: PLAN_v3.12(§8~10), TODO(T-163~165), session log

## [3.12.0] — 2026-08-06 — [macos]
### 변경 (T-152~T-155)
- **통계 상단 요약이 선택 게임으로 변경 + 전체/선택 토글**: 통계 시트 상단에 "요약 대상" 세그먼트(전체 | 선택) 추가. 기본 **선택** 모드로 시트를 열면 현재 게임(Yukon 등)의 통계가 상단 요약에 표시되고(최단 승리 포함), "전체"로 전환하면 전체 합계로 표시. 하단 게임별 행 탭 시 상단 요약이 해당 게임으로 즉시 갱신(다시 탭하면 전체로 폴백).
- **힌트 드래그 애니메이션(왕복 2회)**: 힌트를 호출하면 하이라이트 대신 카드가 소스→목적지→소스 **왕복 2회** 드래그 모션으로 이동을 보여줌(실제 이동 없음, 하이라이트 유지). 스톡/플립류(드래그 개념 부적합)는 하이라이트만 유지. `Enter`로 실제 적용.
- **자동 플레이 상태 표시 + 토글**: 사이드바 자동 플레이 버튼이 ON이면 강조색(파랑)+`accessibilityValue "켜짐"`, OFF면 흐림+"꺼짐". 클릭 시 토글하고 켜지면 즉시 현재 보드에 자동 플레이 적용. 메뉴 "자동 플레이"(⇧⌘A)도 같은 토글 동작 + 켜짐 체크 표시로 통일. 설정 시트 "자동 이동" 스위치와 자동 동기화.
### 검증
- `swift build`(debug·release) 경고 0건, 단위 테스트 **171개** 통과(표시 계층만), release 설치·재시작 (PID 80255, VERSION 3.12.0)
- AX 검증: 자동 플레이 버튼 ON/OFF 토글(파랑 픽셀 6936↔0, value "켜짐"/"꺼짐", UserDefaults 1/0) + 설정 시트 동기화 / 힌트 왕복 2회 프레임 캡처 + 이동 수 불변 / 통계 선택·전체 전환 + 행 탭 시 상단 갱신
- 문서: PLAN_v3.12/TODO/CHANGELOG/DESIGN/테스트 가이드/세션 로그

## [3.11.0] — 2026-08-06 — [macos]
### 변경 (T-149~T-151)
- **설정에 색상/패턴 미리보기 적용**: 설정 시트의 카드 스타일/배경/카드 뒷면 선택이 텍스트 `.segmented`에서 **실제 색·패턴 미리보기 셀**로 교체.
  - `SettingPreviewViews.swift`(신규): `CardBackArtwork`(카드 뒷면 패턴 — `CardView.backView`에서 추출해 중복 제거), 공용 `PreviewCell`(탭 선택, 파랑 테두리+라벨, `.isSelected` 트레잇), `MiniCardFaceView`(클래식 serif/심플 rounded), 3종 픽커.
  - 배경 4종(그린/블루/다크/화이트) = `UserSettings.color(for:)` 스와치 / 카드 뒷면 3종(클래식/블루/골드) = `CardBack.tint/accent` 미니 뒷면 / 카드 스타일 2종(클래식/심플) = `CardView`와 동일 색·폰트 미니 앞면.
  - `UserSettings.backgroundColor(for:)`를 `static color(for:)`로 리팩터(설정 미리보기/보드 렌더 공용). 선택은 즉시 적용되어 보드/카드에 반영.
### 검증
- `swift build`(debug·release) 경고 0건, 단위 테스트 **171개** 통과(표시 계층만), release 설치·재시작 확인 (PID 47350, VERSION 3.11.0)
- AX 덤프: 카드 스타일 2셀 + 배경 4셀 + 카드 뒷면 3셀 렌더. 픽셀 검증: 스와치/패턴 색 정확, 블루 스와치 클릭 → 보드 felt 실시간 블루 변경 확인
- 문서: PLAN_v3.11/TODO/CHANGELOG/DESIGN/테스트 가이드/세션 로그

## [3.10.0] — 2026-08-06 — [macos]
### 변경 (T-145~T-148)
- **게임 형식 선택 UI 교체**: 게임번호 시트의 "게임 형식" 메뉴 픽커(`Picker .menu`)를 **게임 대표 미니 보드 미리보기 카드 그리드**로 교체.
  - `GamePreviewCard`(신규): 0.7 비율 카드 타일 안에 해당 게임의 보드 배치를 축소 렌더 — 홈셀/프리셀/스톡/웨이스트/열/피라미드/트리피크 형태 구분.
  - `GameSelectorView`(신규): `LazyVGrid` 3열 + ScrollView — `GameVariant.allCases` 자동 확장, 호버 scale 1.04, 선택 시 파랑 테두리+파랑 게임명.
  - `GamePreviewLayout` 디스크립터가 게임 클래스 static 상수(`FreeCellGame.columnCount(for:)`/`freeCellCount`, `SpiderGame.columnCount`, `TriPeaksGame.rowsPerPeak` 등) 재사용 → 게임 추가 시 자동 확장, 중복 없음.
  - 시트 크기 440×420으로 확대. 타일 클릭은 **선택만 변경**(게임 시작은 "게임 시작" 버튼) — 범위는 게임번호 시트만, 사이드바 랜덤 전환/설정은 보류(사용자 지시).
### 검증
- `swift build`(debug·release) 경고 0건, 단위 테스트 **171개** 통과(변경 없음 — 표시 계층만), release 설치·재시작 확인 (PID 92503, VERSION 3.10.0)
- AX 덤프: 11개 타일 3열 배치 렌더 확인, 현재 게임 타일 파랑 선택 표시, FreeCell 타일 클릭 → 선택 이동, 창 제목 불변(게임 미시작), 시트 닫기 정상
- 문서: PLAN_v3.10/TODO/CHANGELOG/DESIGN/테스트 가이드/세션 로그

## [3.9.0] — 2026-08-06 — [macos]
### 변경 (T-140~T-144)
- **게임 전환 랜덤화**: 사이드바 "게임 전환" 버튼이 하드코딩된 11개 순환 switch 대신 `GameVariant.allCases`에서 **현재 게임 제외 랜덤** 선택 (`switchToRandomGame`). 게임이 늘어나도 자동 확장.
- **선언적 변형 옵션 모델**: GameCore `GameOption`/`GameOptionChoice` + `GameVariant.optionDefinitions` 신설 (현재 유일 옵션 = Spider 난이도 1/2/4수트). 게임 추가 시 옵션 정의만 추가하면 자동 반영.
- **GameOptionsStore** (UserDefaults, `gameOptions.{variant}.{optionID}`): 옵션 선택값 영구 저장. `spiderDifficulty`를 `@Published`에서 스토어 기반 computed로 이전 (단일 진실 소스).
- **게임 번호 시트**: `selectedVariant.optionDefinitions` 순회 자동 렌더링 (Spider 난이도 특수 케이스 제거), 설명 문구를 "선택한 게임 번호로 결정적 배치 시작"으로 일반화.
- **설정**: "게임별 옵션" 섹션 추가 — `allCases` 중 옵션 있는 게임만 자동 표시.
- **통계 뷰 재작성**: `.segmented` 12세그먼트 → 스크롤 List. 상단 전체 요약 고정 + 게임별 요약 행(선택 시 최단 승리/최근 승리 10건 펼침), 기본 선택 = 현재 게임. 게임 수 무관 확장.
### 검증
- `swift build`(debug·release) 경고 0건, 단위 테스트 **171개** 통과(GameOptionTests 2개 추가), release 설치·재시작 실행 확인 (PID 30221, VERSION 3.9.0), 문서(PLAN_v3.9/TODO/CHANGELOG/DESIGN) 업데이트

## [3.8.0] — 2026-08-06 — [macos]
### 추가 (T-130~T-134)
- **TriPeaks(트리피크스) 게임 추가**: 열한 번째 변형 (표준 규칙) — 보류 후보 3종(Golf·Pyramid·TriPeaks) 전부 완료
  - 규칙: **1덱 52장**, **3개 피크**(각 4줄: 1+2+3+4 = 10장 × 3 = **30장**) + **웨이스트 1장**(딜 시 오픈) + **스톡 21장**, 노출 카드(각 피크 마지막 줄 또는 아래 자식 2장 제거된 카드)만 이동
  - **이동**: 노출 카드가 **웨이스트 맨 위와 정확히 1 랭크 차이**(수트 무관, **같은 랭크·K↔A 순환 제외** — Golf와 차이)면 웨이스트로 제거, 스톡→웨이스트 드로(**재활용 없음**)
  - **승리** = 3개 피크 30장 전부 제거, **종료** = 스톡 소진 + 1 랭크 차이 노출 카드 없음
  - `GameVariant.triPeaks` + displayName "TriPeaks" (SideBar 순환: Pyramid→TriPeaks→FreeCell, 게임 번호 시트/통계 `allCases` 자동 반영)
  - `DealGenerator.triPeaksDeal(gameNumber:)` — 앞 30장 피크(피크별 글로벌 인덱스 순), 1장 웨이스트, 뒤 21장 스톡
  - `Move.triPeaksRemove(card:)` 케이스 추가
  - `TriPeaksGame`(GameCore) — `peaks: [Card?]` 30슬롯(peak*10+local), 노출 판정(`isExposed`), undo/redo 스냅샷, `hint` 우선순위(피크 제거 > 드로), Codable
  - GameSaver: `persistence.savedTriPeaks` 별도 키
  - ViewModel: `@Published triPeaks: TriPeaksGame?` 8-way 분기(init restore/newGame/apply/undo/redo/hint/runAutoPlay(없음)/applyRaw/checkState/persist/clearSave/variant/current*), `makeTriPeaksMove`(카드→웨이스트), `tapTriPeaksCard/Stock/Waste`, `CardSource.triPeaks(Int)` 추가, 자동 플레이 없음
  - GameBoardView: `triPeaksTopRow`(스톡+웨이스트, 홈셀 없음) + `triPeaksBody`(3피크 가로 배치, 노출 카드 하이라이트, 카드 탭=제거, 드래그=웨이스트 드롭), `triPeaksCardOrigin` 좌표(렌더·드래그·드롭 공유), colFactor 19.5
### 검증
- 단위 테스트 **169개** 통과(TriPeaks 18개 추가 — 딜 레이아웃/무중복/결정성/노출 판정/1 랭크 차이 규칙(K↔A 거부)/비노출·빈 웨이스트 거부/제거 적용/드로·무재활용/승리/종료/undo·redo/Codable), `swift build`(debug·release) 경고 0건, release 설치·실행 확인 (PID 87709)

## [3.7.0] — 2026-08-06 — [macos]
### 추가 (T-120~T-124)
- **Pyramid(피라미드) 게임 추가**: 열 번째 변형 (표준 규칙)
  - 규칙: **1덱 52장**, **피라미드 28장**(7줄: 1+2+3+4+5+6+7) + **스톡 24장**(웨이스트 0장 시작), 카드 값 A=1~K=13, 노출 카드(맨 아래 줄 또는 아래 자식 2장이 제거된 카드)만 이동
  - **이동**: 합이 **13**인 노출 카드 제거 — 노출 피라미드 2장 / 노출 피라미드+웨이스트 / **K 단독(13)**, 스톡→웨이스트 드로(**재활용 없음**)
  - **승리** = 피라미드 28장 전부 제거, **종료** = 스톡 소진 + 합 13 짝/K 없음
  - `GameVariant.pyramid` + displayName "Pyramid" (SideBar 순환: Golf→Pyramid→FreeCell, 게임 번호 시트/통계 `allCases` 자동 반영)
  - `DealGenerator.pyramidDeal(gameNumber:)` — 앞 28장 피라미드(글로벌 인덱스 순), 뒤 24장 스톡
  - `Move` 3케이스: `.pyramidRemovePair(first:second:)` / `.pyramidRemoveWastePair(card:)` / `.pyramidRemoveSingle(card:)`
  - `PyramidGame`(GameCore) — `pyramid: [Card?]` 28슬롯, 노출 판정(`isExposed`: 아래 자식 2장 제거 시), undo/redo 스냅샷, `hint` 우선순위(K 단독 > 피라미드 짝 > 웨이스트 짝 > 드로), Codable
  - GameSaver: `persistence.savedPyramid` 별도 키
  - ViewModel: `@Published pyramid: PyramidGame?` 7-way 분기(init restore/newGame/apply/undo/redo/hint/runAutoPlay(없음)/applyRaw/checkState/persist/clearSave/variant/current*), `makePyramidMove`(카드→웨이스트), `tapPyramidCard/Stock/Waste`, `CardSource.pyramid(Int)` 추가, 자동 플레이 없음
  - GameBoardView: `pyramidTopRow`(스톡+웨이스트, 홈셀 없음) + `pyramidBody`(7줄 피라미드, 노출 카드 하이라이트, 카드 탭=짝 제거, 드래그=웨이스트 드롭), `pyramidCardOrigin` 좌표(렌더·드래그·드롭 공유), colFactor 10.7
### 검증
- 단위 테스트 **151개** 통과(Pyramid 22개 추가 — 딜 레이아웃/무중복/결정성/노출 판정/합 13 짝 제거/K 단독/웨이스트 짝/드로·무재활용/승리/종료/undo·redo/Codable), `swift build`(debug·release) 경고 0건, release 설치·실행 확인 (PID 87709)

## [3.6.0] — 2026-08-06 — [macos]
### 추가 (T-110~T-114)
- **Golf(골프) 게임 추가**: 아홉 번째 변형 (표준 규칙)
  - 규칙: **1덱 52장**, **7열×5장(전부 앞면)** + **스톡 16장** + **웨이스트 1장**, 웨이스트 맨 위와 **1 차이/같은 랭크**(수트 무관, **K↔A 인접 순환**)인 열 맨 아래 카드를 웨이스트로 제거, 열 간 이동 없음, **빈 열 재사용 없음**, 스톡 재활용 없음
  - **승리** = 7열 모두 비어있음, **종료** = 스톡 소진 + 제거 불가
  - `GameVariant.golf` + displayName "Golf" (SideBar 순환: Forty Thieves→Golf→FreeCell, 게임 번호 시트/통계 `allCases` 자동 반영)
  - `DealGenerator.golfDeal(gameNumber:)` — 35장 라운드로빈 7열 + 스톡 16 + 웨이스트 1
  - `Move.columnToWaste(columnIndex:card:)` 케이스 추가 + `Destination.waste` (드래그 목적지)
  - `GolfGame`(GameCore) — columns([[Card]])/stock/waste, undo/redo 스냅샷, `canMove`(columnToWaste/drawFromStock), `isAdjacent`(1차이/같은 랭크/순환), `hint` 우선순위(열→웨이스트 > 드로), Codable
  - GameSaver: `persistence.savedGolf` 별도 키
  - ViewModel: `@Published golf: GolfGame?` 5-way 분기(init restore/newGame/apply/undo/redo/hint/runAutoPlay(없음)/applyRaw/checkState/persist/clearSave/variant/current*), `makeGolfMove`(열→웨이스트), `tapGolfStock/Column/Waste`, 자동 플레이 없음
  - GameBoardView: `columnCount` 7 + `colFactor` 7.7, `golfTopRow`(스톡+웨이스트, 홈셀 없음), `golfColumnView`(전부 앞면, 맨 아래만 제거 가능), 드래그 소스(맨 아래 카드 1장)/드롭(웨이스트)/탭
  - GameVariant switch 정리: FreeCellRule/FreeCellGame/SideBarView에 `.golf` 명시 (Golf는 FreeCellRule 미사용 → false)
### 검증
- 단위 테스트 **129개** 통과(Golf 11개 추가 — 딜 레이아웃/무중복/결정성/인접 규칙(K↔A 순환)/제거 적용/빈 웨이스트 거부/스톡 드로·무재활용/승리/종료 판정/undo·redo/Codable), `swift build`(debug·release) 경고 0건, release 설치·실행 확인 (PID 87709)

## [3.5.0] — 2026-08-06 — [macos]
### 추가 (T-100~T-104)
- **Forty Thieves(포트티브스) 게임 추가**: 여덟 번째 변형 (표준 규칙 — 사용자 확정)
  - 규칙: **2덱 104장**, **10열×4장(전부 앞면)** + **스톡 64장**, 스톡 탭=1장 드로→웨이스트(**재활용 없음**), **홈셀 8개**(2덱 수트당 2홈) A→K, **같은 수트 K→A 내림차순**, **빈 열엔 아무 카드**
  - `GameVariant.fortyThieves` + displayName "Forty Thieves" (SideBar 순환: Yukon→Forty Thieves→FreeCell, 게임 번호 시트/통계 `allCases` 자동 반영)
  - `DealGenerator.fortyThievesDeal(gameNumber:)` — Microsoft RNG 재사용, 40장 라운드로빈 10열+스톡 64장
  - `FortyThievesGame`(GameCore) — columns([[Card]])/stock/waste/homes[8], undo/redo 스냅샷, `canMove`(columnToColumn/columnToHome/wasteToColumn/wasteToFoundation/drawFromStock), `canPlaceOnColumn`(같은 수트 `card == last.previous`, 빈 열 true), `homeIndex`(A=빈 홈 우선, 이외 같은 수트 다음 랭크), `movableRun`(바닥→위 같은 수트 내림차순), `hint` 우선순위(홈>웨이스트→열>열→열>드로), Codable
  - GameSaver: `persistence.savedFortyThieves` 별도 키
  - ViewModel: `@Published fortyThieves: FortyThievesGame?` 4-way 분기(init restore/newGame/apply/undo/redo/hint/runAutoPlay/applyRaw/checkState/persist/clearSave/variant/current*), `makeFortyThievesMove`(열→열/홈, 웨이스트→열/홈), `tapFortyThievesStock/Waste/Column/Home` + 더블클릭 + `isFortyThievesSelected`
  - GameBoardView: `columnCount` 10 + `colFactor` 10.7, `fortyThievesTopRow`(스톡+웨이스트 좌, 홈셀 8 우), `fortyThievesColumnView`(전부 앞면, 같은 수트 시퀀스), 드래그 소스(웨이스트만)/드롭(홈셀 8)/`draggedCards(.waste)`, 탭/더블클릭/힌트 소스
### 버그 수정 (T-101 테스트가 발견)
- **FortyThievesGame.canMove(.columnToColumn)** 그룹 검증 오류: `moving[0]`(시퀀스 맨 위) 대신 `moving[moving.count - cardCount]`(이동할 그룹의 맨 위)로 검증해야 함 — cardCount<시퀀스 길이일 때 이동이 거부되던 문제
### 검증
- 단위 테스트 **118개** 통과(FortyThieves 12개 추가 — 딜 레이아웃/2덱 정확성/같은 수트·빈 열 규칙/그룹 이동/movableRun/스톡 드로·무재활용/웨이스트→열·홈/홈셀 8·승리/undo·redo/Codable), `swift build`(debug·release) 경고 0건, release 설치·실행 확인 (PID 87709)

## [3.4.0] — 2026-08-06 — [macos]
### 추가 (T-096~T-098)
- **Klondike 스톡 재활용**: 스톡이 비면 스톡 클릭 시 웨이스트를 역순으로 스톡에 재활용
  - `Move.recycleStock` 케이스 추가 (undo/redo/moveCount 반영, 재활용도 1수 카운트)
  - `KlondikeGame.canMove(.recycleStock)` = 스톡 비고 웨이스트 비어있지 않음, `applyUnchecked` = 웨이스트 역순 복원
  - `hintCandidates`에 재활용 포함 (스톡 비고 웨이스트 있을 때 `hasAnyMove` 판정 정확화)
  - ViewModel `tapKlondikeStock`: 스톡 있으면 드로, 없으면 재활용. `moveDescription` "웨이스트 → 스톡 재활용"
  - FreeCellGame/YukonGame `canMove`/`apply`에 `.recycleStock` 명시 분기
  - 스톡 소진 시 재활용 아이콘(`arrow.uturn.left.circle`)은 기존 렌더 유지
### 검증
- 단위 테스트 **106개** 통과(Klondike 재활용 5개 추가 — 역순 복원/순서 보존/빈 스톡 거부/빈 웨이스트 거부/undo·redo), `swift build` 경고 0건 (ConfettiView 미수정 `var` → `let` 정리 포함)
### UX (T-099)
- **드래그 오버레이 grab offset 보정**: 잡은 카드(원본 topIndex = 오버레이 첫 카드)가 원본 위치에서 시작해 커서를 정확히 추종 — 스택 가운데가 아니라 실제 잡은 카드 기준으로 붙던 어긋남 해소 (`DragState.topIndex` 추가 + `startCardOrigin`/`startLocation` 기반 dx/dy 보정)

## [3.3.0] — 2026-08-06 — [macos]
### 추가 (T-080~T-088)
- **Yukon(유콘) 게임 추가**: KlondikeGame과 병렬로 일곱 번째 변형
  - 규칙: 1덱 52장, **7열**(열0=1장 앞면, 열1~6=뒤집힌 5장+앞면 1~6장), **스톡/웨이스트 없음**, 홈셀 4개
  - **유콘 이동**: 아무 앞면 카드+그 위 전부를 그룹 이동(내부 순서 무관 — 시작 카드만 목적지 규칙 충족), 교대색 내림차순, 빈 열엔 K만
  - **홈셀**: 열→홈만(A→K 같은 수트), 뒤집힌 카드 노출 시 자동 앞면, 승리=홈 4개 모두 13장
  - `GameVariant.yukon` + `DealGenerator.yukonDeal(gameNumber:)` — Microsoft RNG 재사용, `[[ColumnCard]]` 반환
  - `YukonGame`(GameCore) — columns/homes/gameNumber/moveCount, undo/redo 스냅샷, `canMove`(columnToColumn/columnToHome), `movableGroup(from:topIndex:)`, `flipTopIfNeeded`, `hint/hintCandidates`
  - GameSaver: `persistence.savedYukon` 별도 키
  - ViewModel: `@Published yukon: YukonGame?` 분기, init restore, newGame, 이동 디스패치, `tapYukonColumn`/`doubleClickYukonToHome`/`isYukonSelected`, undo/redo, hint, persist/clearSave, `variant` 최우선
  - GameBoardView: `columnCount`/`colFactor`(7.7), `yukonColumnView`(faceUp/faceDown 렌더), 상단 홈셀 4개(우측), 드래그/드롭 `movableGroup`(뒤집힌 카드 소스 불가), 탭/더블클릭 디스패치
  - SideBar 게임 전환 7개 순환(FreeCell→Baker's→Klondike→Spider→Sea Tower→Super FreeCell→Yukon→FreeCell), 게임 번호 시트 `allCases` 자동
### 리팩토링 / 예상 버그 수정 (T-089~T-095)
- **B1**: Yukon `runAutoPlay`가 `hintCandidates()` 미분기로 홈 이동 안 됨 → `columnToHome` 필터 분기 추가
- **B2**: Klondike 웨이스트 탭이 무조건 0열로 이동 → `select(source: .waste, cardCount: 1)`로 단순화
- **B3**: 뒷면 카드 a11y 라벨이 카드 값 노출 → `showBack` 시 "뒷면 카드"
- **B4**: GameNumberSheet 변형 즉시 시작 + confirmNewGame variant 조합 파기 → 로컬 `selectedVariant` + "게임 시작" 버튼에서만 시작, Spider 난이도 시트 반영
- **B5**: 승리 후 undo 시 승리 UI/타이머 미복구 → `resetWinUIAfterUndoIfNeeded()`
- **B6**: Yukon 홈 힌트/펄스가 전체 홈에 그려짐 → 해당 수트 홈만 강조 (`isYukonHomeHintSource` + `lastHomeCard` 펄스)
- **B7**: 미사용 변수/파라미터 경고 정리 (`homeStartX`/`boardSize`/`overlayWidth`/`overlayHeight` 등)
- **B8**: `build_and_run.sh` `VERSION="1.2.0"` → `3.3.0`
- **R1**: 열 클릭 4종(`tapCard`/`tapKlondikeColumn`/`tapSpiderColumn`/`tapYukonColumn`) → `handleColumnTap` 통합
- **R2**: `GameSaver` 제네릭 `store<T>`/`load<T>` 헬퍼로 4종 save/restore 중복 제거
- 힌트 첫 호출이 2번째 후보부터 표시되던 문제 → 첫 힌트는 최우선(홈 이동)부터
- 미사용 데드 코드 제거: `DragPayload`, `CardSource.description`, `newGame(spiderDifficulty:)`
### 검증
- 단위 테스트 **101개** 통과, `swift build` 경고 0건, release 빌드/설치/실행 완료 — 수동 검증 가이드 `docs/tests/v3.3_macos.md`

## [3.2.0] — 2026-08-06 — [macos]
### 추가 (T-070~T-078)
- **Sea Tower(시타워) 게임 추가**: FreeCellGame 변형 다섯 번째
  - 규칙: 1덱 52장, **10열×5장 교대 딜 + 시작 카드 2장을 프리셀 0,1에 배치**, 프리셀 4개, 홈셀 4개
  - **같은 수트만 내림차순**(`movableRun`/`canMoveToColumn` 분기), **빈 열엔 K만**
  - **수퍼무브 = 빈 프리셀+1** (빈 열은 임시 저장으로 못 씀 — Baker's 방식이 아닌 프리셀만 사용), 1장 제한 없음
  - `DealGenerator.seaTowerDeal` — Microsoft RNG 재사용, 10열 교대 50장 + 나머지 2장 프리셀 반환
- **Super FreeCell(슈퍼 프리셀) 게임 추가**: FreeCellGame 변형 여섯 번째
  - 규칙: **2덱 104장** 1회 셔플, **10열**(첫 4열 11장/다음 6열 10장), 프리셀 **6개**, 홈셀 4개
  - **교대색** 내림차순(표준 프리셀 규칙), **빈 열엔 아무 카드**
  - **홈셀은 수트 고정** + A→K→A→K 순환(각 26장), 승리 = 홈 4개 모두 26장
  - **수퍼무브 = (빈 프리셀+1) × 2^(빈 열)** 표준 공식(목적지 빈 열 제외)
  - `DealGenerator.superFreeCellDeal` — 2덱 104장 Microsoft RNG 셔플, 모든 카드 정확히 2장씩
- `FreeCellGame` 확장: `columnCount(for:)`(seaTower/super=10), `freeCellCount(for:)`(seaTower=4, super=6), init variant별 딜, `isWon`(super 홈 26장), `canMoveToHome`/`homeIndex(for:)`/`suitHomeIndex(for:)`(super 수트 고정 + K 위 A), 수퍼무브 용량(seaTower 빈 열 무시)
- GameSaver: `persistence.savedSeaTower` / `persistence.savedSuperFreeCell` 별도 키 (기존 freecell/bakers 저장 덮어쓰기 방지)
- ViewModel: init restore 순서 spider→klondike→seaTower→superFreeCell→freecell, `persist()`/`clearSave()` variant 분기
- GameBoardView: `columnCount`/`freeCellCount`/`colFactor`(10열 변형 10.7) 파라미터화, 상단행 프리셀 렌더 `freeCellCount(for:)`, 드래그/드롭 프리셀 개수 파라미터화, 열 `ForEach id: \.offset`(2덱 중복 카드 대응)
- SideBar 게임 전환 6개 순환(FreeCell→Baker's→Klondike→Spider→Sea Tower→Super FreeCell→FreeCell), 게임 번호 시트 `allCases` 자동
### 검증
- 단위 테스트 **91개** 통과(Sea Tower 10개 + Super FreeCell 9개 추가, 기존 72개 회귀), release 빌드/설치/실행 — **수동 검증 대기**

## [3.1.0] — 2026-08-06 — [macos]
### 추가 (T-060~T-068)
- **Spider(스파이더) 게임 추가**: FreeCell/Baker's/Klondike와 병렬로 네 번째 변형
  - `SpiderGame`(GameCore) — 10열(뒤집힌 카드 `ColumnCard{card, faceUp}`, 열 0~3=6장/4~9=5장), 스톡 5더미(각 10장), 완성 수트 표시. 홈셀/프리셀/웨이스트 없음
  - **난이도 3종**: 1수트(초급, 스페이드 8세트) / 2수트(중급, 스페이드+하트 4세트씩) / 4수트(고급, 전 수트 2세트씩) — `SpiderGame.Difficulty` enum, 게임 번호 시트 난이도 세그먼트
  - 규칙: **같은 수트 K→A 내림차순 시퀀스만 이동**(`movableRun`), 빈 열엔 아무 카드, 열에 13장 K→A 완성 시 자동 제거(`completedSuits`+1), 스톡 탭=각 열에 앞면 1장 딜(`Move.dealFromStock`), 승리=`completedSuits == 8`
  - `DealGenerator.spiderCards(gameNumber:suitCount:)` — 104장(2덱), Microsoft RNG 재사용, 난이도별 수트 구성
  - `GameVariant.spider` 추가 — 통계/기록/최단시간은 `variant.rawValue` 키로 자동 분리
  - ViewModel: `spider`/`spiderDifficulty` 분기(init 복원, newGame, 이동 디스패치, 탭, 힌트, undo/redo, checkState, persist). Spider 자동 플레이 없음
  - GameBoardView: 상단 스톡 5더미 + 완성 수트 표시(완성 N/8), 10열 faceUp/faceDown 렌더(`colFactor` 10.7), 드래그/드롭 파라미터화(열 10개, 상단 드래그 소스 없음), 게임 전환 4개 순환(FreeCell→Baker's→Klondike→Spider→FreeCell)
  - GameSaver: `persistence.savedSpider` 키로 Spider 별도 저장/복원(난이도 포함)
### 검증
- 단위 테스트 **72개** 통과(Spider 13개 추가, 기존 59개 회귀), release 빌드/설치/실행 — **수동 검증 대기**

## [3.0.0] — 2026-08-06 — [macos]
### 추가 (T-050~T-058)
- **Klondike(솔리테어) 게임 추가**: 기존 FreeCell/Baker's와 병렬로 세 번째 변형
  - `KlondikeGame`(GameCore) — 7열(뒤집힌 카드 `ColumnCard{card, faceUp}`), 스톡 24장, 웨이스트, 홈셀 4개. 내림차순+교대색, 빈 열엔 K만, 앞면 카드만 이동, 스톡 1장 드로, 빈 열 뒤집힌 카드 탭으로 뒤집기
  - `Move` 확장: `drawFromStock`, `wasteToColumn`, `wasteToFoundation`, `flipColumnCard` (기존 7개 유지)
  - `GameVariant.klondike` 추가 — 딜은 Microsoft RNG 재사용, 통계/기록/최단시간은 `variant.rawValue` 키로 자동 분리
  - ViewModel: `klondike` 분기(init 복원, newGame, 이동 디스패치, 탭/더블클릭, 힌트, 자동 플레이, undo/redo, checkState, persist). `CardSource.waste` 추가
  - GameBoardView: 스톡/웨이스트/홈셀 상단행 + 7열 faceUp 렌더, 드래그 지오메트리 파라미터화(`columnCount`/`colFactor`), 게임 전환 버튼 3개 순환(FreeCell→Baker's→Klondike→FreeCell)
  - GameSaver: `persistence.savedKlondike` 키로 Klondike 별도 저장/복원
### 수정
- `currentGameNumber`/`currentMoveCount`/`currentIsWon` 프로퍼티로 뷰의 variant 무관 참조 통일
- Klondike 자동 플레이: 홈셀 이동(`columnToHome`/`wasteToFoundation`)만 자동 적용(FreeCell의 안전 카드 규칙은 미사용)
### 검증
- 단위 테스트 **59개** 통과(Klondike 11개 추가, 기존 48개 회귀), release 빌드/설치/실행 — **수동 검증 대기**

## [2.4.0] — 2026-08-06 — [macos]
### 추가 (T-041~T-046)
- **볼륨 조절**: 설정에 효과음/BGM 볼륨 슬라이더(0~1) — SoundPlayer(NSSound.volume) + BGMPLayer(AVAudioPlayer.volume) 실시간 반영
- **창 크기·위치 기억**: `WindowAccessor` + `setFrameAutosaveName`으로 창 프레임 자동 저장/복원
- **승리 연출 확장**: 승리 시 Hero+Tink+Glass 팡파레 시퀀스 + `ConfettiView`(색종이/원/별 낙하 파티클)
- **카드 뒷면 패턴**: `CardBack` enum(클래식/블루/골드) 설정 + 딜 애니메이션 중 뒷면 렌더링
- **경과 시간 표시**: 게임 정보에 실시간 mm:ss + 일시정지/재개 버튼(타이머 정지/재개, 시간 누적 유지)
- **통계/기록 초기화**: 설정 데이터 섹션에서 전체+변형별 통계 및 승리 기록 삭제(확인 다이얼로그)
### 수정
- `elapsedSeconds` computed → Timer 기반 `@Published`(1초 갱신), 승리 시 정지, 복원 게임도 재시작
### 검증
- 단위 테스트 **48개** 통과(RecordStore.clearAll 추가), release 빌드/설치/실행

## [2.3.0] — 2026-08-05 — [macos]
### 추가 (T-036~T-039)
- **승리 기록**: RecordStore(최대 50건, 변형별 `records.{variant}`), 승리 시 자동 기록. 통계 > 변형별 > "최근 승리"(게임번호/이동/시간, 최대 10개)
- **승리 연출**: 홈 도착 카드 초록 테두리 펄스(0.5s) + 승리 배너("🎉 승리" + 게임번호) 스케일 페이드인
- **배경음악**: 코드 생성 아르페지오 루프(`resources/bgm.wav`) + 설정 "배경음악" 토글(기본 꺼짐). 생성 스크립트 `scripts/gen_bgm.swift`
- **보드 줌**: 설정 슬라이더(0.7~1.4) + ⌘+/⌘- 단축키, 카드 크기 배율 적용
### 검증
- 단위 테스트 **47개** 통과, release 빌드/설치/실행 (bgm.wav 번들 포함 확인), 사용자 확인 "다 잘됨"

## [2.2.0] — 2026-08-05 — [macos]
### 추가 (T-031~T-035)
- **딜 애니메이션**: 새 게임 시 카드 (0.5s easeOut)로 보드에서 아래로 떨어지며 나타나는 연출 (`isDealing` 0.7s 후 애니메이션)
- **게임 시간 측정**: 게임 시작 시각 기록, 승리 시 최단 시간 기록(`stats.{variant}.bestTimeSeconds`). 통계 > 변형별 > "최단 승리" 표시
- **새 게임 확인**: 이동 1회 이상이고 미승리 상태에서 새 게임/번호/형식 전환 시 확인 다이얼로그("이동 N회가 사라집니다"). 승리 시 화면 하단 "다음 게임" 버튼
- **사이드바 게임 전환**: 좌측 게임 그룹에 FreeCell ↔ Baker's Game 전환 아이콘 버튼 추가
- **회귀 테스트**: 오토플레이 무한루프 수렴+상태 일관성(홈 연속성/중복 카드), 안전 카드 잔존 검증, Baker's 빈 열 수퍼무브 경계, 더블클릭 bottom 카드만 이동, 빈 열/빈 프리셀 경계
### 수정
- `newGame` → `requestNewGame`/`confirmNewGame`/`cancelNewGame` 흐름으로 재구성 (확인 다이얼로그 연동), `applyGameNumber`/`switchVariant`도 확인 경유
### 검증
- 단위 테스트 **45개** 통과, release 빌드/설치/실행 (사용자 확인 진행 중)

## [2.1.0] — 2026-08-05 — [macos]
### 추가 (T-026~T-029 — 후속 4종)
- **통계 형식별 분리**: 통계 시트에 "전체 / FreeCell / Baker's Game" 세그먼트. 변형별 총게임·승리·승률·연승 기록, 게임 번호도 변형별로 기억. 기존 전체 키는 유지 (사용자 확인 완료)
- **효과음**: 이동(Glass)/홈 배치(Tink)/승리(Hero) 시스템 사운드. 설정 > 게임플레이 > 효과음 토글. `SoundPlayer` 신규
- **키보드**: `Esc`=선택 해제, `Space`=선택 카드 홈 이동, 힌트는 `⌘H` 순환 + `Enter` 적용. 게임정보 접근성 라벨에 게임명 포함
- **힌트 고도화**: `hintCandidates()`로 모든 유효 이동 수집(우선순위 유지). `⌘H` 반복 시 다음 후보("힌트 2/5: ...") 순환, 소스 카드를 **노란 테두리**로 하이라이트, `Enter`로 적용. 이동/취소/새 게임 시 하이라이트 해제
### 검증
- 단위 테스트 **39개** 통과 (힌트 후보 유효성/승리 시 비어있음 추가), release 빌드/설치/실행 (사용자 확인 완료 — "다 좋아")

## [2.0.0] — 2026-08-05 — [macos]
### 추가 (T-019~T-025 — 두 번째 게임 Baker's Game)
- **GameVariant enum** (`freecell` / `bakersGame`) — 게임 형식을 모델에 저장
- **Baker's Game 규칙**: 같은 딜 번호(#1~#1,000,000) 그대로, 프리셀 없음(0개), 타블로 쌓기 = **같은 수트만** 내림차순, 열→열 이동은 **한 번에 한 장만**, 홈셀은 A→K 같은 무늬 (기존 프리셀과 동일)
- **게임 번호 선택 시트**: "게임 형식" 세그먼트(FreeCell / Baker's Game) 추가 — 같은 번호로 두 형식 비교 가능
- **FreeCellRule 분기**: `canMoveToColumn`/`movableRun`에 variant 파라미터, Baker's는 수퍼무브 용량(빈 열 기반) 제한
- **FreeCellGame**: `variant` 필드 + `freeCellCount(for:)` + custom Codable(`decodeIfPresent` → legacy 저장 무손상 복원, 기본 freecell)
- **창 제목**: "Pure FreeCell — Baker's Game N" 형식으로 게임명 표시
- **프리셀 조건부 렌더**: Baker's에서 프리셀 행 숨김, 드래그/탭/ViewModel freeCell 인덱스 접근 방어
### 추가 (v2.0.1 — 설정 화면 정리)
- **설정 시트를 macOS Form + Section으로 재구성**: 카드(스타일) / 보드(배경) / 게임플레이(자동 이동 + 애니메이션 슬라이더) 3섹션, 섹션 헤더 아이콘 + 좌측 정렬 + 하단 바 영역 닫기 버튼. (사용자 "어 좋다" 확인)
### 검증
- 단위 테스트 **37개** 통과 (신규 BakersGameTests 6개: 같은 딜 쌍 검증/같은 수트 쌓기/1장 제한/프리셀 거부/홈 이동/legacy 호환), release 빌드/설치/실행

## [1.2.0] — 2026-08-05 — [macos]
### 추가 (T-018 접근성 VoiceOver 고도화)
- **카드 접근성**: 라벨("10 ♥")에 더해 **힌트**(타블로/프리셀: "누르면 선택, 두 번 누르면 홈셀로 이동", 홈셀: "누르면 선택, 홈에서 꺼낼 수 있음")와 **선택 상태 값**(선택됨) 추가
- **보드 영역 그룹**: 홈셀/프리셀/각 타블로 열을 접근성 컨테이너로 묶어 VoiceOver 내비게이션 문맥 제공 (홈셀/프리셀/열 N 라벨)
- **게임 정보 결합**: "게임 번호 N, 이동 M" 한 접근성 요소로 묶음
- **사이드바 버튼**: 접근성 라벨(제목) + 힌트(단축키) 명시
- **드래그 오버레이**: `.accessibilityHidden(true)`로 VoiceOver 노출 제거
- (macOS SwiftUI에 `accessibilityLiveRegion` 미지원 → 메시지 자동 안내는 제외)
### 수정 (v1.2.1)
- **카드 적은 열이 세로 중앙으로 정렬되던 문제**: 자동 이동 등으로 타블로 열의 카드가 줄어들면 그 열(빈 카드판)이 보드 세로 중앙으로 이동. 원인: `columnView`가 내재 높이로 렌더링되어 HStack 정렬에 의존. **수정**: 각 열을 `frame(maxHeight: .infinity, alignment: .top)`으로 최대 높이 + **상단 정렬 강제** → 카드 수와 무관하게 모든 열이 위에 붙음
### 검증
- 단위 테스트 30개 통과, release 빌드/설치/실행

## [1.1.0] — 2026-08-05 — [macos]
### 추가
- **자동 저장 (T-017)**: 게임 도중 앱 종료/크래시에도 진행 상태를 잃지 않도록 **게임 전체 상태(열/프리셀/홈/이동 횟수 + undo/redo 스택)를 UserDefaults에 JSON으로 자동 저장**하고 재시작 시 이어서 복구
  - `Card`/`Suit`/`Rank`/`FreeCellGame`에 `Codable` 추가 (Int raw-value enum → 자동 합성)
  - `FreeCellGame`의 undo/redo 스택(내부 `Snapshot`)까지 직렬화 → 실행 취소 기록도 보존
  - `Persistence/GameSaver.swift` 신규: `save`/`restore`/`clear`/`hasSavedGame`
  - 저장 시점: 이동/undo/redo/자동 이동/새 게임 직후 + 앱이 백그라운드·비활성 전환 시 안전 저장 (`scenePhase`)
  - 복구: `FreeCellViewModel.init`에서 저장 상태가 있으면 복원(자동 플레이 재실행 없음), 없으면 기존 신규 게임
  - 승리 시 저장 클리어 → 완료된 게임 대신 새 게임으로 시작
### 검증
- 단위 테스트 **30개 전부 통과** (신규 `testCodableRoundTrip`: 이동 적용 상태 + undo 기록까지 round-trip 복원 확인)
- release 빌드/설치/실행, 앱 재시작 후 자동 저장 복구 확인

### 수정 (v1.1.1)
- **드래그 히트 판정 버그 수정**: 자동 이동으로 타블로 카드가 줄어든 후, 열의 **마지막 카드 아래쪽 42%를 클릭하면 클릭은 되는데 드래그가 안 잡히던 증상**. 원인: `dragSource` 히트가 카드 간격 `step`(=카드높이×0.58) 구획으로만 판정해 마지막 카드의 하단 0.42 카드높이 영역에서 `i`가 `cards.count`를 초과해 nil을 반환 → 클릭(onTapGesture, 카드 전체 프레임)은 되나 드래그 제스처가 시작되지 않았음. **수정**: 마지막 카드의 bottom까지 히트 허용(`i = min(Int(y/step), lastIndex)` + `y ≤ lastCardBottom` 가드). 사용자 "정상" 확인
- **드래그 오버레이 여러 장 개선** (사용자 피드백 반복 반영):
  - 오버레이 카드 간격이 보드와 달라(0.42높이 vs 보드 0.58높이 step) **카드들이 더 빽빽하게 겹쳐 보이던 문제** → 보드와 동일한 `step` 간격으로 보정
  - 오버레이가 "카드 원위치 + 마우스 이동량" 기준이라 여러 장일수록 **카드가 마우스 아래로 쌓이고 첫 카드가 마우스 위로 밀리던 문제** → **드래그 오버레이 전체 중앙을 마우스 포인터에 고정** (1장=카드 중앙, 여러 장=카드 묶음 중앙)
  - 드롭 목적지 판정을 **마우스 포인트 위치**(`drag.location`) 기준으로 통일 → 렌더링 위치와 드롭 판정 일치, "놓치도 못함" 해소
  - 사용자 최종 확인: "어 중앙에 있네 좋아 .. 정상"

## [1.0.0] — 2026-08-05 — [macos]
### 추가
- 프리셀 MVP 전체 기능 구현 (GameCore + SwiftUI 앱)
- 마이크로소프트 정통 규칙: LCG 기반 딜(#1/#617/#11982 검증), 수퍼무브 공식, 홈셀 회수 허용
- 게임 번호 1~1,000,000 지원, 기본 시드 1
- 게임 로직: 이동 검증, Undo/Redo, 힌트, 자동 플레이, 승리 판정
- UI: 커스텀 벡터 카드(클래식/심플), 배경 4종(그린/블루/다크/화이트), 드래그&드롭/클릭/더블클릭, 단축키, 게임 번호 시트, 통계(UserDefaults), 설정
- 배포: AppIcon.icns, `scripts/build_and_run.sh [debug|release]` (.app 번들 → ~/Applications 설치 → 코드서명 → 실행)

### 검증
- 단위 테스트 28개 전부 통과 (DealGenerator #1/#617/#11982, Rule, Game, AutoPlay)
- release 빌드 성공, 창 1000×732, 카드 52장 렌더링, a11y 덤프 3종 저장
- 성능: RSS 92.8MB (예산 300MB), CPU <1% 유휴

### 수정 (v1.0.1)
- **타블로 상단 정렬 수정**: 카드 열이 아래쪽 정렬로 되어 아래 카드 이동 시 카드들이 아래로 떨어지던 문제 → `Spacer` 제거, 모든 열 top 카드 y 좌표 일치(y=150) 검증
- **카드 면 디자인 개선**: 중앙 무늬가 납작(w×0.46/h×0.34)하고 중앙을 벗어나 작게 보이던 문제 → 정비율 큰 무늬(w×0.62, 카드 중앙 배치), 좌측 상단 랭크 확대, 우측 하단 반전 랭크/무늬 추가로 카드 면을 꽉 채움
- **접근성(T-018 일부)**: 각 카드를 하나의 접근성 요소로 결합, 접근성 라벨(예: "10 ♥") 추가 → VoiceOver 호환 + 텍스트 검증 가능

### 수정 (v1.0.2)
- **다중 카드 이동 버그 수정**: `movableRun`이 bottom→top 순서로 반환하는데 `canMove`는 `columns.suffix`(top→bottom)와 비교해 순서 불일치 → **2장 이상 이동이 항상 거부**되던 문제. `movableRun`을 top→bottom 순서로 통일 + `run.suffix` 비교로 수정. 클릭 선택 계산도 `fromBottom+1`로 수정. 회귀 테스트 `testMultiCardColumnToColumn`(8♠,7♥,6♠ 한 번에 이동) 추가
- **드래그 범위 제한**: 이동 가능한 시퀀스(movableRun) 내의 카드에서만 드래그 시작되도록 수정
- **카드 크기/창 크기 조정**: 창 기본 900×780(가로 1000→900 축소), overlapFactor 0.45→0.42 → 카드 85×60 → 96×67로 확대. 접근성 덤프로 카드 크기 96px, 상단 정렬 유지 확인

### 수정 (v1.0.3)
- **자동 이동을 게임 중에도 적용**: 기존에는 게임 시작 시에만 실행되던 안전한 카드 홈셀 자동 이동이, 이동 후에도 적용되도록 수정 (autoPlayEnabled 토글 켜짐 기준). 설정 라벨을 "자동 이동 (에이스 등 안전한 카드를 게임 중 홈셀로)"로 명확화
- **사이드바 아이콘 버튼 추가**: 게임 화면 좌우 빈 공간에 게임 메뉴 기능 8종을 아이콘으로 배치. 좌측: 게임(새 게임, 게임 번호) / 이동(실행 취소, 다시 실행), 우측: 도움(힌트, 자동 플레이) / 정보(통계, 설정). 그룹별 Divider 구분, 아이콘+라벨+툴팁(단축키), 배경색(화이트 포함) 대응, 실행취소/다시실행은 비활성 표시

### 수정 (v1.0.4)
- **메시지 배너 하단 이동**: 상단에 표시되던 "자동 플레이: N장..." 알림이 카드를 가리던 문제 → 화면 하단 중앙으로 이동 (전환 애니메이션도 bottom edge로)

### 수정 (v1.0.5)
- **메시지 3초 자동 소멸**: 승리/패배/자동 플레이/힌트/게임 번호 오류 메시지가 표시된 후 계속 남아있던 문제 → `showMessage()` 헬퍼로 3초 후 자동 사라짐 (새 메시지 표시 시 이전 타이머 취소, 새 게임/이동 시 즉시 해제)
- **창 가로 축소**: 750으로 축소하면서 중앙 게임 번호(게임 번호/N/이동 N)가 잘리던 문제 → 830으로 복원 후, 사용자 요청으로 메뉴 버튼 1개 폭(44px)만큼 더 줄여 **786×780**로 확정 (게임 번호 온전히 표시, 카드 96×67 유지)
- **게임 번호 두 줄 줄바꿈 수정**: 숫자 Text에 `lineLimit`이 없어 좁은 폭에서 "967,231"이 두 줄로 나뉘던 문제 → `.lineLimit(1)` + `.minimumScaleFactor(0.5)` + `.fixedSize(horizontal: true)`로 **항상 한 줄** 강제 (a11y 검증: 86×24 한 줄)
- **창 타이틀바에 앱 이름 + 게임 번호 표시**: `hiddenTitleBar` 제거, `.navigationTitle`로 **"Pure FreeCell — 967231"** 표시 (새 게임 시 번호 자동 갱신). 게임 번호가 중앙 게임정보와 타이틀바 양쪽에서 확인 가능
- **게임 번호 중앙 여백 수정**: topRow를 HStack(Spacer 배치) → ZStack 중앙 오버레이로 변경. 홈셀+프리셀 간격 6→2로 좁히고 카드 크기를 96×67→90×63으로 미세 축소해 좌우 **여백 ~20px 확보**. 게임 번호 중심이 보드 중심(391)과 일치(389, 2px 오차) — 좌우 여백 대칭 (a11y 검증)
- **카드 스타일 클래식/심플 차별화**: 기존에 배경색(1.0 vs 0.97)만 달라 구분이 어렵던 문제 → 클래식(흰 카드 + 진한 테두리 + 세리프 랭크 폰트) / 심플(밝은 회백색 카드 + 옅은 테두리 + 라운드 랭크 폰트)으로 시각적 차이를 명확히 구분

### 수정 (v1.0.6)
- **드래그 시 카드 프리뷰 따라다님 (T-016)**: `.onDrag`(NSItemProvider, macOS에서 프리뷰 미표시 문제) → `.draggable(payload) { preview }`로 전환 시도. **사용자 피드백: "프리뷰가 마우스 포인트를 따라가지 않고, 선택하면 포인터로 카드가 오며, 놓으면 카드가 아래로 사라진다"** → `.draggable` 커스텀 프리뷰가 SwiftUI 기본 드래그 프리뷰와 충돌해 커서 미추종/아래 미끄러짐 현상. **커스텀 드래그 오버레이 방식으로 전면 교체**:
  - `DragState`(source/cardCount/location) 상태로 **마우스 위치 직접 추적** (`DragGesture` + `coordinateSpace("board")`)
  - 드래그 중 이동 카드 시퀀스를 ZStack 최상단 오버레이(`zIndex(100)`)로 렌더링하고 `position(x:y + 카드높이×0.45)`에 배치해 **커서에 정확히 추종**
  - 드롭 시 마우스 좌표로 목적지 판정(`dropTarget(at:boardSize:cardSize:)`): 상단 영역(y<열시작)은 홈셀/프리셀, 하단은 열 인덱스 계산 후 `vm.move(cardAt:cardCount:to:)` 호출
  - `.draggable`/`DragPayload`/`dragPreview`/`UTType` 제거, 탭(클릭/더블클릭) 로직은 기존 유지
- **사이드바 아이콘 확대 및 타블로 정렬**: 아이콘 36→44pt, 라벨 9→11pt로 확대하고, 사이드바를 세로 중앙 → 상단 정렬로 변경. 아이콘 버튼이 홈셀 아래 **타블로 카드 최상단 줄(y=164)과 정확히 일치**하도록 정렬 (a11y 덤프로 좌우 버튼 y=164, 타블로 첫 카드 y=164 확인)

### 수정 (v1.0.6-2)
- **드래그 좌표 정밀화 (커서 정확 추종)**:
  - y축 오류: `dragSource`가 `fromBottom`(아래서부터) 인덱스를 반환해 `cardBoardOrigin`이 그걸 위에서부터로 잘못 사용 → **잡은 카드보다 6장 위에 오버레이가 뜨던 증상** 수정. `dragSource`가 `topIndex`(위에서부터 i)를 반환하도록 변경
  - x축 오류: 타블로 열이 중앙 정렬인데 보드 좌측 기준으로 x 계산 → **마우스 포인트 옆 카드가 잡히던 증상** 수정. `columnsStartX(boardSize:cardSize:) = 14 + (보드폭 - 28 - 열묶음폭)/2` 헬퍼로 중앙 정렬 오프셋 반영 (드래그 시작/오버레이/드롭 판정 3곳 공용)
  - 드롭 판정을 카드 좌상단 → **카드 중심**(`dropPoint = startCardOrigin + delta + 오버레이/2`)으로 변경해 정확도 개선
  - 마우스 추적을 `DragGesture` 이동 이벤트 → `onContinuousHover`(좌표 지속 추적)로 변경
  - 사용자 확인: "드래그 너무 잘 되. 굿!!!"
- **자동 이동 연쇄 적용**: 기존에는 자동 이동이 1회만 실행되어 둘째/셋째 안전 카드가 남던 문제 → `runAutoPlay()`를 while 루프로 **안전 이동이 소진될 때까지 반복** ("자동 플레이: N장...")
- **더블클릭 홈 이동 수정**: macOS에서 `onTapGesture(count:2)` + `(count:1)` 동시 등록 시 더블클릭이 무력화되던 문제 → **시간 기반(0.35초) 더블클릭 판정** `handleTap(identifier:single:double:)`로 교체. 타블로 맨 아래 카드 → 홈 자동 이동, 프리셀 → 홈 이동. 단일 클릭은 지연 없이 즉시 실행
- **드래그 오버레이 겹침**: 드래그 중 카드가 VStack(펼침)으로 떨어져 보이던 문제 → ZStack + `offset(y: i × 카드높이×0.42)`로 보드와 동일하게 겹쳐 표시. `finishDrag` 오버레이 높이 계산도 동일 규칙으로 일치
- **크래시 수정 (실행 취소)**: 앱 종료 크래시(PID 30711) — `FreeCellGame.undo()` line 192에서 **빈 홈셀의 `removeLast()`** 호출로 "Can't remove last element from an empty collection" 트랩. 원인: 이동 기반 역연산이 홈 상태를 재계산하다가 불일치 발생. **상태 스냅샷 기반 undo/redo로 전면 교체** — `apply` 시 이동 전 전체 상태(열/프리셀/홈/moveCount)를 스택에 저장하고, undo/redo는 스냅샷 복원만 수행 → 상태 불일치 여부와 무관하게 크래시 불가. `undoStack`/`redoStack`은 `[Move]` → 내부 `Snapshot`으로, 외부는 `canUndo`/`canRedo`로 접근

### 알려진 제한
- v1.1에서 자동 저장(중간 복구), VoiceOver 접근성 고도화 예정 (T-017, T-018)
