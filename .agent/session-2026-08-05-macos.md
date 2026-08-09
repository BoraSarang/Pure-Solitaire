# 세션 로그 — 2026-08-05 — [macos]

## 1. 수행 내용
- T-013(T-015): release 빌드로 최종 설치 완료
  - `./scripts/build_and_run.sh release` → 빌드 6.49s, 단위 테스트 28/28 통과, ~/Applications/Pure FreeCell.app 설치 + ad-hoc 서명 + open 실행
  - 창 검증: `Pure FreeCell` 1000×732 @ (400,238), 프로세스 PID 90760
  - UI 접근성 트리: 게임 번호 1 / 이동 0 / 카드 52장 전부 렌더링 / 버튼 3개
  - a11y 덤프 3종 저장: `docs/screenshots/macos/v1.0_board.a11y.txt` + `.storage.json` + `.perf.json`
  - 스크린샷 갱신: `docs/screenshots/macos/v1.0_board.png` (602KB)

## 2. 플랫폼
- macos (SwiftPM CLI, SwiftUI, macOS 26.5.2 arm64, Swift 6.3.3)

## 3. 빌드/성능 결과
- 빌드: release 성공 (turbo 불필요 — 단일 SwiftPM 패키지)
- 테스트: 28/28 통과 (DealGenerator #1/#617/#11982, FreeCellRule 9, FreeCellGame 11, AutoPlay 3)
- PERF: RSS 92.8MB (예산 300MB), CPU 0.1% 유휴 / 7.2% 순간
- CACHE: 해당 없음 (오프라인 단독 로컬 앱, Server/캐시 없음)

## 4. 남은 TODO
- T-016: 수동 플레이 피드백 반영 (사용자 확인 필요)
- T-017: 자동 저장(중간 복구) 검토
- T-018: 접근성(VoiceOver) 개선
- T-019: 두 번째 게임 (v2.0)

## 5. 다음 에이전트 전달 사항
- E-MAC-UI-1001 관련 없음. 실행 중인 앱은 사용자가 확인 가능.
- 사용자 수동 플레이 후 피드백을 받아 T-016으로 반영할 것.
- release 재빌드 시: `./scripts/build_and_run.sh release` (자동으로 이전 앱 종료 후 재설치 필요 시 osascript quit 먼저)

### v1.0.1 수정 (16:16 완료)
- 사용자 피드백: "카드가 아래로 떨어진다" + "카드 이미지 눌림/썰렁"
- GameBoardView.columnView: `Spacer(minLength:0)` 제거 → 상단 정렬 (접근성 덤프로 top y=150 전 열 일치 검증)
- CardView: 중앙 무늬 w*0.62 정비율 + 진짜 중앙(h*0.52), 우측 하단 반전 랭크/무늬 추가, 좌측 상단 랭크 확대
- CardView: 접근성 요소 결합 + 라벨("10 ♥") → VoiceOver 개선, 접근성 덤프 55노드(카드52)로 검증 가능
- 재검증: 빌드 OK, 테스트 28/28, 스크린샷/덤프 갱신

### v1.0.2 수정 (16:35 완료)
- 사용자 피드백: "카드 조금 키우고 가로 줄이자" + "여러 카드 이동 안 됨 / 7이 선택 안 되고 6만 선택"
- **다중 카드 이동 버그**: movableRun(bottom→top)과 canMove의 columns.suffix(top→bottom) 비교 순서 불일치 → cardCount>1 항상 거부. movableRun top→bottom 통일 + run.suffix 비교 + tapCard fromBottom+1 수정
- 회귀 테스트 testMultiCardColumnToColumn 추가 (총 29개 통과)
- 드래그: movableRun 범위 내 카드만 onDrag(조건부 ifApply) 적용
- 창 900×780 defaultSize(가로 축소) + overlapFactor 0.42 → 카드 96×67(85→96 확대)
- 접근성 덤프로 검증: 카드 96px, 상단 정렬(top y=164), 52장 딜 일치

### v1.0.3 수정 (16:45 완료)
- 사용자 피드백: "자동 이동할 수 있는 카드는 자동 이동 (옵션 있으면 좋겠다)" + "좌우 빈 공간에 게임 메뉴 기능을 아이콘으로 나열"
- **자동 이동 게임 중 적용**: FreeCellViewModel.apply()에서 autoPlayEnabled면 runAutoPlay() 호출 (기존엔 게임 시작 시에만). runAutoPlay에서 자동 이동 없어도 checkState 호출하도록 수정. 설정 토글 라벨 명확화
- **SideBarView 신규**: 좌측(새 게임/게임 번호/실행 취소/다시 실행), 우측(힌트/자동 플레이/통계/설정) 그룹별 Divider 구분, 아이콘+라벨+툴팁(단축키), 배경 화이트 대응, undo/redo 비활성 표시. ContentView를 HStack으로 변경
- 접근성 덤프 검증: 사이드바 8버튼 + 창버튼 3, 카드 52장 상단 정렬(y=159, 92px) 유지
- 테스트 29개 통과

### v1.0.4 수정 (17:05 완료)
- 사용자 피드백: 메시지 배너가 카드를 가림 → "메시지 배너 하단으로 이동" 요청 반영
- ContentView ZStack alignment .top → .bottom, padding .bottom 14, transition bottom edge. 빌드/재설치/실행 확인(PID 43130)

### v1.0.5 수정 (17:15 완료)
- 사용자 피드백: "메시지가 없어지지 않네... 3초 뒤에 자동으로 없어지게 해줘" + "가로 사이즈 더 줄이자(카드 2장 폭)" → 이후 "너무 줄였구나 게임 번호가 안 보이네" + "좌우 메뉴 아이콘 크게, 카드 윗부분 줄에 정렬" → 재요청 "그 아래 카드(타블로) 맨 윗줄에 정렬" → "이 상태에서 메뉴 하나 크기만큼 가로 줄여" → "게임 번호 왜 두 줄이냐... 개행 없이 한 줄로"
- **메시지 3초 자동 소멸**: FreeCellViewModel에 `showMessage()`/`dismissMessage()` + `dismissTask`(Task.sleep 3초) 추가. message 직접 할당 지점(승리/패배/자동 플레이/힌트/게임번호 오류/apply/undo/redo/newGame) 전부 교체
- **창 가로 750→830→786**: 게임 번호가 잘리던 문제 → 830 복원 → 사용자 요청으로 메뉴 1개 폭(44px)만큼 더 축소해 786×780 확정, minWidth 780
- **게임 번호 한 줄 강제**: 숫자 Text가 좁은 폭에서 "967,231" 두 줄(46×48)로 나뉘던 문제 → `.lineLimit(1)` + `.minimumScaleFactor(0.5)` + `.fixedSize(horizontal:true)` → 한 줄(86×24) 검증
- **타이틀바 + 게임번호 중앙 정렬**: (1) `hiddenTitleBar` 제거 + `.navigationTitle`로 창 타이틀바에 "Pure FreeCell — 967231" 표시 (onChange로 게임번호 자동 갱신). (2) 게임번호 좌우 여백 불균형(오른쪽 35px 치우침) → topRow를 ZStack 중앙 오버레이로 변경 + 홈셀/프리셀 간격 6→2 → 게임번호 중심 389 = 보드 중심 391 (2px 오차)로 좌우 대칭 달성
- **게임번호 여백 + 카드 스타일 (사용자 후속 요청)**: "게임번호 좌우 여백이 너무 붙어 답답" → 카드 96×67→90×63 축소 + ZStack 중앙 오버레이로 **여백 ~20px 확보** (게임번호 17pt 한 줄 유지). "클래식/심플 차이가 없다" → 심플 스타일을 밝은 회백색 배경(0.92/0.93/0.90) + 옅은 테두리 + 라운드 폰트로 변경해 클래식(흰색+진한 테두리+세리프)과 뚜렷이 구분

### v1.0.6 수정 (17:50 완료) — T-016
- 사용자 요청: "마우스를 클릭 하고 드래그 할때 카드가 따라 다녔으면"
- **`.onDrag` → `.draggable` 전환**: macOS에서 onDrag가 드래그 프리뷰를 제대로 안 보여주던 문제 → `DragPayload`(이미 Transferable/Codable)를 `.draggable(payload) { preview }`로 사용. 커스텀 프리뷰 `dragPreview(cards:cardSize:)`로 드래그 중인 카드 시퀀스를 실제 카드 모양(세로 오버랩)으로 렌더링해 커서가 따라다님
- 타블로(다중 카드 `cards.suffix(cardCount)`) + 프리셀(단일 카드) 모두 적용, movableRun 내 카드만 draggable 유지, tapCard 선택/드롭 로직 기존 유지. 불필요해진 `dragProvider`(NSItemProvider) 제거
- 검증: 빌드 OK + 테스트 통과(swift test), 카드 52장/사이드바 8버튼 정상. 실제 드래그 프리뷰 동작은 사용자 화면 확인 필요
- **사이드바 아이콘 확대 + 타블로 최상단 정렬**: 아이콘 36→44pt, 라벨 9→11pt, ContentView frame alignment center→top, SideBarView padding.top 13→132. a11y 검증: 좌우 버튼 y=164 = 타블로 첫 카드 "10 ♣"와 정확히 일치(최종), 버튼 44×62, 카드 52장 96×67
- 카드 52장 + 사이드바 8버튼 검증, 스크린샷 v1.0.5_board.png + v1.0.5_board.a11y.txt 갱신

### v1.0.6-2 수정 (18:00 완료) — T-016 커스텀 드래그 오버레이로 전면 교체
- 사용자 피드백: **"마우스 포인트를 카드가 따라가지 않고, 선택하면 포인터로 카드가 오며, 놓으면 카드가 아래로 사라진다"** — `.draggable` 커스텀 프리뷰가 SwiftUI 기본 드래그 프리뷰와 충돌해 커서 미추종/아래 미끄러짐
- **커스텀 드래그 오버레이로 교체** (GameBoardView 전면 재작성):
  1. `@State drag: DragState?` — source/cardCount/location
  2. `DragGesture(minimumDistance:2, coordinateSpace:.named("board"))`로 마우스 위치 직접 추적
  3. 드래그 중 이동 카드 시퀀스를 ZStack 최상단 오버레이(`zIndex(100)`)에 `position(x: drag.location.x, y: drag.location.y + 카드높이×0.45)`로 배치 → **커서 정확 추종**
  4. `onEnded`에서 `dropTarget(at:boardSize:cardSize:)`로 목적지 판정: y<columnsStartY면 홈셀(좌)/프리셀(우), 아니면 열 인덱스(x-14)/간격 → `vm.move(cardAt:cardCount:to:)`
  5. `.draggable`/`DragPayload`/`dragPreview`/`UTType.json` import 제거, 탭/더블클릭 로직 유지
- 검증: 빌드 성공 + **29개 테스트 전부 통과**, 앱 설치·실행(PID 84337). 접근성 트리 덤프는 이번 환경에서 TCC 접근성 권한 없어 트리가 비어 보임(Finder도 동일) — 실제 드래그 추종/드롭 판정은 사용자 화면 확인 필요

## 6. 문서 업데이트 목록
- docs/TODO.md (T-001~T-015 완료 체크)
- docs/CHANGELOG.md 신규 생성 (v1.0.0~v1.0.5 기록)
- docs/screenshots/macos/ 3종 덤프 + PNG 갱신
- docs/PLAN.md / DESIGN.md / PRD.md는 v1.0 상태 유지

## 7. 오프라인 큐 상태
- 해당 없음 (로컬 단독 앱, Server 연동 없음)

## 8. E2E/k6 결과
- 해당 없음. 대신 단위 테스트 28개 + a11y 트리 검증으로 대체

## 9. v1.0.6-2 후속 수정 (18:00~19:40) — T-016
### 18:00 드래그 좌표 정밀화 (사용자 반복 피드백 수렴)
- "하단에서 카드가 마우스로 오는데" → 오버레이 원점 y 불일치. `DragState`의 시작 위치를 전역 좌표로 + `startCardOrigin` 델타 계산으로 수정
- "드래그 자체가 안 되서" → 카드별 DragGesture가 탭 제스처와 충돌. **보드 전체 단일 DragGesture + `dragSource(at:)` 히트 판정**으로 재작성
- "마우스 근처에 있지도 않아 아주 멀리 위에" → 좌표 공간 불일치. `.global` → 보드 로컬 좌표로 통일 (`boardOrigin = geo.frame(in: .global).origin` 뺄셈)
- "카드 6장 정도 위에 있어" / "7장짜리 열 아래쪽을 잡으면 정확히 6장 위" → **근본 원인 확정**: `dragSource`가 `fromBottom`(아래서부터)을 반환하는데 `cardBoardOrigin`이 위에서부터로 해석 → `dragSource`가 `(source, cardCount, topIndex)`의 **topIndex**를 반환하도록 변경. 사용자 "꿀밤 기대"
- "바로 옆 카드가 잡히고 이동되 / 마우스 포인트에 오른쪽 카드" → 타블로 열이 중앙 정렬(VStack 기본)인데 x=14+col*간격 좌측 기준 계산 → `VStack(alignment:.leading)` 시도(사용자 "왼쪽 정렬 왜? 드래그는 잘 되는데 6에 5를 못 올려놓네") → **중앙 정렬 복원 + `columnsStartX(boardSize:cardSize:)` = 14 + (보드폭-28-열묶음폭)/2 헬퍼**로 해결. 드롭 판정도 카드 **중심**(`startCardOrigin + delta + 오버레이/2`)으로 변경
- 사용자 최종 확인: **"드래그 너무 잘 되. 굿!!!"**
### 19:00 후속 피드백 3건
- "자동 이동이 둘째, 셋째가 안 됨" → `runAutoPlay()`를 while 루프로 **안전 이동 소진까지 반복**
- "더블클릭 홈 이동 안 됨" → macOS `onTapGesture(count:2)`+`(count:1)` 충돌 → **시간 기반(0.35초) `handleTap`**으로 교체 (타블로 맨 아래/프리셀 → 홈)
- "4장 이상 드래그 시 세로로 안 겹치고 떨어져 길어" → 드래그 오버레이 VStack(펼침) → **ZStack + offset(y: i×카드높이×0.42)**로 겹침. "여러 장 못 옮기는 건 오른쪽 칸 여유(수퍼무브) 규칙 때문" → 사용자가 "정상이네" 확인 (버그 아님)
### 19:30 크래시 수정 (PID 30711)
- 증상: 앱 실행 중 종료 크래시. 크래시 리포트 `PureFreeCell-2026-08-05-192430.ips` 분석 → **`FreeCellGame.undo()` line 192**에서 "Can't remove last element from an empty collection" 트랩 (빈 홈셀 removeLast)
- 원인: 이동 기반 역연산이 홈/열 상태를 재계산하다가 일관성 불일치 발생 (homeIndex 재계산 + 홈 상태 상이)
- 해결: **상태 스냅샷 기반 undo/redo로 전면 교체** — `apply` 시 이동 전 전체 상태(columns/freeCells/homes/moveCount)를 내부 `Snapshot`에 저장, undo/redo는 스냅샷 복원만 수행. 크래시 원리 자체 제거. `undoStack`/`redoStack` `[Move]` → `[Snapshot]`(private), 외부 접근은 `canUndo`/`canRedo`
- 재검증: 29개 테스트 통과, release 재설치·실행(PID 31958)
- 문서: docs/CHANGELOG.md v1.0.6-2 항목 기록

## 10. v1.1 자동 저장 (T-017) (19:45~19:56)
- 사용자 선택: 다음 작업 = 자동 저장 (T-017)
- **PLAN_v1.1_macos.md 작성** (문서 우선) → docs/TODO.md T-017 진행중 표시
- 구현:
  1. `Card`/`Suit`/`Rank`/`FreeCellGame`/`Snapshot`에 `Codable` 추가 → 게임 전체 상태 + undo/redo 스택 직렬화 가능
  2. `Persistence/GameSaver.swift` 신규 (save/restore/clear/hasSavedGame, UserDefaults 키 `persistence.savedGame`)
  3. `FreeCellViewModel.init`에서 저장 상태 복원(성공 시 자동 플레이 재실행 없음) / 실패 시 기존 신규 게임
  4. 저장 시점: `apply`/`undo`/`redo`/`newGame`/`runAutoPlay` 직후 `persist()` + 승리 시 `clearSave()`
  5. `PureFreeCellApp` `scenePhase` .background/.inactive에서 안전 저장 (macOS 13 단일 인자 onChange)
- 검증: **30개 테스트 통과** (신규 `testCodableRoundTrip`), release 설치·실행. 구버전(PID 31958) → pkill 후 바이너리 직접 실행으로 새 버전(PID 37474) 실행. `open`이 번들 경로를 못 찾는 문제 있어 바이너리 직접 실행으로 대체
- 사용자 수동 검증 대기: 이동 후 앱 종료 → 재실행 시 상태 이어지기

## 11. v1.1.1 드래그 히트 버그 수정 (20:00~20:05)
- 사용자 피드백: "자동 이동 된 다음에 드래그를 못하는 상황 / 바닥에 있는 빈 카드판이 위에 있을 때 / 클릭은 되는데 드래그가 안 되고 잡히지도 않음"
- **원인**: 자동 이동으로 타블로 카드가 줄어든 후, 열의 **마지막 카드 아래쪽 42%** 영역에서 드래그가 안 잡힘. `dragSource`가 `i = Int((point.y - columnsStartY)/step)`로 카드 간격(카드높이×0.58) 구획만 히트 → 마지막 카드 하단 0.42높이에서 `i >= cards.count` → nil → DragGesture 미시작. 클릭(onTapGesture, 카드 전체 프레임)은 되고 드래그만 실패하는 불일치
- **수정**: 마지막 카드 bottom까지 히트 허용 — `yOffset ≤ lastCardBottom` 가드 + `i = min(Int(yOffset/step), lastIndex)`. fromBottom/movableRun 검증은 기존 유지
- 30개 테스트 통과, release 재설치·실행(PID 37985), 사용자 "정상" 확인
- 자동 저장 복구도 사용자 "잘 되" 확인 → **T-017 완료**

## 12. v1.1.1 드래그 오버레이 개선 (20:00~20:35)
- 사용자 피드백 4연속: "여러 개 드래그 시 겹침이 작아지는/깨지는 현상" → "3개 드래그 하려는데 카드가 작아져서(또는 겹쳐져서) 마우스 아래에 위치" → "여러 개 동시 이동 시 개수에 따라 마우스 아래로" → "마우스 포인트가 카드 목록 위로 올라감"
- **원인 3종 + 수정**:
  1. 오버레이 카드 간격이 보드와 다름: 보드 step(0.58높이) vs 오버레이 0.42높이 → 오버레이 카드들이 더 빽빽하게 겹쳐 보임 → **`offset(y: i × step)`로 보드와 동일하게 보정** + overlayHeight도 step 기반 (finishDrag/dragOverlay 동일)
  2. 드롭 판정이 "카드 원위치+이동량 기준 첫 카드 중심"이라 사용자가 마우스를 놓는 위치와 어긋나 "놓치도 못함" → **드롭 목적지 = 마우스 포인트(`drag.location`)** 기준으로 통일
  3. 오버레이 렌더링이 "첫 카드 중앙 = 마우스"라 여러 장일수록 카드가 아래로만 쌓여 마우스가 목록 위쪽에 남음 → **오버레이 전체 중앙 = 마우스 포인터**(`position = drag.location`)로 변경
- 30개 테스트 통과, release 재설치·실행(PID 42032→42333), 사용자 최종 "어 중앙에 있네 좋아 .. 정상" 확인
- 문서: CHANGELOG v1.1.1 갱신

## 13. v1.2 접근성(T-018) + 열 상단 고정 (20:35~20:45)
- 사용자 선택: 다음 작업 = 접근성 개선 (T-018)
- **PLAN_v1.2_macos.md 작성** → TODO T-018 진행중
- 접근성 구현:
  1. CardView: `accessibilityHintText` 파라미터 + `accessibilityValue`(선택됨) + hint (타블로/프리셀/홈셀별)
  2. GameBoardView: 홈셀/프리셀/열 접근성 컨테이너 그룹(contain+라벨), 게임정보 결합("게임 번호 N, 이동 M"), 드래그 오버레이 `.accessibilityHidden(true)`
  3. SideBarButton: `.accessibilityLabel`(제목) + `.accessibilityHint`(단축키)
  4. macOS에 `accessibilityLiveRegion` 미지원 확인 → 메시지 자동 안내 제외 (PLAN 수정)
- 빌드 에러 수습: `.polite`/`.move` 타입 추론 → AnyTransition 명시, `accessibilityHint(String?)` → `?? ""`, `.frame(width:maxHeight:)` → 분리
- **사용자 피드백**: "빈 카드 덱이 자꾸 중앙으로 이동 / 세로로 겹친 카드가 줄어들수록 중앙 정렬, 무조건 위로 정렬하고 싶다" → `columnView`를 `.frame(width).frame(maxHeight:.infinity, alignment:.top)`로 **열마다 최대 높이 + 상단 정렬 강제**
- 30개 테스트 통과, release 실행(PID 47024). 사용자 확인 대기: 열 상단 정렬 + VoiceOver 라벨/힌트

## 14. v2.0 Baker's Game(T-019~T-025) + 설정 정리 (20:55~21:15)
- 사용자 선택: 두 번째 게임 = **프리셀 변형(게임 번호 선택)** → 추천 승인: **Baker's Game**
- **PLAN_v2.0_macos.md 작성** → TODO T-019~T-025
- 구현:
  1. `GameVariant` enum 신규 (`freecell`/`bakersGame`)
  2. `FreeCellRule`: `canMoveToColumn`/`movableRun`에 variant 파라미터 (bakers: 같은 수트)
  3. `FreeCellGame`: `variant` 필드 + `freeCellCount(for:)` + custom Codable(encode/decodeIfPresent → legacy 저장 무손상, 기본 freecell). columnToColumn에서 bakers는 `cardCount != 1` 거부. homeToColumn/freeCellToColumn도 variant 전달
  4. `FreeCellViewModel`: `variant`/`variantDisplayName` 노출, `newGame(variant:)`, `switchVariant`, freeCell 인덱스 방어
  5. `GameBoardView`: bakers에서 프리셀 행 숨김. `GameNumberSheet`: 게임 형식 세그먼트 추가. `ContentView`: 창 제목 "Pure FreeCell — Baker's Game N"
  6. **BakersGameTests 6개 신규** → **37개 테스트 통과**
- 테스트 작성 오류 수습: "7 위에 8" 은 프리셀 규칙상 내림차순 위반 → "7 위에 6" 으로 수정
- 사용자 확인: "잘 된다.." (같은 딜 번호 + 프리셀 사라짐 + 같은 수트 쌓기 동작)
- **설정 화면 정리(v2.0.1)**: 사용자 "널부러져 있어서 엉망" → `Form`+`Section` 3섹션(카드/보드/게임플레이) 재구성. 세그먼트 피커 + 섹션 아이콘 + 하단 바 닫기. 사용자 "어 좋다"
- release 재설치·실행(PID 62013). 다음 작업 대기

## 15. v2.1 후속 4종(T-026~T-029) (21:15~21:50)
- 사용자 선택: **통계 분리 + 사운드 + 키보드/접근성 + 힌트 고도화** 진행, 변형 프리셀(T-030)은 보류
- **PLAN_v2.1_macos.md 작성**
- T-026 통계: StatsStore 변형별 키(`stats.{variant}.{key}`) + 기존 전체 키 유지, `entry(for:)`, `recordStarted/Win/Loss(variant)`, `lastGameNumber(for:)`. StatsView `Scope` 세그먼트(전체/FreeCell/Baker's), ViewModel `all*`/`stats(for:)` 노출
- T-027 사운드: `SoundPlayer`(NSSound Glass/Tink/Hero 캐시), `Move.isHomeMove`, apply/오토플레이/승리 트리거, `settings.soundEnabled` 토글
- T-028 키보드: GameCommands에 선택 해제(Esc)/선택 카드 홈으로(Space), ViewModel `clearSelection`/`moveSelectionToHome`. 게임정보 a11y 라벨에 게임명
- T-029 힌트: `FreeCellGame.hintCandidates()`(기존 hint 우선순위 → 전체 수집, local hint로 위임), ViewModel `hintCandidates`/`hintIndex`/`highlightedMove` 순환(`⌘H` → "힌트 n/M"), `applyHighlightedHint`(Enter). CardView `isHintSource` 노란 테두리. GameBoardView `isHintSource`(열/프리셀/홈), 이동/취소/새게임 시 해제
- **39개 테스트 통과** (진행중 hintCandidates 유효성/승리 시 빈 배열 추가 — 초기 테스트는 wins 상태에서 columns 비우는 누락으로 1회 실패 후 수정). release 실행(PID 72398). 사용자 확인: "다 좋아 잘 되었어"

## 16. v2.2 애니메이션/시간/확인/사이드바/회귀테스트(T-031~T-035) (21:50~22:15)
- 사용자 선택: **1~5번 모두 진행** → **PLAN_v2.2_macos.md 작성**
- T-031 딜 애니메이션: ViewModel `isDealing` + 0.7s 후 `withAnimation`, GameBoardView columnsRow offset+opacity 애니메이션
- T-032 시간: `gameStartedAt`(새 게임 설정), 승리 시 `recordWinTime` → StatsStore `bestTimeSeconds(for:)`(변형별). StatsStore.Entry에 bestTime 추가. StatsView "최단 승리" 행
- T-033 새 게임 확인: `showingNewGameConfirmation` + `requestNewGame`(기존 `newGame`은 내부용)/`confirmNewGame`/`cancelNewGame`, 승리 시 `showNextGameButton` + "다음 게임" 버튼(ContentView). confirmationDialog 연동
- T-034 사이드바: 게임 그룹에 "게임 전환"(arrow.left.arrow.right) 버튼 → 반대 변형 requestNewGame
- T-035 회귀 테스트: 오토플레이 수렴(5개 딜, 200회 제한) + 홈 연속성/중복 카드, 안전 카드 잔존 검증, Baker's 빈 프리셀 인덱스/빈 열 수퍼무브, 더블클릭 bottom만, 빈 열 경계
  - 수습: `Array(1...home.count)` 빈 홈(1...0 역방향) 크래시 → empty 분기. 딜#1 col0=7장 확인 후 테스트 보정
- **45개 테스트 통과**, release 실행(PID 74512). 사용자 확인 대기

## 17. 앱 아이콘 제작 (22:20~22:45)
- 사용자: "앱 아이콘도 없다 .. 알아서 적당히 멋지게 최고로 만들어 반영, 생성 이미지는 images 폴더에"
- 원인: Info.plist에 `CFBundleIconFile/CFBundleIconName` 키 없음 → Dock에 아이콘 미반영
- `scripts/make_icon.swift` 전면 재작성 → 그린 그라데이션 배경, 광원, 기울어진 카드 3장 스택, 정면 하트 카드(A+중앙하트+빛), "FREE CELL" 배너 (Big Sur+ 스타일)
- 생성 경로: `images/AppIcon-1024.png` 저장. build_and_run.sh가 images/에서 읽도록 수정
- build_and_run.sh Info.plist에 `CFBundleIconFile`/`CFBundleIconName = AppIcon` 추가
- 아이콘 반영: lsregister 재등록 + `killall Dock` 캐시 초기화
- 수습: `let font = NSFont(...)! ?? ...` 크래시 → `??` 단독으로 수정 (1회)
- 사용자 확인: "반영 잘 됬음"

## 18. v2.3(T-036~T-039) 진행 (22:45~)
- 사용자 선택: **기록 + 승리연출 + BGM + 보드줌** 4종 → PLAN_v2.3_macos.md 작성
- **T-036 기록(23:10 완료)**: `Sources/GameCore/RecordStore.swift` 신규(public, max 50, 변형별 키 `records.{variant}`), ViewModel `recordStore`/`winRecords`/승리 시 기록, StatsView "최근 승리" 목록(최대 10개). RecordStoreTests 2개 → **47개 테스트 통과**
- **T-037 승리 연출(23:20 완료)**: ViewModel `lastHomeCard` + `pulseHomeCard(for:)`(apply에서 isHomeMove 시 0.5s 펄스), CardView `isPulsing`(초록 테두리), GameBoardView homeCell 전달, ContentView WinBanner(🎉 승리 + 게임번호) 오버레이 + spring 애니메이션
  - 수습: 승리 배너 인라인 VStack이 타입체크 초과 → `WinBanner` 별도 struct로 분리
- **T-038 BGM(23:35 완료)**: `scripts/gen_bgm.swift`(사인 합성 아르페지오 12초 WAV → `resources/bgm.wav`), `Audio/BGMPLayer.swift`(AVAudioPlayer 루프), SettingsView "배경음악" 토글 → `vm.toggleBGM`, App onAppear에서 재생, build_and_run.sh가 bgm.wav를 Resources로 복사
- **T-039 보드 줌(23:55 완료)**: UserSettings `boardScale`(0.7~1.4), GameBoardView cardSize에 곱, SettingsView "보드 줌" 슬라이더, GameCommands ⌘+/⌘- 단축키(settings 전달)
  - 수습: `onKeyPress`는 macOS 14 전용 → macOS 13 타깃이라 **GameCommands keyboardShortcut으로 대체**
- **47개 테스트 통과**, release 설치·실행, bgm.wav 번들 포함 확인. **사용자 확인 "다 잘됨" → v2.3 완료 확정**

## 19. v2.4(T-041~T-046) 완료 (2026-08-06)
- 사용자 선택: **효과음 볼륨 + 창 기억 + 승리 확장 + 카드 뒷면 + 경과 시간 + 통계 초기화** 6종 → PLAN_v2.4_macos.md 작성
- **T-041 볼륨**: UserSettings `soundVolume`(기본 1.0)/`bgmVolume`(기본 0.5), SoundPlayer `play(..., volume:)`(NSSound.volume), BGMPLayer `start(volume:)/setVolume`, ViewModel `setBGMVolume`, SettingsView 슬라이더 2개(토글 disabled 연동)
- **T-042 창 기억**: `WindowAccessor.swift`(NSViewRepresentable) + ContentView `.background`에서 `setFrameAutosaveName("PureFreeCellMainWindow")` → macOS 자동 저장/복원
- **T-043 승리 확장**: SoundPlayer `playWinSequence`(Hero + 0.15s 후 Tink + 0.30s 후 Glass), `ConfettiView.swift`(TimelineView+Canvas, 60개 파티클: 직사각형/원/별 낙하+흔들림), ContentView 승리 시 배경에 오버레이
- **T-044 카드 뒷면**: UserSettings `CardBack` enum(클래식/블루/골드 tint+accent), CardView `showBack`/`cardBack` + `backView`(다이아몬드 패턴), GameBoardView columnView가 `vm.isDealing`일 때 showBack → **딜 애니메이션 중 뒷면 표시 후 앞면 전환**
- **T-045 경과 시간**: ViewModel `@Published elapsedSeconds`(Timer 1초, 승리 시 정지) + `isPaused`/`togglePause`(재개 시 gameStartedAt=now-elapsed 보정) + `isInProgress`, gameInfoView에 mm:ss + pause/play 버튼
- **T-046 초기화**: StatsStore `resetAll()`(전체+변형별 키), RecordStore `clearAll()`(public), ViewModel `resetStats()`, SettingsView "데이터" 섹션 destructive 버튼 + confirmationDialog
- 수습: computed `elapsedSeconds`와 @Published 이름 충돌 → `activeElapsedSeconds`로 변경
- **48개 테스트 통과**(RecordStore clearAll 신규), release 설치·실행 확인. 사용자 검증 대기

## 20. v3.0(Klondike) 구현 완료 — release 설치, 수동 검증 대기 (2026-08-06)
- 사용자: "다른 게임도 추가" → 아키텍처 분석 제안(Klondike 병렬 추가) → 사용자 "Klondike, 가자" → PLAN_v3.0_macos.md 작성 후 진행
- **T-050 KlondikeGame**: `Sources/GameCore/KlondikeGame.swift` — columns `[[ColumnCard{card,faceUp}]]` 7열(딜: 열 i에 i+1장, 맨 위만 앞면), stock 24, waste, homes 4. `canMove/apply/applyUnchecked`(columnToColumn/columnToHome/wasteToColumn/wasteToFoundation/drawFromStock/flipColumnCard), `flipTopIfNeeded`, undo/redo Snapshot, `movableRun`(앞면+교대색 내림차순), `hintCandidates`(홈→웨이스트→열→뒤집기→드로 우선순위), Codable
- **T-051 Move**: `drawFromStock`/`wasteToColumn(columnIndex:card:)`/`wasteToFoundation(card:)`/`flipColumnCard(columnIndex:card:)` 추가, `isHomeMove`에 wasteToFoundation 포함
- **T-052 GameVariant**: `.klondike` 추가 → FreeCellGame.freeCellCount(0)/FreeCellRule.canMoveToColumn(교대색)/canMove·applyUnchecked 스위치 보강
- **T-053 테스트**: `KlondikeGameTests.swift` 11개 — 딜 구성(52장/열 i+1/맨위 앞면/스톡 24), 교대색, 뒤집힌 카드 이동 불가, 빈 열 K, 스톡 드로, 웨이스트→열/홈, 뒤집기, 승리, undo/redo, Codable. **59개 통과**
- **T-054 ViewModel**: `@Published klondike: KlondikeGame?` 병렬 보유, `variant` computed, `currentGameNumber/MoveCount/IsWon`, init에서 `restoreKlondike()` 우선, newGame variant 분기, `apply`/`applyRaw`/`undo/redo`/`persist/clearSave`/`checkState`/`hint`/`runAutoPlay`(Klondike는 홈 이동만) 분기, `makeKlondikeMove`, 탭/더블클릭(`tapKlondikeStock/Waste/Column/Home`, `doubleClickKlondikeWaste/ToHome`), `isKlondikeSelected`. `CardSource.waste` 추가
- **T-055 GameSaver**: `save(_ klondike:)`/`restoreKlondike()`/`clearKlondike()` + 키 `persistence.savedKlondike`
- **T-056/057 GameBoardView**: `columnCount`/`colFactor`(8.7→7.7) 파라미터화, klondike 상단행(스톡+웨이스트 좌, 홈셀 우), `stockView`(뒷면+빈 슬롯)/`wasteView`/`klondikeHomeCell`, `klondikeColumnView`(faceUp=false→showBack, 뒤집힌 카드 탭=뒤집기), dragSource/dropTarget/cardBoardOrigin/draggedCards에 waste+7열 분기, ContentView/GameNumberSheet `current*`/`variant` 사용, SideBar 게임 전환 3개 순환
- 수습: enum 스위치 non-exhaustive(waste), `ColumnCard.id` 없음→`\.offset`, Card 인자 순서, Destination에 waste 없음(제거), struct mutating → `klondike?.apply()`
- **59개 테스트 통과, release 빌드/설치/실행 완료**. **사용자 수동 검증 대기** (스톡/웨이스트/뒤집힌 카드/자동저장/승리)

## 21. v3.1(Spider) 구현 완료 — release 설치, 수동 검증 대기 (2026-08-06)
- 사용자: "이제 다른 게임 타입 넣어줘 스파이더?" → 난이도 선택 질문 → 사용자 "1/2/4수트 선택 지원" → PLAN_v3.1_macos.md 작성 후 진행
- **T-060 DealGenerator**: `spiderCards(gameNumber:suitCount:)` — 104장(2덱), Microsoft RNG. 1수트=스페이드 8세트, 2수트=스페이드+하트 4세트씩, 4수트=전 수트 2세트씩
- **T-061 Move/GameVariant**: `Move.dealFromStock` 1케이스만 추가(열 이동은 기존 `.columnToColumn` 재사용), `GameVariant.spider` 추가, `SpiderGame.Difficulty` enum(oneSuit=1/twoSuits=2/fourSuits=4, displayName 초급/중급/고급). GameCore 스위치: `FreeCellGame.freeCellCount` spider→0, `FreeCellRule.canMoveToColumn` spider→true(랭크만), canMove/applyUnchecked·`KlondikeGame.canMove`에 dealFromStock false/break
- **T-062 SpiderGame**: `Sources/GameCore/SpiderGame.swift` — columns `[[ColumnCard{card,faceUp}]]` 10열(0~3=6장/4~9=5장, 맨 위만 앞면), stock 50(5더미×10), completedSuits, undo/redo Snapshot. `canPlaceOnColumn`(랭크 previous, 빈 열 허용), `movableRun`(같은 수트 내림차순), `dealFromStock`, `removeCompletedSequences`(13장 K→A 같은 수트 `isCompleteSequenceStart`), `hint()/hintCandidates()`, `isWon = completedSuits == 8`. `columnCount = 10`, `completedSuitsToWin = 8`. StatsStore/RecordStore `variant.rawValue` 키 기반 자동 분리
- **T-063 테스트**: `SpiderGameTests.swift` 13개 — 덱 구성(104장/수트별 개수), 결정성(같은 시드), 딜 레이아웃(열 i장/맨위 앞면/스톡 50), 같은 수트 이동, 다른 수트 불가, 빈 열 허용, 랭크 규칙, 완성 수트 제거, dealFromStock(각 열 1장+스톡 감소), 빈 스톡 거부, 승리, undo/redo, Codable. **72개 통과**(기존 59 + 13)
- **T-064 ViewModel**: `@Published spider: SpiderGame?` + `spiderDifficulty`(기본 .fourSuits), `variant`/`currentGameNumber/MoveCount/IsWon` spider 최우선, init `restoreSpider()` 1순위, `newGame(spiderDifficulty:)`/`newGame(number:variant:spiderDifficulty:)`, `setSpiderDifficulty`(시트 난이도만 변경), `apply/applyRaw`/`undo/redo`/`checkState`(hasAnyMove→패배 메시지)/`persist/clearSave`/`hint`/`runAutoPlay`(Spider moves=[]), `makeSpiderMove`(열→열 전용), `tapSpiderStock`/`tapSpiderColumn`(뒤집힌 카드 무시)/`isSpiderSelected`, `moveDescription` dealFromStock
- **T-065 GameSaver**: `save(_ spider:)`/`restoreSpider()`/`clearSpider()` + 키 `persistence.savedSpider`(난이도 포함)
- **T-066/067 GameBoardView**: `columnCount` spider=10, `colFactor` spider=10.7, `spiderTopRow`(좌 스톡 5더미 `spiderStockPile` 뒤집힘+빈 슬롯 opacity 0.3, 탭=`tapSpiderStock`; 우 `completedSuitsView` 8개 스페이드 아이콘 "완성 N/8"), `spiderColumnView`(faceUp=false→showBack, 탭=`tapSpiderColumn`, `isSpiderSelected`, `isSpiderHintSource`), `handleSpiderCardTap`(더블클릭 없음), dragSource/dropTarget(상단 드래그 소스/드롭 없음)/draggedCards spider 분기, GameNumberSheet 난이도 세그먼트(초급/중급/고급), SideBar 4개 순환(FreeCell→Baker's→Klondike→Spider→FreeCell)
- 수습: app 경로 `Pure Free Cell.app` 오타 → 실제 `Pure FreeCell.app`(FreeCell 붙여쓰기). 경고 2개는 기존 무관 코드(overlayWidth/overlayHeight 미사용, homeStartX)
- **72개 테스트 통과, release 빌드/설치/실행 완료**. **사용자 수동 검증 대기** (난이도 3종 스톡 딜/완성 수트 제거/드래그/자동저장/승리)

## 22. v3.2(Sea Tower + Super FreeCell) 구현 완료 — release 설치, 수동 검증 대기 (2026-08-06)
- 사용자: "Sea Tower와 Super FreeCell을 순서대로 추가" → 규칙 확정(Sea Tower: 1덱 10열×5+프리셀2장 시작/같은 수트/빈 열 K만/수퍼무브=빈 프리셀+1, Super: 2덱 104장/교대색/빈 열 아무카드/프리셀6/홈 수트 고정 26장) → PLAN_v3.2_macos.md 작성
- **T-070 GameVariant/DealGenerator**: `seaTower`/`superFreeCell` + displayName, `seaTowerDeal`(10열 교대 50장+프리셀 2장 반환), `superFreeCellDeal`(2덱 104장 1회 셔플, 첫 4열 11장/다음 6열 10장)
- **T-071 FreeCellRule**: `canMoveToColumn`(seaTower 같은 수트+빈 열 K만, superFreeCell 교대색+빈 열 아무카드), `movableRun`(seaTower/Baker's 같은 수트, superFreeCell/freecell/klondike 교대색)
- **T-072 FreeCellGame**: `columnCount(for:)`(seaTower/super=10), `freeCellCount(for:)`(seaTower=4, super=6), init variant별 딜(seaTower 프리셀 0,1 시작 카드 2장), `isWon`(super 홈 26장), `canMoveToHome`/`homeIndex(for:)`/`suitHomeIndex(for:)`(super 수트 고정+K 위 A 허용), columnToColumn 수퍼무브(seaTower `emptyColumns: 0` 전달)
- **T-073 테스트**: `SeaTowerGameTests` 10개 + `SuperFreeCellGameTests` 9개 — 딜 구성/중복 2장씩/결정성/같은 수트/빈 열 K만/수퍼무브(seaTower 빈 열 무시, super 표준 공식+목적지 빈 열 제외)/홈 수트 고정+K→A/승리/undo/Codable. 테스트 단언 2회 수정(K는 Q 위 못 옴→빈 열, 목적지 빈 열은 용량 미포함)
- **T-074 GameSaver**: `saveSeaTower`/`restoreSeaTower`/`clearSeaTower` + `saveSuperFreeCell`/`restoreSuperFreeCell`/`clearSuperFreeCell`(키 `persistence.savedSeaTower`/`savedSuperFreeCell`, variant 가드)
- **T-075 ViewModel**: init restore 순서 spider→klondike→seaTower→superFreeCell→freecell(구버전 저장 variant 가드로 freecell/bakers만), `persist()`/`clearSave()` variant 분기
- **T-076/077 GameBoardView**: `columnCount`(variant 기반)/`freeCellCount` 파라미터화, `colFactor` 10열 변형 10.7, 상단행 프리셀 렌더 `freeCellCount(for:)`, dragSource/dropTarget/cardBoardOrigin 프리셀 개수 파라미터화, 열 `ForEach id: \.offset`(2덱 중복 카드 대응), SideBar 6개 순환, GameNumberSheet `allCases` 자동
- **91개 테스트 통과, release 빌드/설치/실행 완료**. **사용자 수동 검증 대기** (6개 게임 모두 추가 — 검증은 게임 다 추가한 후 차례대로 예정)

## 23. v3.3(Yukon) 구현 완료 — release 설치, 수동 검증 대기 (2026-08-06)
- 사용자: "새 변형 게임 추가" → 옵션 제시 후 **Yukon(유콘) 확정**, 나머지(Golf/Pyramid/TriPeaks/Forty Thieves)는 보류 TODO 등록 → PLAN_v3.3_macos.md 작성
- 규칙 확정(위키 검증): 7열 1/6/7/8/9/10/11장, 열0=1장 앞면, 열1~6=뒤집힌 5장+앞면 col장, **스톡/웨이스트 없음**, **유콘 이동**=아무 앞면 카드+위 전부 그룹 이동(내부 무순서), 교대색 내림차순, 빈 열 K만, 홈셀 A→K 같은 수트(열→홈만), 노출 뒤집힌 카드 자동 앞면
- **T-080**: `GameVariant.yukon` + `DealGenerator.yukonDeal`(7열 1/6/7/8/9/10/11, `[[ColumnCard]]`, Microsoft RNG 재사용, 결정적)
- **T-081**: `YukonGame` 구현(KlondikeGame과 병렬) — columns/homes/gameNumber/moveCount, undo/redo 스냅샷, `canMove`(columnToColumn/columnToHome), `canPlaceOnColumn`(교대색+빈 열 K만), `movableGroup`(앞면 시작 위 전부), `flipTopIfNeeded`, `hint`(홈 우선+그룹)
- **T-082**: `FreeCellRule`/`FreeCellGame` 스위치 `.yukon`(교대색, freeCellCount 0) + SideBar 7개 순환. `DealGenerator`에서 `superFreeCellDeal` 실수 삭제→복원
- **T-083**: `YukonGameTests` 10개(딜/결정성/유콘 그룹 이동 내부 무순서/뒤집힌 소스 불가/교대색+K만/홈셀/자동 앞면/승리/undo/Codable) — **101개 테스트 전체 통과**
- **T-084/085**: ViewModel yukon 분기(`tapYukonColumn`/`doubleClickYukonToHome`/`isYukonSelected`/`makeYukonMove`/persist) + GameSaver `savedYukon` — `swift build` 통과
- **T-086**: GameBoardView yukon 분기 — `columnCount`=YukonGame.columnCount(7), `colFactor` 7.7, `.animation(value: vm.yukon)`, `yukonTopRow`(홈셀만 우측), `yukonColumnView`(faceUp/faceDown), `isYukonHintSource`, `handleYukonCardTap`, dragSource(앞면 소스만+movableGroup)/dropTarget(홈셀 우측)/draggedCards — `movableGroup` optional unwrap 수정 후 빌드 통과
- **T-087**: SideBar 7개 순환 + GameNumberSheet `allCases` 자동(이전에 완료 확인)
- **T-088**: 101개 테스트 통과, release 빌드/설치/실행 완료(PID 87709). TODO/PLAN_v3.3/CHANGELOG v3.3.0 갱신. **사용자 수동 검증 대기**
- 남은 작업: v3.3 수동 검증(Yukon 규칙 UX 확인) → 보류 후보(Golf/Pyramid/TriPeaks/Forty Thieves) 추후 진행
