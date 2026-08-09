# PLAN v3.7 — Pyramid 추가 (macos)

> platform: macos · 버전: 3.7.0 · 작성: 2026-08-06

## 1. 개요
보류 후보 2순위 **Pyramid(피라미드)** 를 열 번째 변형으로 추가한다. 기존 6-way 분기(spider/klondike/yukon/fortyThieves/golf/game)를 7-way로 확장한다.
(Golf → Pyramid → TriPeaks 순으로 후보를 차례대로 진행 — 사용자 지시)

## 2. 결정 사항 (표준 Pyramid 규칙)
- **1덱 52장**, **피라미드 28장**(7줄: 1+2+3+4+5+6+7) + **스톡 24장** (웨이스트 0장 시작)
- **카드 값**: A=1, 2~10=숫자, J=11, Q=12, K=13 (`rank.rawValue`)
- **노출 카드**: 7번째 줄(맨 아래)은 항상 노출, 위 줄 카드는 아래 두 자식이 모두 제거됐을 때만 노출
  - row r, pos p의 자식 = row r+1의 pos p, pos p+1
- **이동 (합 13 제거)**:
  1. 노출 피라미드 2장 합 = 13 → 둘 다 제거 (`.pyramidRemovePair(first:second:)`)
  2. 노출 피라미드 + 웨이스트 맨 위 합 = 13 → 둘 다 제거 (`.pyramidRemoveWastePair(card:)`)
  3. 노출 피라미드 **K 단독(13)** → 제거 (`.pyramidRemoveSingle(card:)`)
  4. 스톡 → 웨이스트 1장 드로 (**재활용 없음**, `drawFromStock` 재사용)
- **승리**: 피라미드 28장 전부 제거 (웨이스트/스톡 잔여 무관)
- **종료**: 스톡 소진 + 노출/웨이스트 조합 합 13 짝 없음 + K 단독 없음
- 자동 플레이: **없음** (제거 기반)
- 새 Move 케이스 3개: `.pyramidRemovePair` / `.pyramidRemoveWastePair` / `.pyramidRemoveSingle`

## 3. 아키텍처
```
GameCore/PyramidGame.swift         (pyramid[Card?] 28슬롯, stock, waste, 노출 판정, canMove/apply/undo/hint)
DealGenerator.pyramidDeal          (앞 28장 피라미드, 뒤 24장 스톡)
Move 3케이스                       (pair / wastePair / single)
GameVariant.pyramid                (통계/기록/최단시간 자동 분리)
GameSaver.savedPyramid             (제네릭 store/load 재사용)
ViewModel @Published pyramid        (init/newGame/이동/탭/힌트/undo/persist/checkState)
GameBoardView 피라미드(7줄) + 스톡/웨이스트(좌) — 홈셀 없음
SideBar 10개 순환 + 게임 번호 시트 allCases 자동
```

## 4. 구현 단계
- [x] T-120: `GameVariant.pyramid` + `DealGenerator.pyramidDeal` + 테스트
- [x] T-121: `Move` 3케이스 + `PyramidGame` (노출 판정/합 13 제거/undo/redo/hint, 종료 판정) + 테스트
- [x] T-122: `GameSaver.savedPyramid` + ViewModel 분기 (init restore/newGame/makeMove/tap/hint/undo/persist/checkState) + `CardSource.pyramid`
- [x] T-123: GameBoardView 분기 (피라미드 7줄 렌더, 스톡/웨이스트, 카드 탭=짝 제거, 드래그)
- [x] T-124: SideBar 10개 순환 + 게임 번호 시트 + 회귀(신규 테스트) + release 검증 + 문서

## 5. 테스트 계획 (실행 결과 — 151개 전부 통과)
- [x] TC-120-1: 딜 레이아웃 (피라미드 28장, 스톡 24장, 총 52장 무중복, 결정성)
- [x] TC-121-1: 노출 판정 (7번째 줄 노출, 위 카드는 자식 2장 제거 후 노출)
- [x] TC-121-2: 합 13 짝 제거 (피라미드 2장 / 피라미드+웨이스트), K 단독 제거, 그 외 거부
- [x] TC-121-3: 스톡 드로 → 웨이스트, 재활용 없음
- [x] TC-121-4: 승리 (피라미드 전부 제거), 종료 판정 (스톡 소진+합13 없음 → hasAnyMove false)
- [x] TC-121-5: undo/redo, Codable 왕복

## 6. 롤백 계획
- `git revert` + T-124 이전 커밋으로 복귀. GameSaver는 키 분리라 기존 저장 무손상.

## 7. 성능/영향
- 피라미드 7줄 레이아웃 (colFactor 10.7 — 최대 가로 폭 10.3칸에 맞춤), 카드 수 52장
- ViewModel/View 분기만 추가 — 기존 9개 게임 로직 불변 (회귀 151개 통과 확인, debug·release 경고 0건, release 설치·실행 확인)
