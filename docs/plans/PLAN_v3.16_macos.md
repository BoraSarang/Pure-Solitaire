# PLAN v3.16 — 데일리 딜 (macos)

> platform: macos · 버전: 3.16.0 · 작성: 2026-08-12 · 근거: docs/RESEARCH.md §3.6 / §5 후보 2

## 1. 개요

**데일리 딜(날짜 시드 고정 딜)** 만 구현한다. Winnable 딜은 사용자 결정으로 v3.16에서 제외.

- **T-184 날짜→시드 매핑**: 날짜(YYYY-MM-DD)를 결정적 시드로 변환해 하루 1개 고정 딜. 변형별로 다른 시드. 기존 게임 번호(1~1,000,000) 파이프라인 재사용.
- **T-185 VM 진입점**: `startDailyDeal()` — 오늘 날짜 시드로 현재 변형 게임 시작(진행 중이면 기존 확인 다이얼로그 재사용).
- **T-186 UI/메뉴**: 사이드바 "데일리 딜" 버튼(⌘D) + 게임 메뉴 항목.
- **T-187 회귀 + 테스트 + 빌드 + 문서**.

## 2. 결정 사항

- **시드 매핑**: `GameCore/DailyDeal.swift` 신규 — `DailyDeal.gameNumber(for:variant:) -> Int`.
  - 기준: `Calendar.current.ordinality(of: .day, in: .era)` (날짜 순번, 타임존 일관) + 변형 rawValue 해시 혼합.
  - 변형별 독립: 같은 날짜라도 변형마다 다른 시드 → 변형별 데일리 1개씩.
  - 범위: `1...DealGenerator.maxGameNumber`(1,000,000) 클램프. 같은 날짜+변형은 항상 같은 번호(결정적).
  - GameCore에 두어 순수 로직으로 테스트 가능.
- **진입**: 사이드바 좌측 상단 "게임 번호" 아래 "데일리 딜"(icon: calendar, ⌘D). `vm.startDailyDeal()` → `requestNewGame(number:variant:)` 경유(진행 중 확인 다이얼로그 + 통계 기록/자동플레이/딜 연출 재사용).
- **승리/통계**: 데일리 딜도 일반 게임과 동일하게 시드가 기록되어 통계·게임 번호 표시에 자연 반영. 별도 데일리 저장 상태는 두지 않음(단순).
- **롤백**: 기능 제거 시 `git revert` + DailyDeal 삭제 — 저장 구조 무변경.

## 3. 아키텍처

```
Sources/GameCore/DailyDeal.swift                 날짜→시드 결정적 매핑 (+ 테스트)
Sources/PureSolitaire/ViewModels/FreeCellViewModel.swift  startDailyDeal() 추가
Sources/PureSolitaire/Views/SideBarView.swift    "데일리 딜" 버튼 (⌘D)
Sources/PureSolitaire/Views/GameCommands.swift   게임 메뉴 "데일리 딜" 항목
```

## 4. 구현 단계

- [x] T-184: `DailyDeal.gameNumber(for:variant:)` — 결정적 혼합 + 범위 클램프 + 단위 테스트(같은 날짜 같은 번호 / 다른 날짜 다른 번호 / 변형별 다름 / 범위)
- [x] T-185: `startDailyDeal()` — `requestNewGame(number:variant:)` 경유
- [x] T-186: 사이드바 버튼 + GameCommands 메뉴 (⌘D)
- [x] T-187: 회귀(178+신규) + swift build(debug·release) 경고 0 + release 설치·실행(VERSION 3.20.0 빌드본 확인) + 문서

## 5. 테스트 계획

- **자동**:
  - `DailyDeal` 단위 테스트: 같은 날짜+변형 = 같은 번호, 다른 날짜 = (대부분) 다른 번호, 변형별 서로 다름, 1...1,000,000 범위, 2개 샘플 날짜 고정값 회귀.
  - 기존 178개 전부 통과.
- **수동 (일괄, v3.15~v3.19 마지막에)**: 데일리 딜 시작 → 같은 날짜에 다시 시작해 동일 배치 확인, 변형 전환 후 데일리 딜 다른 배치 확인, 날짜 변경 시 다른 배치 확인.

## 6. 롤백 계획

- `git revert`. DailyDeal 파일 삭제 + 버튼/메뉴 제거. 저장 구조 무변경(시드일 뿐).

## 7. 성능/영향

- 시드 매핑은 초당 수회 호출되는 계산(비용 무시 가능). GameCore 결정론 유지, 저장 스키마 무변경.
