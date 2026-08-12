# PLAN v3.17 — 데일리 챌린지 + 업적 (macos)

> platform: macos · 버전: 3.17.0 · 작성: 2026-08-12 · 근거: docs/RESEARCH.md §3.6 / §5 후보 3

## 1. 개요

**데일리 챌린지(1일 1챌린지, 변형 고정) + 업적(배지)** 를 함께 구현한다.

1. **T-188 데일리 챌린지 모델**: 날짜 → 고정 변형 + 시드(v3.16 DailyDeal 재사용). 별점 3점(승리/시간/이동 수). 완료 상태 저장.
2. **T-189 업적 모델**: 승리/게임/연승/변형 완주 등 10개 배지, 통계 데이터 기반 판정 + 잠금 해제 저장.
3. **T-190 VM/UI**: 챌린지 사이드바 진입 + 챌린지 시트(오늘 챌린지/별점/완료 표시), 업적 시트(배지 목록). 승리 시 챌린지 별점 기록 연동.
4. **T-191 회귀 + 테스트 + 빌드 + 문서**.

## 2. 결정 사항

### 2.1 데일리 챌린지 (T-188)
- **변형 고정**: `DailyChallenge.variant(for:)` — 날짜를 `GameVariant.allCases` 순환으로 매핑(요일별 고정 회전). 하루 1개 변형.
- **시드 재사용**: `DailyDeal.gameNumber(for:variant:)` 그대로 — 오늘 날짜 + 챌린지 변형으로 시드 생성. 시작은 기존 `requestNewGame(number:variant:)` 재사용.
- **별점 (3점)**: 
  - 승리 = 1점, 시간 목표 이내 = +1, 이동 수 목표 이내 = +1 (최대 3점).
  - 변형별 기준: `DailyChallenge.timeTarget(for:)` / `moveTarget(for:)` — 변형별 상수 테이블(단순).
- **완료 상태**: `ChallengeStore` (UserDefaults) — 날짜 키(`challenge.completed.{YYYY-MM-DD}`) 저장 값: 별점+기록. 재실행 시 그대로 유지, 날짜 바뀌면 새 챌린지.
- **a11y**: 별점(☆★)은 Text + 라벨("오늘 챌린지 완료, 별 3개"), 잠금 업적은 불투명 처리 + "잠금 해제 조건" 힌트.

### 2.2 업적 (T-189)
- **10개 배지** (`Achievement`): 첫 승리 / 10승 / 50승 / 첫 연승 / 5연승 / 변형 1종 완주(승리) / 변형 5종 완주 / 100게임 / 최단 승리 1분 이내 / 게임 번호 챌린지 3성.
- **판정**: `StatsStore.Entry`/전체 합계 + `ChallengeStore` 데이터 기반 순수 함수 `Achievement.progress(...)` → `isUnlocked`. 저장은 `AchievementStore`(UserDefaults 배열) — 잠금 해제 시 1회 기록 + 메시지.
- **UI**: 업적 시트 — 배지 목록(그리드/행), 잠금 해제는 풀컬러 + 해제 날짜, 미해제는 회색 + 조건 텍스트. 전체 달성 수 표시.

### 2.3 VM/UI (T-190)
- 사이드바: "챌린지"(목표: medal? calendar.badge) 버튼 + "업적"(trophy) 버튼 — 우측 하단 정보 그룹 근처.
- `ChallengeView` 시트: 오늘 변형/시드/별점 3개 목표(승리·시간·이동) 표시 + "챌린지 시작" 버튼(해당 변형+시드로 새 게임). 완료 시 별점 + 기록 표시.
- `AchievementsView` 시트: 배지 그리드.
- 승리 시: `stats.recordWin` 직전/후에 오늘 챌린지 활성 게임이면(`currentGameNumber == 챌린지 시드`) 별점 계산 → 저장 → 챌린지 완료 메시지.
- GameCommands 메뉴: "챌린지"(⌥⌘D) + "업적"(⌥⌘T) 추가(단축키 충돌 회피 — ⌘D/⌘T 사용 중).

## 3. 아키텍처

```
Sources/GameCore/ChallengeStore.swift (DailyChallenge + ChallengeStore + Achievement + AchievementStore 합본)
Sources/PureSolitaire/ViewModels/FreeCellViewModel.swift  챌린지 진입/승리 연동/업적 상태
Sources/PureSolitaire/Views/ChallengeView.swift           챌린지 시트
Sources/PureSolitaire/Views/AchievementsView.swift        업적 시트
Sources/PureSolitaire/Views/SideBarView.swift             버튼 2개
Sources/PureSolitaire/Views/GameCommands.swift            메뉴 2개 (⌥⌘D / ⌥⌘T)
Sources/PureSolitaire/Views/ContentView.swift             시트 프레젠테이션 연결
```

## 4. 구현 단계

- [x] T-188: `DailyChallenge`(변형/시드/별점 기준) + `ChallengeStore`(완료 상태 저장) + 단위 테스트
- [x] T-189: `Achievement` 모델 + 판정 + `AchievementStore` + 단위 테스트
- [x] T-190: VM(`startChallenge`/`recordChallengeIfToday`/업적 상태) + ChallengeView/AchievementsView + 사이드바/메뉴/시트 연결
- [x] T-191: 회귀(183+신규) + swift build(debug·release) 경고 0 + release 설치·실행(VERSION 3.20.0 빌드본 확인) + 문서

## 5. 테스트 계획

- **자동**:
  - `DailyChallenge`: 같은 날짜 같은 변형(결정성), 날짜 변경 시 변형/시드 변경, 별점(승리/시간/이동) 경계값, 목표 기준표 유효.
  - `Achievement`: 각 배지 판정(통계 값 경계), 저장/복원, 해제 중복 방지.
  - `ChallengeStore`: 완료 저장/복원, 날짜별 격리.
  - 기존 183개 전부 통과.
- **수동 (일괄, v3.15~v3.19 마지막에)**: 챌린지 시작→승리 시 별점 연동, 날짜 변경 시 새 챌린지, 업적 잠금 해제 표시.

## 6. 롤백 계획

- `git revert`. 저장 키(챌린지 완료/업적)는 신규 전용 키 — 기존 데이터 무손상. 시트 분리라 제거 시 UI만 원복.

## 7. 성능/영향

- 챌린지/업적 판정은 UserDefaults 조회 수회 — 비용 무시. GameCore 결정론 유지, 기존 저장 스키마 무변경(신규 키만 추가).