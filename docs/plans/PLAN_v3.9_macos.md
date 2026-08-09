# PLAN v3.9 — 랜덤 게임 전환 + 유동적 게임번호/통계/설정 (macos)

> platform: macos · 버전: 3.9.0 · 작성: 2026-08-06

## 1. 개요
게임 전환을 **하드코딩 순환(11개 switch)** 에서 **랜덤**으로 바꾸고, 게임번호/통계/설정이 **게임이 늘어나도 자동으로 확장**되도록 구조를 재작성한다.
사용자 지시: "게임 전환은 랜덤으로", "통계도 게임에 맞추어 재작성", "앞으로 추가될 게임에 따라 게임번호·통계·설정이 유동적으로".

## 2. 결정 사항
1. **랜덤 게임 전환**: `GameVariant.allCases`에서 **현재 게임 제외** 후 랜덤 선택 (사용자 확인). 진행 중 게임이면 기존 `requestNewGame(variant:)` 확인 다이얼로그 재사용.
2. **선언적 변형 옵션 모델**: GameCore에 `GameOption`/`GameOptionChoice` + `GameVariant.optionDefinitions` 신설. 현재 유일 옵션 = Spider 난이도(1/2/4수트). 앞으로 게임 추가 시 `optionDefinitions`에 옵션만 추가하면 게임번호 시트/설정에 자동 반영.
3. **GameOptionsStore** (UserDefaults, 키 `gameOptions.{variant}.{optionID}`): 옵션 선택값 영구 저장. `spiderDifficulty`를 `@Published`에서 스토어 기반 computed로 이전 (단일 진실 소스).
4. **통계 뷰 재작성**: `.segmented` 12세그먼트 → **스크롤 List**. 상단 전체 요약 고정 + `GameVariant.allCases` 게임별 요약 행, 선택 시 상세(최단 승리 + 최근 승리 10건) 펼침. 기본 선택 = 현재 게임. (사용자 확인 — 스크롤 List 방식)
5. `StatsStore`는 이미 변형별 키 + `resetAll`이 `allCases` 순회 — 유지 (자동 확장).
6. 게임 번호 시트 설명 문구 일반화 ("선택한 게임 번호로 결정적 배치 시작").

## 3. 아키텍처
```
GameCore/GameOption.swift (신규)   GameOption(key/title/choices) + GameOptionChoice(id/title)
GameCore/GameVariant.swift         optionDefinitions (Spider: 난이도)
PureFreeCell/Persistence/GameOptionsStore.swift (신규)  UserDefaults 저장
ViewModel                           switchToRandomGame() / spiderDifficulty 스토어 기반 / winRecords(for:)
SideBarView                         게임 전환 → vm.switchToRandomGame()
GameNumberSheet                     selectedVariant.optionDefinitions 순회 자동 렌더링
SettingsView                        "게임별 옵션" 섹션 (옵션 있는 게임만 자동 표시)
StatsView                           스크롤 List 재작성
```

## 4. 구현 단계
- [x] T-140: GameCore `GameOption`/`GameOptionChoice` + `GameVariant.optionDefinitions` + 테스트
- [x] T-141: `GameOptionsStore` 신설 + ViewModel `spiderDifficulty` 스토어 이전 + `switchToRandomGame` + `winRecords(for:)`
- [x] T-142: SideBarView 게임 전환 → 랜덤 + GameNumberSheet 옵션 자동 렌더링/문구 일반화
- [x] T-143: SettingsView "게임별 옵션" 섹션 + StatsView 스크롤 List 재작성
- [x] T-144: 회귀(신규 테스트) + `swift build`(경고 0) + release 설치·재시작 실행(VERSION 3.9.0) + 문서

## 5. 테스트 계획 (실행 결과 — 171개 전부 통과)
- [x] TC-140-1: `GameVariant.optionDefinitions` — spider에 난이도 3개(초급/중급/고급, id "1"/"2"/"4"), 그 외 변형은 빈 배열
- [x] TC-141-1: `switchToRandomGame` — 현재 게임 제외 랜덤 (GameVariant.allCases 기반)
- [x] 회귀: 기존 169개 + 신규 2개 = **171개 전부 통과**

## 6. 롤백 계획
- 랜덤 전환: SideBarView 버튼을 기존 순환 switch로 복구
- 옵션 모델: `spiderDifficulty`를 `@Published`로 되돌리고 GameNumberSheet 특수 케이스 복구
- GameOptionsStore는 별도 키라 기존 UserDefaults 무손상

## 7. 성능/영향
- UI/설정 계층만 변경 — GameCore 게임 로직 불변 (회귀 169개 통과 확인 필요)
- 통계 뷰는 고정 시트(~420×560) + 내부 ScrollView로 게임 수 무관 렌더
