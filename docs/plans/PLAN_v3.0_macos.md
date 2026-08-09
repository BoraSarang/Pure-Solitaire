# PLAN v3.0 — Klondike(솔리테어) 추가 — macOS

> 작성일: 2026-08-06 | platform: macos | 상태: 진행중

## 1. 개요

기존 FreeCell/Baker's에 이어 세 번째 게임 **Klondike**를 추가한다.

- 구조: 열 7개 + **스톡/웨이스트** + **뒤집힌 카드** + 홈셀 4개. 프리셀 없음.
- 규칙: 내림차순 + **교대색**, 빈 열엔 **K만**, 앞면 카드만 이동, 빈 열의 뒤집힌 카드는 탭으로 뒤집기, 스톡에서 카드 드로(웨이스트로).
- 승리: 홈셀 4개에 각 수트 A→K 완성.

## 2. 결정 사항

- **D3.0-1 병렬 추가**: 기존 `FreeCellGame`/`Move`/`GameBoardView`는 건드리지 않는다. `KlondikeGame`을 신규 struct로 추가하고 ViewModel/보드에 variant 분기. 회귀 테스트 48개로 기존 동작 보호.
- **D3.0-2 Move 확장**: `Move.swift`에 Klondike 전용 케이스 추가(기존 7개 유지) — `drawFromStock`, `wasteToColumn`, `wasteToFoundation`, `columnToFoundation`(기존 columnToHome 재사용 가능), `flipColumnCard`.
- **D3.0-3 딜 재사용**: `DealGenerator.shuffledCards(gameNumber:)`(Microsoft RNG)로 52장 셔플 → 열 i에 i+1장(맨 위 앞면), 나머지 24장 스톡.
- **D3.0-4 뒤집힌 카드**: `CardView`의 `showBack`/`cardBack`(v2.4 구현) 재사용. GameBoardView에서 faceUp=false면 뒷면 렌더.
- **D3.0-5 저장**: `GameSaver`에 Klondike 전용 키(`persistence.savedKlondike`) 추가.
- **D3.0-6 통계/기록**: `StatsStore`/`RecordStore`가 이미 `variant.rawValue` 키 기반 → **자동 동작**.
- **D3.0-7 승리/타이머/일시정지/자동저장**: 기존 로직 재사용, variant 분기만 추가.

## 3. 구현 단계

### 1단계: GameCore
- [x] T-050: `KlondikeGame` 구현 (columns[ColumnCard]/stock/waste/foundations + canMove/apply/undo/redo + hint + Codable)
- [x] T-051: `Move`에 Klondike 케이스 추가
- [x] T-052: `GameVariant.klondike` 추가
- [x] T-053: `KlondikeGameTests` 작성 (딜 구성/이동 규칙/스톡 드로/승리/undo/Codable)

### 2단계: ViewModel
- [x] T-054: ViewModel `klondike` 분기 (이동 디스패치, 탭, 드래그, 게임정보)
- [x] T-055: `GameSaver` Klondike 저장/복원

### 3단계: 보드
- [x] T-056: GameBoardView Klondike 레이아웃 (홈셀4 + 게임정보 + 스톡/웨이스트, 7열, 뒤집힌 카드)
- [x] T-057: 드래그/드롭/탭 지오메트리 파라미터화 + 스톡/웨이스트 상호작용

### 4단계: 검증
- [x] T-058: 회귀 테스트 + Klondike 테스트 통과 (59개), release 빌드/설치/실행 완료 — **수동 검증 대기**

## 4. 테스트 계획

- [x] TC-3.0-01: Klondike 딜 — 총 52장, 열 i는 i+1장, 맨 위만 앞면, 스톡 24장
- [x] TC-3.0-02: 교대색 내림차순 이동, 빈 열엔 K만, 뒤집힌 카드 이동 불가
- [x] TC-3.0-03: 스톡 드로 → 웨이스트, 웨이스트→열/홈
- [x] TC-3.0-04: 빈 열 뒤집힌 카드 뒤집기
- [x] TC-3.0-05: 승리 판정 (홈셀 전부 13장)
- [x] TC-3.0-06: undo/redo, Codable 왕복
- [x] TC-3.0-07: 기존 48개 회귀 통과 (전체 59개 통과)

## 5. 롤백 계획

- 병렬 추가 + variant 분기 → Klondike 코드만 제거하면 기존 앱 복귀
- GameSaver 새 키 추가 → 기존 저장 무손상

## 6. 성능 예산

- Klondike 상태 소량, 보드 7열 — 기존과 동일 수준
- undo/redo 스냅샷 1장당 ~52카드 — 기존과 동일
