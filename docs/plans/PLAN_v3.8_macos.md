# PLAN v3.8 — TriPeaks 추가 (macos)

> platform: macos · 버전: 3.8.0 · 작성: 2026-08-06

## 1. 개요
보류 후보 3순위 **TriPeaks(트리피크스)** 를 열한 번째 변형으로 추가한다. 기존 7-way 분기를 8-way로 확장한다.
(Golf → Pyramid → TriPeaks 순으로 후보를 차례대로 진행 — 사용자 지시. v3.8 완료로 보류 후보 3종 전부 완료)

## 2. 결정 사항 (표준 TriPeaks 규칙)
- **1덱 52장**, **3개 피크**(각 4줄 피라미드: 1+2+3+4 = 10장 × 3 = **30장**) + **웨이스트 1장**(딜 시 오픈) + **스톡 21장**
- **노출 카드**: 각 피크의 마지막 줄(4번째 줄)은 항상 노출, 위 줄 카드는 아래 두 자식이 모두 제거됐을 때만 노출
  - 피크 내 localIndex = rowStart(row) + pos, rowStart = [0,1,3,6]. 자식 = row+1의 pos, pos+1
- **이동**: 노출 카드가 **웨이스트 맨 위와 정확히 1 랭크 차이**(수트 무관, **같은 랭크·K↔A 순환 제외**)면 웨이스트로 제거 (`.triPeaksRemove(card:)`)
  - Golf(`1 차이|같은 랭크|K↔A`)와 달리 **1 차이만** — 표준 TriPeaks 규칙 채택
- 스톡 → 웨이스트 1장 드로 (**재활용 없음**, `drawFromStock` 재사용)
- **승리**: 3개 피크 30장 전부 제거
- **종료**: 스톡 소진 + 노출 카드 모두 웨이스트와 1 차이 아님
- 자동 플레이: **없음** (제거 기반)
- 새 Move 케이스 1개: `.triPeaksRemove(card: Card)`

## 3. 아키텍처
```
GameCore/TriPeaksGame.swift          (peaks[Card?] 30슬롯, stock, waste, 노출 판정, canMove/apply/undo/hint)
DealGenerator.triPeaksDeal           (앞 30장 피크, 그다음 1장 웨이스트, 뒤 21장 스톡)
Move 1케이스                          (.triPeaksRemove)
GameVariant.triPeaks                 (통계/기록/최단시간 자동 분리)
GameSaver.savedTriPeaks              (제네릭 store/load 재사용)
ViewModel @Published triPeaks         (init/newGame/이동/탭/힌트/undo/persist/checkState)
GameBoardView 3피크 + 스톡/웨이스트(좌) — 홈셀 없음
SideBar 11개 순환 + 게임 번호 시트 allCases 자동
```

## 4. 구현 단계
- [x] T-130: `GameVariant.triPeaks` + `DealGenerator.triPeaksDeal` + 테스트
- [x] T-131: `Move.triPeaksRemove` + `TriPeaksGame` (노출 판정/1 차이 제거/undo/redo/hint, 종료 판정) + 테스트
- [x] T-132: `GameSaver.savedTriPeaks` + ViewModel 분기 (init restore/newGame/makeMove/tap/hint/undo/persist/checkState) + `CardSource.triPeaks`
- [x] T-133: GameBoardView 분기 (3피크 렌더, 스톡/웨이스트, 노출 카드 탭=제거, 드래그)
- [x] T-134: SideBar 11개 순환 + 게임 번호 시트 + 회귀(신규 테스트) + release 검증 + 문서

## 5. 테스트 계획 (실행 결과 — 169개 전부 통과)
- [x] TC-130-1: 딜 레이아웃 (피크 30장, 스톡 21장, 웨이스트 1장, 총 52장 무중복, 결정성)
- [x] TC-131-1: 노출 판정 (각 피크 4번째 줄 노출, 위 카드는 자식 2장 제거 후 노출)
- [x] TC-131-2: 웨이스트와 1 차이만 제거 허용 (같은 랭크·2 차이·K↔A 거부)
- [x] TC-131-3: 스톡 드로 → 웨이스트, 재활용 없음
- [x] TC-131-4: 승리 (피크 전부 제거), 종료 판정 (스톡 소진+1 차이 없음 → hasAnyMove false)
- [x] TC-131-5: undo/redo, Codable 왕복

## 6. 롤백 계획
- `git revert` + T-134 이전 커밋으로 복귀. GameSaver는 키 분리라 기존 저장 무손상.

## 7. 성능/영향
- 3피크 가로 배치 (colFactor 19.5 — 최대 가로 폭 18.95칸에 맞춤), 카드 수 52장
- ViewModel/View 분기만 추가 — 기존 10개 게임 로직 불변 (회귀 169개 통과 확인, debug·release 경고 0건, release 설치·실행 확인)
