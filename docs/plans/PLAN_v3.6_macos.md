# PLAN v3.6 — Golf 추가 (macos)

> platform: macos · 버전: 3.6.0 · 작성: 2026-08-06

## 1. 개요
보류 후보 1순위 **Golf(골프)** 를 아홉 번째 변형으로 추가한다. 기존 5-way 분기(spider/klondike/yukon/fortyThieves/game)를 6-way로 확장한다.
(Golf → Pyramid → TriPeaks 순으로 후보를 차례대로 진행 — 사용자 지시)

## 2. 결정 사항 (표준 Golf 규칙)
- **1덱 52장**, **7열×5장**(전부 앞면, 35장) + **스톡 16장** + **웨이스트 1장**(딜 시작 시)
- 스톡 클릭 → 웨이스트로 1장 드로 (**재활용 없음**, 스톡 소진 시 종료 판정에 포함)
- **이동**: 웨이스트 맨 위 카드와 **1 차이 또는 같은 랭크**인 **열 맨 아래 카드**를 웨이스트로 제거 (수트 무관)
  - **순환 인접**: `K(13) ↔ A(1)` 인접 (A-2-...-K-A 순환)
- 열 간 이동 없음, **빈 열 재사용 없음**
- **승리**: 7열 모두 비어있음 (웨이스트/스톡 잔여는 무관)
- **종료**: 스톡 소진 + 제거 가능한 열 카드 없음 → "이동 가능한 수가 없습니다."
- 자동 플레이: **없음** (제거 기반 게임이라 AutoPlay 홈 이동 개념 부적합)
- 새 Move 케이스 **`.columnToWaste(columnIndex:card:)`** 1개 추가 (열→웨이스트 제거). `drawFromStock`은 스톡→웨이스트 재사용

## 3. 아키텍처
```
GameCore/GolfGame.swift          (columns/stock/waste, canMove/apply/undo/hint, 종료 판정)
DealGenerator.golfDeal           (7열×5장 + 스톡 16 + 웨이스트 1)
Move.columnToWaste               (열 맨 아래 카드 → 웨이스트 제거)
GameVariant.golf                 (통계/기록/최단시간 자동 분리)
GameSaver.savedGolf              (제네릭 store/load 재사용)
ViewModel @Published golf         (init/newGame/이동/탭/힌트/undo/persist/checkState)
GameBoardView 7열 + 스톡/웨이스트(좌) — 홈셀 없음
SideBar 9개 순환 + 게임 번호 시트 allCases 자동
```

## 4. 구현 단계
- [x] T-110: `GameVariant.golf` + `DealGenerator.golfDeal` + 테스트
- [x] T-111: `Move.columnToWaste` + `GolfGame` (canMove/apply/undo/redo/hint, 종료 판정) + 테스트
- [x] T-112: `GameSaver.savedGolf` + ViewModel 분기 (init restore/newGame/makeMove/tap/hint/undo/persist/checkState)
- [x] T-113: GameBoardView 분기 (7열 렌더, 스톡/웨이스트, 열 탭=웨이스트 제거, 드래그/드롭)
- [x] T-114: SideBar 9개 순환 + 게임 번호 시트 + 회귀(신규 테스트) + release 검증 + 문서

## 5. 테스트 계획 (실행 결과 — 129개 전부 통과)
- [x] TC-110-1: 딜 레이아웃 (7열×5장=35, 스톡 16, 웨이스트 1, 총 52장 무중복, 결정성)
- [x] TC-111-1: 웨이스트 1 차이/같은 랭크만 열→웨이스트 허용 (K-A 순환 포함, 그 외 거부)
- [x] TC-111-2: 스톡 드로 → 웨이스트, 재활용 없음 (스톡 소진 시 드로 불가)
- [x] TC-111-3: 승리 (7열 모두 비어있음)
- [x] TC-111-4: 종료 판정 (스톡 소진 + 제거 불가 → hasAnyMove false)
- [x] TC-111-5: undo/redo, Codable 왕복

## 6. 롤백 계획
- `git revert` + T-114 이전 커밋으로 복귀. GameSaver는 키 분리라 기존 저장 무손상.

## 7. 성능/영향
- 7열 colFactor 7.7 재사용, 카드 수 52장 (Klondike/Yukon과 동일 규모)
- ViewModel/View 분기만 추가 — 기존 8개 게임 로직 불변 (회귀 129개 통과 확인, debug·release 경고 0건, release 설치·실행 확인)
