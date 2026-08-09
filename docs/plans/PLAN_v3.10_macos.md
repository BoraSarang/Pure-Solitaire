# PLAN v3.10 — 게임 형식 선택을 대표 카드 이미지 그리드로 교체 (macos)

> platform: macos · 버전: 3.10.0 · 작성: 2026-08-06

## 1. 개요
게임번호 시트의 "게임 형식" **메뉴 픽커**(GameNumberSheet.swift:21-28)를 **게임을 대표하는 미니 보드 레이아웃 미리보기 카드** 3열×4행 그리드로 교체한다.
사용자 지시: "게임 형식을 구분 하는 곳에 픽커가 아니고 게임을 대표하는 카드 이미지(생성)를 사용하도록 다시 접근해줘" / 확정: 게임번호 시트만, 미니 보드 레이아웃, 3열×4행.

## 2. 결정 사항
1. **범위**: 게임번호 시트의 픽커만 교체. 사이드바 "게임 전환"(랜덤)은 유지.
2. **대표 이미지**: 카드 타일(0.7 비율) 안에 해당 게임의 보드 배치를 축소 렌더. 홈셀/프리셀/스톡/웨이스트/열/피라미드/트리피크 형태 구분.
3. **메타데이터**: `GamePreviewLayout`(뷰측 디스크립터)가 게임 클래스 static 상수 재사용 → 중복 없음, 새 게임 추가 시 자동 확장.
4. **그리드**: `LazyVGrid` 3열 + ScrollView — 게임 수 무관 자동 확장.
5. 선택 상태는 CardView `isSelected`(파랑)와 동일 시맨틱.

## 3. 아키텍처
```
PureFreeCell/Views/GamePreviewCard.swift (신규)  GamePreviewLayout 디스크립터 + GamePreviewCard(미니 보드)
PureFreeCell/Views/GameSelectorView.swift (신규)  3열 LazyVGrid + 선택 바인딩
GameNumberSheet.swift                              Picker → GameSelectorView 교체, 시트 크기 확대
```

## 4. 구현 단계
- [x] T-145: `GamePreviewLayout` + `GamePreviewCard` 신규 (11종 미니 보드 레이아웃 렌더)
- [x] T-146: `GameSelectorView`(3열 그리드) + GameNumberSheet "게임 형식" 픽커 교체
- [x] T-147: 시트 레이아웃/크기/a11y 정리 + 문서(PLAN/TODO/DESIGN/CHANGELOG/테스트 가이드/세션)
- [x] T-148: `swift build`(경고 0) + `swift test` 171개 + release 설치·실행(VERSION 3.10.0)

## 4-1. 검증 결과 (2026-08-06)
- `swift build`(debug·release) 경고 0건, `swift test` **171개** 통과
- release 설치·실행: `~/Applications/Pure FreeCell.app` (PID 92503, VERSION 3.10.0)
- AX 덤프로 시트 구조 검증:
  - 시트(329,280 496×647): 제목 "게임 번호 선택" + 설명 + `AXScrollArea d="게임 선택"`(357,395 440×420)
  - **11개 타일 3열 배치** 확인: FreeCell/Baker's Game/Klondike (행1), Spider/Sea Tower/Super FreeCell (행2), Yukon/Forty Thieves/Golf (행3), Pyramid/TriPeaks (행4)
  - 현재 게임 Super FreeCell 타일에 **파랑 선택 테두리** 렌더 확인 (스크린샷 파랑 클러스터 x662-786 y626-812)
  - FreeCell 타일(430,503) 클릭 → 파랑 테두리가 FreeCell(x369-490 y406-591)로 이동 — **선택 전환 동작 확인**
  - 클릭 후에도 창 제목 "Pure FreeCell — Super FreeCell 414237" 유지 — **타일 클릭은 선택만 변경, 게임 시작 안 함** (의도대로)
  - Super FreeCell/FreeCell은 옵션 없음 → 난이도 라디오 없음 (정상). Spider 선택 시만 옵션 표시
  - 시트 닫기(esc) 정상

## 5. 테스트 계획
- **자동**: `swift test` 171개 유지 (GameCore 불변, 회귀 확인)
- **수동**:
  - 시트 열기 → 11종 카드 미니 보드 렌더 확인 (FreeCell 8열/Spider 10열+스톡 5더미/Pyramid 피라미드/TriPeaks 3피크 구분)
  - 카드 클릭 → 파랑 선택 강조 + 옵션 있는 게임(Spider)만 난이도 표시
  - 번호 입력 → "게임 시작" → 선택 게임/번호로 시작
  - 취소 시 현재 게임 유지, 재열람 시 현재 게임 자동 선택

## 6. 롤백 계획
- `git revert` — GameNumberSheet는 기존 Picker 버전으로 복구, 신규 GamePreviewCard.swift/GameSelectorView.swift 제거
- UserDefaults/통계/저장 데이터 무손상 (표시 계층만 변경)

## 7. 성능/영향
- 표시 계층(Views)만 변경 — GameCore 게임 로직/저장 불변
- 미니 보드 렌더는 정적 Shape/색 조합 (11개 고정) — 성능 예산 영향 없음
