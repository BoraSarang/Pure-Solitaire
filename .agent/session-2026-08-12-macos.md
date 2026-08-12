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

## v3.19 점수 체계 구현 (T-198~T-200)

### 1. 무엇을 (T-198~T-200)
- **T-198**: `Sources/GameCore/Scoring.swift` — 이동 점수(스톡 +5/홈 +10/홈에서 -15/재활용 -100/뒤집기 +5/제거 계열)/승리 보너스(500·800·300)/Klondike 시간 패널티(10초당 -2)/finalScore. `ScoringTests.swift` 7개.
- **T-199**: VM — `score`/`finalScore` published, `scoreGain(for:)`(이동+스파이더 완성 ×100), `scoreHistory`/`redoScoreHistory` 스택으로 undo/redo 롤백, newGame 초기화, checkState 승리 시 finalScore+GameRecord.score 저장. `RecordStore.GameRecord.score: Int?` 추가(기존 데이터 호환).
- **T-200**: gameInfoView "점수 N", WinBanner "최종 점수 N점"(ContentView), StatsView 최근 승리 목록에 점수.

### 2. 플랫폼
- macos (SwiftUI + GameCore)

### 3. 빌드/테스트 결과
- `swift build` 경고 0건, 단위 테스트 **214개 통과** = 207 + Scoring 7.

### 4. 남은 TODO
- v3.18 T-197 / v3.19 T-201: 문서 갱신은 완료, 커밋 대기
- 수동 검증 v3.15~v3.19 일괄 지연 (사용자 지시)

### 5. 다음 에이전트 전달 로그
- 커밋 예정 2건: `feat(macos): v3.18 Scorpion`(이미 커밋 abb81a3) → `feat(macos): v3.19 점수 체계`
- 자동 플레이/자동 완성 이동은 score 미포함 (설계상)

### 6. 문서 업데이트 목록
- PLAN_v3.19, TODO, CHANGELOG([3.19.0]), DESIGN(§3.21)

### 7. 오프라인 큐 상태
- 해당 없음

### 8. E2E/k6
- 해당 없음

## v3.20 Winnable 딜 — FreeCellSolver 코어 (T-202)

### 1. 무엇을 (T-202)
- **FreeCellSolver.swift** 생성 — FreeCell 계열 4종(freecell/bakersGame/seaTower/superFreeCell) 승리 가능 여부 판정. 안전 홈 이동(AutoPlay) 정규화 + 반복 DFS(명시적 스택) + 휴리스틱 이동 순서 + 방문 집합 + 수퍼무브. `isWinnable(gameNumber:variant:budget:)`, `firstWinnableGameNumber(from:variant:)`, `isFreeCellFamily(_:)`.
- **버그 수정**: 깊이 예산 초과 시 기존 `return false`(전체 탐색 즉시 포기) → `continue`(경로만 가지치기, 백트래킹 유지)로 변경. 이전에는 DFS가 한 줄기로만 깊이를 소모하며 #3/#10/#20을 false로 오판했음. 가지치기 수정으로 5/13 → 10/13 딜 true.
- **기본 예산 상향**: nodeLimit 400,000 / timeLimit 4.0s / depthLimit 20,000 (기존 200k/1.5s는 미확정 다발).
- **FreeCellSolverTests.swift** 5개 신규 — 대표 MS 딜 풀림(#4/#5/#10/#20/#100/#1000/#5000/#10000)/예산 내 판정(#2)/예산 0 미확정/미지원 변형/firstWinnableGameNumber.

### 2. 플랫폼
- macos (GameCore 순수 로직 — UI 연동 없음)

### 3. 빌드/테스트 결과
- `swift build` 경고 0건, 단위 테스트 **219개 통과** = 214 + FreeCellSolver 5.
- 디버깅 과정: 딜 생성기/MS RNG 검증(#24 fc-solve 일치), 우선순위 재배치 10여 회(불안정 — 구조 문제임 확인), IDDFS 시도 후 롤백, visited hit 비율·프레임 통계 로깅으로 "노드≈깊이(분기 없음)" 원인 → depth-limit `return false` 버그 발견.
- 알려진 한계: MS 딜 #1/#50/#500은 기본 예산 내 미확정(false). 50만 노드에서도 해를 못 찾음 — 휴리스틱 개선 과제로 남김.

### 4. 남은 TODO
- T-203~T-205(옵션/VM/UI 연동)는 이후 진행 완료
- 후속: #1/#50/#500 해결용 휴리스틱 개선 (빈 열/홈 근접 카드 우선 등)

### 5. 다음 에이전트 전달 로그
- 커밋 완료: `feat(macos): v3.20 Winnable 딜 — FreeCellSolver 승리 가능 판정 (T-202)` (922e42b)
- 솔버 내부 탐색: 반복 DFS는 `stack.count > depthLimit` 시 `continue`(가지치기) — 이 패턴 유지 필수
- 사용자 선택: "여기서 정리 후 커밋" — #1/#50/#500 미확정은 T-203 진행 전 별도 논의
- 에러코드 없음

### 6. 문서 업데이트 목록
- PLAN_v3.20_macos.md (신규), TODO.md (v3.20 섹션), CHANGELOG.md ([3.20.0])

### 7. 오프라인 큐 상태
- 해당 없음

### 8. E2E/k6
- 해당 없음

## v3.20 Winnable 옵션 연동 (T-203~T-205)

### 1. 무엇을 (T-203~T-205)
- **T-203**: `GameVariant.optionDefinitions`에 FreeCell 계열 4종(freecell/bakersGame/seaTower/superFreeCell) `winnable` 옵션("일반"/"승리 보장") 추가. GameOptionTests에 FreeCell 계열 옵션 검증 +1, testOtherVariantsHaveNoOptions 갱신.
- **T-204**: VM — `isWinnableEnabled(for:)` 옵션 읽기, `newGame(number:variant:spiderDifficulty:)`에서 승리 보장이면 `firstWinnableGameNumber(from:variant:budget:maxAttempts:)`(WinnableSearchBudget 100k/1.0s, maxAttempts 50)로 풀리는 번호 탐색. `startNumber`를 실제 시작 번호로 사용(FreeCellGame 생성·gameNumberText·setLastGameNumber 반영).
- **T-205**: GameNumberSheet — 승리 보장 선택 시 "풀리지 않는 번호는 다음 풀리는 번호로 시작됩니다" 안내 문구.

### 2. 플랫폼
- macos (GameCore + FreeCellViewModel + GameNumberSheet)

### 3. 빌드/테스트 결과
- `swift build` 경고 0건, 단위 테스트 **220개 통과** = 219 + GameOption +1.
- T-204/205는 executable target(PureSolitaire)이라 단위 테스트 범위 밖 — 빌드로만 검증, 수동 검증 v3.15~v3.20 일괄 지연.

### 4. 남은 TODO
- T-205 문서·커밋 완료, v3.20 전체 완료.
- 후속: MS 딜 #1/#50/#500 미확정 → 휴리스틱 개선 (빈 열/홈 근접 카드 우선 등) 별도 논의 예정.
- 수동 검증: v3.15~v3.20 일괄 지연 (사용자 지시).

### 5. 다음 에이전트 전달 로그
- 커밋 완료: `feat(macos): v3.20 Winnable 옵션 연동 — winnable 토글, VM 번호 탐색, 시트 안내 (T-203~T-205)` (3702d30)
- VM winnable 탐색은 동기 호출 — 새 게임 시작 시 1초(WinnableSearchBudget)까지 지연 가능. 만족스럽지 않으면 비동기 전환 검토.
- 에러코드 없음.

### 6. 문서 업데이트 목록
- PLAN_v3.20 (T-203~205 체크), TODO.md (v3.20 섹션 갱신), CHANGELOG.md ([3.20.0] 연동 항목)

### 7. 오프라인 큐 상태
- 해당 없음

### 8. E2E/k6
- 해당 없음

## v3.20 솔버 휴리스틱 개선 — #1/#2 해결 (T-202 후속)

### 1. 무엇을
- **휴리스틱 개선** (`FreeCellSolver.priority`): 이동 우선순위를 연속 점수로 세분화 — 홈 0 → 프리셀→열 10 → 빈 열 K 20 → **홈 카드 드러내기 30+랭크(빈 열이 있을 때만, 드러난 카드가 홈으로 갈 수 있는 이동)** 31..43 → 그룹 2+ 50 → 빈 열 비-K 60 → 단일(빈 열 있을 때) 70 → 열→프리셀 80 → 단일(빈 열 없음) 90 → 홈 꺼내기 99.
- 핵심 통찰: 드러내기 우선을 **무조건** 적용하면 #1은 풀리지만 #2가 회귀(우선순위 tie로 탐색 순서가 뒤흔들림). **빈 열이 있을 때만 드러내기를 우선**하면 #1과 #2를 동시에 해결 — 10/13 → **11/13 true** (기본 예산 400k/4s).
- testWinnableStandardDeals에 #1/#2 추가, testSolvableWithinBudget을 #1/#2로 확장.

### 2. 플랫폼
- macos (GameCore 순수 로직)

### 3. 빌드/테스트 결과
- `swift test -c release` **220개 통과** (0 실패).
- 딜별 판정(기본 예산): #1 true 0.63s, #2 true 3.34s, #3 true, #4 true, #5 true, #10 true, #20 true, #50 false, #100 true, #500 false, #1000 true, #5000 true, #10000 true.
- #50/#500 진단: **#50은 1.5M/10s에서 true(해 존재, 5M/60s에서 29.2s)** — 기본 예산 초과로 false일 뿐. **#500은 5M/60s에서도 false** — 현 DFS 솔버가 못 찾는 난제.
- 사용자 결정: 기본 예산 유지(400k/4s), #50/#500은 후속 과제(T-206)로 보류.

### 4. 남은 TODO
- [ ] T-206: #50(해 존재 확인)/#500 기본 예산 내 해결 — 보류
- [ ] 수동 검증 v3.15~v3.20 일괄 지연 (사용자 지시)

### 5. 다음 에이전트 전달 로그
- 커밋 예정: `feat(macos): v3.20 솔버 휴리스틱 개선 — #1/#2 해결 (빈 열 조건부 드러내기 우선)`
- 우선순위 tie 탐색 순서 민감 — 우선순위 재배치 시 양 딜(#1/#2) 회귀 테스트 필수.
- 에러코드 없음.

### 6. 문서 업데이트 목록
- TODO.md (T-202 갱신, T-206 추가), CHANGELOG.md ([3.20.0] 휴리스틱 항목)

### 7. 오프라인 큐 상태
- 해당 없음

### 8. E2E/k6
- 해당 없음
- **버그 수정**: 깊이 예산 초과 시 기존 `return false`(전체 탐색 즉시 포기) → `continue`(경로만 가지치기, 백트래킹 유지)로 변경. 이전에는 DFS가 한 줄기로만 깊이를 소모하며 #3/#10/#20을 false로 오판했음. 가지치기 수정으로 5/13 → 10/13 딜 true.
- **기본 예산 상향**: nodeLimit 400,000 / timeLimit 4.0s / depthLimit 20,000 (기존 200k/1.5s는 미확정 다발).
- **FreeCellSolverTests.swift** 5개 신규 — 대표 MS 딜 풀림(#4/#5/#10/#20/#100/#1000/#5000/#10000)/예산 내 판정(#2)/예산 0 미확정/미지원 변형/firstWinnableGameNumber.

### 2. 플랫폼
- macos (GameCore 순수 로직 — UI 연동 없음)

### 3. 빌드/테스트 결과
- `swift build` 경고 0건, 단위 테스트 **219개 통과** = 214 + FreeCellSolver 5.
- 디버깅 과정: 딜 생성기/MS RNG 검증(#24 fc-solve 일치), 우선순위 재배치 10여 회(불안정 — 구조 문제임 확인), IDDFS 시도 후 롤백, visited hit 비율·프레임 통계 로깅으로 "노드≈깊이(분기 없음)" 원인 → depth-limit `return false` 버그 발견.
- 알려진 한계: MS 딜 #1/#50/#500은 기본 예산 내 미확정(false). 50만 노드에서도 해를 못 찾음 — 휴리스틱 개선 과제로 남김.

### 4. 남은 TODO
- [ ] T-203: GameVariant.optionDefinitions에 `winnable` 옵션 (FreeCell 계열 4종)
- [ ] T-204: VM winnable 연동 — newGame에서 풀리는 번호 탐색 후 시작
- [ ] T-205: 게임 번호 시트 안내 문구 + 회귀(219+신규) + 문서
- 후속: #1/#50/#500 해결용 휴리스틱 개선 (빈 열/홈 근접 카드 우선 등)

### 5. 다음 에이전트 전달 로그
- 커밋 완료: `feat(macos): v3.20 Winnable 딜 — FreeCellSolver 승리 가능 판정 (T-202)` (922e42b)
- 솔버 내부 탐색: 반복 DFS는 `stack.count > depthLimit` 시 `continue`(가지치기) — 이 패턴 유지 필수
- 사용자 선택: "여기서 정리 후 커밋" — #1/#50/#500 미확정은 T-203 진행 전 별도 논의
- 에러코드 없음

### 6. 문서 업데이트 목록
- PLAN_v3.20_macos.md (신규), TODO.md (v3.20 섹션), CHANGELOG.md ([3.20.0])

### 7. 오프라인 큐 상태
- 해당 없음

### 8. E2E/k6
- 해당 없음

## v3.15~v3.17 문서 마무리 + release 검증 (T-183/T-187/T-191)

### 1. 무엇을
- **VERSION 상향**: `scripts/build_and_run.sh`/`gen_info_plist.py`의 고정 버전 3.12.1 → **3.20.0** (그동안 커밋 누락됨 — 설치본도 v3.14.0이었음).
- **release 빌드·설치·실행**: `./scripts/build_and_run.sh release` — 빌드/테스트 220개 통과 + `.app` 번들 구성 + ad-hoc 서명 + `~/Applications` 설치 + `open` 실행.
- **실행 검증**: PID 확인 + System Events AX 덤프 — 창 "Pure Solitaire — TriPeaks 586112" (900×1130), 보드 그룹 a11y 요소 41개 렌더 확인 (이미지 지원 불가 모델 — a11y 텍스트 검증 대체).
- **문서 마무리**: PLAN_v3.15/16/17 T-183/187/191 체크 완료, TODO.md v3.15~3.17 "완료" 전환, CHANGELOG 3.15~3.17 검증 항목에 release 설치·실행 반영.

### 2. 플랫폼
- macos (SwiftUI + GameCore)

### 3. 빌드/테스트 결과
- `./scripts/build_and_run.sh release`: 빌드 성공 + 테스트 220개 통과 + 설치·실행 성공. VERSION 3.20.0 확인.
- 실행: PID 30898, 창 제목 "Pure Solitaire — TriPeaks 586112", 보드 a11y 요소 41개(카드/버튼/텍스트).

### 4. 남은 TODO
- [ ] 수동 플레이 검증 (v3.15~v3.20 일괄, 사용자 지시로 계속 지연 중)
- [ ] T-206: #50(해 존재 확인)/#500 기본 예산 내 해결 — 보류
- [ ] docs/tests/ v3.15~3.19 테스트 가이드는 미작성 (v3.10~3.14만 존재)

### 5. 다음 에이전트 전달 로그
- 커밋 예정: `docs(macos): v3.15~3.17 문서 마무리 + release 설치·실행 검증 (T-183/187/191)`
- build_and_run.sh VERSION이 이제 3.20.0 — 다음 버전 작업 시 함께 상향 필요.
- a11y 검증 osascript: `tell application "System Events"` + `UI elements of window 1` (게임 보드 렌더 확인).
- 에러코드 없음.

### 6. 문서 업데이트 목록
- PLAN_v3.15/16/17 (T 체크), TODO.md (v3.15~3.17 완료), CHANGELOG (3.15~3.17 검증 항목), 세션 로그

### 7. 오프라인 큐 상태
- 해당 없음

### 8. E2E/k6
- 해당 없음
