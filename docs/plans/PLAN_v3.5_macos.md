# PLAN v3.5 — Forty Thieves 추가 (macos)

> platform: macos · 버전: 3.5.0 · 작성: 2026-08-06

## 1. 개요
Klondike/Spider/Yukon과 병렬로 **Forty Thieves(포트티브스)** 여덟 번째 변형을 추가한다.
기존 4-way 분기(spider/klondike/yukon/game)를 5-way로 확장한다.

## 2. 결정 사항
- **표준 규칙**: 2덱 104장, **10열×4장**(전부 앞면), **스톡 64장**, 탭=1장 드로→웨이스트, **홈셀 8개**(A→K, 같은 수트, 2덱이므로 수트당 2홈)
- 열 규칙: **같은 수트 K→A 내림차순**, **빈 열엔 아무 카드**
- **스톡 재활용 없음** (표준 규칙 — 일회성, 스톡 소진 시 웨이스트/열 이동만 가능)
- 홈셀: 열 맨 위/웨이스트 → 홈 (A는 빈 홈, 그 외 같은 수트+next 홈)
- 자동 플레이: Klondike처럼 홈 이동만 자동 수행
- 기존 Move 케이스(`columnToColumn`/`columnToHome`/`drawFromStock`/`wasteToColumn`/`wasteToFoundation`) 재사용 — **Move 추가 불필요**
- `FortyThievesGame`은 `[[Card]]` 열 사용 (전부 앞면이라 faceUp 불필요)

## 3. 아키텍처
```
GameCore/FortyThievesGame.swift   (columns/stock/waste/homes[8], canMove/apply/undo/hint)
DealGenerator.fortyThievesDeal    (2덱 셔플, 10열×4장 + 스톡 64장)
GameVariant.fortyThieves          (통계/기록/최단시간 자동 분리)
GameSaver.savedFortyThieves       (제네릭 store/load 재사용)
ViewModel @Published fortyThieves (init/newGame/이동/탭/힌트/undo/persist/checkState)
GameBoardView 10열 + 스톡/웨이스트(좌) + 홈셀 8개(우)
SideBar 8개 순환 + 게임 번호 시트 allCases 자동
```

## 4. 구현 단계
- [x] T-100: `GameVariant.fortyThieves` + `DealGenerator.fortyThievesDeal` (2덱 셔플, 10열×4장+스톡64) + 테스트
- [x] T-101: `FortyThievesGame` (canMove/apply/undo/redo/hint — 같은 수트, 홈8, 빈 열 아무 카드) + 테스트
- [x] T-102: `GameSaver.savedFortyThieves` + ViewModel 분기 (init restore/newGame/makeMove/tap/hint/undo/persist/checkState)
- [x] T-103: GameBoardView 분기 (10열 렌더, 스톡/웨이스트, 홈셀 8, 드래그/드롭/탭)
- [x] T-104: SideBar 8개 순환 + 게임 번호 시트 + 회귀(신규 테스트) + release 검증

## 5. 테스트 계획 (실행 결과 — 118개 전부 통과)
- [x] TC-101-1: 딜 레이아웃 (10열×4장=40, 스톡 64, 전부 앞면, 104장 중복 없음)
- [x] TC-101-2: 같은 수트 내림차순만 열 이동 허용, 빈 열엔 아무 카드
- [x] TC-101-3: 스톡 드로→웨이스트, 웨이스트→열/홈
- [x] TC-101-4: 홈셀 A→K 8홈 (2덱 수트 2세트)
- [x] TC-101-5: 승리(홈 8×13), undo/redo, Codable 왕복
- [x] TC-101-6: 스톡 소진 시 드로 불가 (재활용 없음)

> T-101 테스트 중 **모델 버그 발견·수정**: `canMove(.columnToColumn)`가 `moving[0]`(시퀀스 맨 위)로 검증하던 것을 `moving[moving.count - cardCount]`(이동할 그룹의 맨 위)로 수정 — cardCount<시퀀스 길이인 이동이 거부되던 문제.

## 6. 롤백 계획
- `git revert` + T-104 이전 커밋으로 복귀. GameSaver는 키 분리라 기존 저장 무손상.

## 7. 성능/영향
- 10열 colFactor 10.7 재사용, 카드 수 104장 (Super FreeCell과 동일 규모)
- ViewModel/View 분기만 추가 — 기존 4개 게임 로직 불변 (회귀 118개 통과 확인, debug·release 경고 0건, release 설치·실행 확인)
