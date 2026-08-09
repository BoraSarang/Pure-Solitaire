# PLAN v3.12 — 통계 선택 요약 / 힌트 드래그 애니메이션 / 자동 플레이 상태 표시 (macos)

> platform: macos · 버전: 3.12.0 · 작성: 2026-08-06

## 1. 개요
사용자 확정 3건을 반영한다.

1. **통계 시트**: 게임 유형 선택 시 상단 요약도 해당 게임 통계로 바뀌어야 한다는 요청.
2. **힌트**: 하이라이트 대신/보조로 실제 드래그 모션(소스→목적지 왕복)을 **2회** 반복하되 **실제 이동 없이** 보여준다.
3. **자동 플레이 버튼**: `autoPlayEnabled` 켜짐/꺼짐 상태를 버튼에 표시하고, 클릭 시 토글한다.

## 2. 결정 사항
1. **통계 (T-152)**: 상단 세그먼트 토글 **"전체 | 선택"** 추가. 기본 `.selected`(시트 열리면 현재 게임이 미리 선택되어 그 통계 표시). 선택 게임 상단 카드에는 최단 승리 시간도 포함. 하단 게임별 행 탭 시 상단 즉시 갱신, 행 아래 상세 펼침은 현행 유지.
2. **힌트 (T-153)**: 드래그 애니메이션 + **하이라이트 유지**(확정). 애니메이션은 소스→목적지→소스 **왕복 2회**, `apply` 호출 없음(보드 불변). 스톡/플립류(`drawFromStock`/`recycleStock`/`dealFromStock`/`flipColumnCard`)는 드래그 개념 부적합 → 하이라이트만 유지.
3. **자동 플레이 (T-154)**: 사이드바 버튼 + 메뉴(⇧⌘A) 모두 토글로 통일. ON으로 켜지면 즉시 `runAutoPlay()` 호출(현재 보드에도 적용). 설정 시트의 "자동 이동" 토글과 `@AppStorage` 자동 동기화.

## 3. 아키텍처
```
Views/StatsView.swift          상단 토글 + 선택 게임 요약 (T-152)
ViewModels/FreeCellViewModel   hintAnimationMove/Tick + hint() 트리거 (T-153)
Views/GameBoardView.swift      HintAnimState + destinationOrigin/hintGeometry + onChange 애니메이션 (T-153)
Views/SideBarView.swift        SideBarButton.isActive + 자동 플레이 토글 (T-154)
Views/GameCommands.swift       "자동 플레이" 메뉴 토글 통일 (T-154)
```

## 4. 구현 단계
- [x] T-152: StatsView 상단 세그먼트("전체|선택") + 선택 게임 요약 카드(최단 승리 포함), 행 탭 시 상단 갱신
- [x] T-153: VM `hintAnimationMove/Tick` + GameBoardView 힌트 왕복 2회 애니메이션 + `destinationOrigin`/`hintGeometry` 매핑, 하이라이트 유지
- [x] T-154: SideBarButton `isActive` + 자동 플레이 버튼 토글/상태 표시, GameCommands 메뉴 토글 통일
- [x] T-155: `swift build`(경고 0) + `swift test` 171개 + release 설치·실행(VERSION 3.12.0) + 문서(PLAN/TODO/DESIGN/CHANGELOG/tests/세션)

## 4-1. 검증 결과 (2026-08-06)
- `swift build`(debug·release) 경고 0건, `swift test` **171개** 통과
- release 설치·실행: `~/Applications/Pure FreeCell.app` (VERSION 3.12.0, PID 80255)
- 수동 검증(PID 80255, AX 덤프 + 실클릭):
  - **T-154 자동 플레이**: 사이드바 버튼(클릭 1121,293) 클릭마다 ON/OFF 토글. ON=강조(파랑 픽셀 6936·`accessibilityValue "켜짐"`·UserDefaults 1), OFF=흐림(픽셀 0·"꺼짐"·UserDefaults 0). 설정 시트 "자동 이동" 스위치와 즉시 동기화 확인.
  - **T-153 힌트**: `⌘H`/힌트 클릭 → 카드 오버레이가 소스→목적지 **왕복 2회** 애니메이션(프레임 캡처로 왕복 확인), 이동 수·게임번호·보드 불변(실제 이동 없음), `Enter`는 실제 적용.
  - **T-152 통계**: 시트 열림 시 기본 **"선택"** 모드로 상단 요약 = 현재 게임(Yukon). "전체" 라디오(562,380) 클릭 → 전체 합계(총 95판/승률 9.5%) 전환, "선택"(627,380) 복귀. 하단 11개 행 탭 시 상단이 해당 게임 요약으로 즉시 갱신, 다시 탭(해제) 시 전체 합계로 폴백.

## 5. 테스트 계획
- **자동**: `swift test` 171개 유지 (표시 계층 + VM 퍼블리시만, GameCore 불변)
- **수동 (AX)**:
  - 통계(`⌘T`): 상단이 현재 게임 통계로 표시, "전체" 토글 시 전체 합계 전환, 다른 행 탭 시 상단 갱신
  - 힌트(`⌘H`): 카드가 소스→목적지 왕복 2회 애니메이션 + 하이라이트 유지 + 보드 상태(이동 수/게임번호) 불변 + Enter 실제 적용
  - 자동 플레이: 버튼 ON(강조)/OFF(흐림) 표시, 클릭 시 토글 + 설정 시트 "자동 이동" 동기화, ⇧⌘A 동일

## 6. 롤백 계획
- `git revert` — StatsView/SideBarView/GameCommands 원복, VM 퍼블리시 속성 제거, GameBoardView 힌트 애니메이션 상태 제거
- 저장 구조 불변(UserDefaults 키 그대로) — 데이터 무손상

## 7. 성능/영향
- 표시 계층(Views) + VM 퍼블리시 속성만 변경 — GameCore/저장 불변
- 힌트 애니메이션은 Task 1개 + 단기 오버레이 — 성능 예산 영향 없음

## 8. 핫픽스 — 드래그 오버레이 위치 어긋남 (2026-08-06, T-163)
### 원인
`dragOverlay`의 카드를 `ZStack(alignment: .topLeading)`에 넣고 `.offset(y: i*step)`으로 쌓았다. SwiftUI의 `offset`은 **레이아웃 크기에 반영되지 않으므로** ZStack 실제 프레임 높이는 카드 1장(`cardHeight+12`)에 불과하다. 그런데 `.position`의 중심 계산은 카드 묶음 전체 높이(`contentHeight+12`)를 기준으로 한다. 이 불일치 때문에 오버레이 첫 카드(잡은 카드)가 실제로 **`(count-1)*step/2`만큼 아래로** 어긋난다.

| 그룹 크기 | 어긋난 거리 |
|---|---|
| 1장 | 0 (정상) |
| 2장 | `step/2` |
| 3장 | `step` ≈ 1장 |
| 5장 | `2*step` ≈ 2장 |

### 결정
1. `ZStack`에 `.frame(width: cardSize.width, height: contentHeight)`을 명시해 offset 카드 묶음 전체가 레이아웃에 포함되게 함 → `.position` 중심 계산이 의도대로 동작.
2. `dx`/`dy`에 `- padding` 보정 → 드래그 시작 시 오버레이 첫 카드가 원래 카드 위치(`startCardOrigin`)와 정확히 겹침(기존 6px 어긋남 제거), 드래그 중 잡은 카드가 마우스 포인트에 정확히 붙음.

### T-163 구현
- [x] T-163: `GameBoardView.dragOverlay` — ZStack `.frame` 고정 + `dx/dy` padding 보정
- [x] T-163-보완: `.frame`에 `alignment: .topLeading` 추가 (기본 center 정렬이 ZStack을 contentHeight 중앙에 배치해 다시 `(count-1)*step/2` 아래로 밀던 문제 해소)
- [x] T-155-재검증: `swift build`(0경고) + `swift test` 171개 + release 설치·실행 + 수동 단일/다중 드래그 재확인

## 9. 핫픽스 — 화면 넘침 시 카드 겹침 자동 조정 (2026-08-06, T-164)
### 요구
카드 묶음이 많아져 열이 화면 아래로 넘칠 때 카드 겹침을 늘려(step 축소) 화면에 맞춘다. 사용자 확정: **최대 70% 겹침** (minStep = cardH*0.30).
### 결정
1. `maxColumnCards()`: 게임별 현재 최대 열 카드 수 (Spider/Klondike/Yukon/FortyThieves/Golf/FreeCell 계열). Pyramid/TriPeaks는 열 개념 없음 → 제외.
2. `effectiveStep(cardSize:boardSize:)`:
   - `baseStep = cardH * 0.58` (기존 overlapFactor 0.42)
   - `fitStep = (보드높이 - 상단행(cardH*1.3+10) - 하단여백 - cardH) / max(1, maxCards-1)`
   - `minStep = cardH * 0.30`
   - `step = max(minStep, min(baseStep, fitStep))`
3. 열 렌더(`overlapOffset = cardH - step`), `dragSource`, `cardBoardOrigin`, `dragOverlay`에 동일 `step` 적용 → 좌표계 일관 유지(드롭 정확도 보존).
### T-164 구현
- [x] T-164: `maxColumnCards()` + `effectiveStep()` 신설, 열 렌더/드래그 좌표계에 동일 step 적용

## 10. 핫픽스 — 힌트 크래시 (Index out of range) (2026-08-06, T-165)
### 원인
`FreeCellViewModel.hint()`(line 1339)의 `candidates[hintIndex]`가 **배열 인덱스 초과**로 크래시(SIGTRAP). `hintIndex`는 힌트 클릭 횟수만큼 증가하지만, 게임 상태 변화(이동 적용/자동 플레이/게임 전환)로 `hintCandidates()` 결과가 줄어들면 인덱스가 범위를 초과했다. `hintIndex`는 게임 전환 시 리셋되지 않았다.
### 결정
1. `hint()` 진입 시 `hintIndex >= candidates.count`면 `hintIndex = 0`으로 클램프 (이동 적용 등으로 candidates가 줄어든 경우에도 안전).
2. `newGame(...)`에서 `hintCandidates = []` + `hintIndex = 0` 리셋 (게임 전환 시 힌트 순환 초기화).
### T-165 구현
- [x] T-165: `hint()` 인덱스 가드 + `newGame` 힌트 상태 리셋 → 힌트 크래시 수정

## 11. 보류 후보 3건 진행 (2026-08-06, T-166~T-168)
### T-166 화이트 배경 가시성
- 원인: `GameBoardView` 게임 정보/완성 수트/스톡 빈 표시 등 **9곳**의 텍스트·아이콘이 하드코딩 `.white` — 화이트 배경 설정 시 안 보임. (ContentView의 `.white` 3곳은 검은 pill 배경 위라 무관)
- 결정: `UserSettings.feltTextBase` computed 추가(배경 == .white면 검정, 그 외 흰색) → 9곳을 `settings.feltTextBase.opacity(기존값)`으로 교체. opacity는 기존 값 유지.
### T-167 SideBar 상단 하드코딩 정렬
- 원인: `SideBarView` `.padding(.top, 132)` 고정 — 창 크기와 무관한 상단 여백, 하단 그룹(이동/정보)이 바닥에 안 붙음.
- 결정: 상단 그룹(게임/도움)+separator / Spacer / 하단 그룹(이동/정보) 구조로 변경. `.padding(.top, 132)` 제거 → 상단 12 여백 + 하단 그룹 바닥 정렬.
### T-168 Golf/Pyramid/TriPeaks 힌트 소스 하이라이트
- 원인: 이 3종은 `hintCandidates()`/드래그 애니메이션(`hintSourceDestination`)은 지원하나 **힌트 소스 하이라이트**(노란 테두리)가 없음 — `isHintSource` 미지정.
- 결정: `isGolfHintSource`/`isPyramidHintSource`/`isTriPeaksHintSource` 추가, 각 카드 뷰에 `isHintSource` 연결 (golf=열 맨 아래 카드, pyramid/triPeaks=노출 카드).
### T-166~168 구현
- [x] T-166: `UserSettings.feltTextBase` + GameBoardView 9곳 교체
- [x] T-167: SideBarView 상/하단 그룹 + Spacer 배치
- [x] T-168: 3종 힌트 소스 하이라이트 함수 + 카드 뷰 연결
