# PLAN v3.3 — Yukon 추가 (macOS)

> 작성: 2026-08-06 · 상태: 진행중
> 사용자: "새 변형 게임 추가" 선택 → 표준 Yukon 규칙 확정

## 1. 개요

Klondike 패밀리의 변형 **Yukon(유콘)** 을 여섯 번째 변형 게임으로 추가한다.
7열 타블로에 모든 카드(52장)를 배치하고 스톡/웨이스트 없이 플레이하며,
**유콘 이동**(아무 앞면 카드 + 위 전부를 그룹 이동)이 핵심 차별점이다.

기존 변형: FreeCell / Baker's / Klondike / Spider / Sea Tower / Super FreeCell
→ 이번에 Yukon 추가로 **7개 게임**이 된다.

## 2. 규칙 (표준 Yukon — 2026-08-06 검증)

- **딜**: 52장을 7열에 배치 — 열0=1장(앞면), 열1~6=6/7/8/9/10/11장
  - 각 열: 맨 아래 5장은 뒤집힘, 위 5장은 앞면 (열1~6 기준)
  - 정확히: 열0=1장 앞면. 열1~6은 각각 뒤집힌 5장 + 앞면 (열i-1)장
  - 스톡/웨이스트 없음 — 전부 타블로에 있음
- **타블로 조합**: 내림차순 + 교대색 (빨강/검정 번갈아)
- **유콘 이동**: 아무 **앞면 카드**와 그 위에 쌓인 카드 전체를 한 그룹으로 이동
  - 내부 순서/랭크 연속성 무관 — 시작 카드(그룹 맨 아래)만 목적지 규칙 충족
  - 예: 시작 카드가 빨강 7 → 검정 8 위에 놓을 수 있음 (위의 카드들은 아무거나)
- **빈 열**: K 또는 K로 시작하는 그룹만 놓을 수 있음
- **홈셀**: 4개, A→K 같은 수트 (열에서만 이동, 홈셀→타블로 불가)
- **뒤집힌 카드**: 노출되면(위 카드가 모두 이동) **자동으로 앞면** 전환
- **승리**: 홈셀 4개 모두 K까지 완성

## 3. 구현 단계

### 1단계: GameCore
- [x] T-080: `GameVariant.yukon` 추가 + `DealGenerator.yukonDeal(gameNumber:)` — Microsoft RNG, 7열 배치(열0=1장 앞면, 열1~6=뒤집힌 5장+앞면 1~6장), 반환 `[[ColumnCard]]`
- [x] T-081: `YukonGame` 구현 (`Sources/GameCore/YukonGame.swift`) — KlondikeGame과 병렬
  - 상태: `columns: [[ColumnCard{card, faceUp}]]`, `homes: [[Card]]`, `moveCount`, `gameNumber`
  - `columnCount = 7`, `homeCount = 4`
  - `movableGroup(from:topIndex:)` — topIndex부터 위 전부(앞면 시작 카드 포함) 반환
  - `canMove(_:)` 재사용: `.columnToColumn(from,to,cardCount)` / `.columnToHome(columnIndex,card)` / `.flipColumnCard(columnIndex,card)`(유콘은 자동 뒤집기라 별도 탭 불필요 — false)
  - 이동 적용 시 **노출된 뒤집힌 카드 자동 앞면**
  - 유콘 이동 규칙: 시작 카드만 랭크1높음+교대색, 내부 순서 무관
  - `isWon = homes 모두 13장`, undo/redo Snapshot, Codable
- [x] T-082: `FreeCellRule`/`FreeCellGame`/`KlondikeGame`/`SpiderGame`에 `case .yukon` 빈 분기 추가(스위치 컴파일 대응) + `GameSaver` yukon 키
- [x] T-083: `YukonGameTests` 작성 — 딜(7열 구성/앞면·뒤집힘 개수/52장 무중복/결정성), 유콘 이동(내부 무순서 그룹 이동), 교대색+랭크 규칙, 빈 열 K만, 홈셀 A→K, 노출 자동 앞면, 승리/undo/Codable

### 2단계: ViewModel
- [x] T-084: ViewModel — `@Published yukon: YukonGame?` 분기, init restore, `newGame`, 이동 디스패치, 탭(홈셀 이동), 힌트, undo/redo, checkState, persist/clearSave, `variant` 최우선
- [x] T-085: GameSaver `persistence.savedYukon` + save/restore/clear

### 3단계: 보드/UI
- [x] T-086: GameBoardView — `yukon` 분기(7열 faceUp/faceDown 렌더, `colFactor` 7.7, 상단 홈셀 4개, 스톡/웨이스트 없음), 드래그/드롭 `movableGroup`, 탭=홈셀 이동(유콘은 자동 뒤집기)
- [x] T-087: SideBar 7개 순환(FreeCell→Baker's→Klondike→Spider→Sea Tower→Super FreeCell→Yukon→FreeCell) + GameNumberSheet(allCases 자동)
- [x] T-088: 회귀 + 신규 테스트, release 빌드/설치/실행 + 문서 갱신

## 4. 테스트 계획

- [ ] TC-3.3-01: Yukon 딜 — 7열(1/6/7/8/9/10/11), 열0 앞면, 열1~6 뒤집힌 5장+앞면 나머지, 총 52장, 무중복, 결정적 재현
- [ ] TC-3.3-02: 유콘 이동 — 내부 무순서 그룹 이동 허용(시작 카드만 목적지 규칙), 앞면 카드만 소스
- [ ] TC-3.3-03: 타블로 규칙 — 내림차순+교대색, 랭크/색 위반 거부
- [ ] TC-3.3-04: 빈 열 K만 — K 단독 및 K 그룹 허용, 비K 거부
- [ ] TC-3.3-05: 홈셀 — A→K 같은 수트, 열→홈 이동, 홈→타블로 불가
- [ ] TC-3.3-06: 노출 자동 앞면 — 뒤집힌 카드 위 전부 이동 시 앞면 전환
- [ ] TC-3.3-07: 승리/undo/redo/Codable
- [ ] TC-3.3-08: 기존 91개 회귀 무손상

## 5. 롤백 계획

- `YukonGame` 병렬 추가 → 기존 6개 게임 무영향
- git revert + `swift build`/`swift test` + release 재설치
- `persistence.savedYukon` 키 삭제로 자동저장 롤백

## 6. 성능 예산

- 타블로 최대 11장 → maxStackFactor 12 기준 미미, 메모리 소량
- 유콘 이동 O(n) / 힌트 O(n²) 유지 (열 7개) — 미미

## 7. 에러코드

- 신규 에러코드 없음 (규칙 로직만 추가)
