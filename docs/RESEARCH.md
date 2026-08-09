# 리서치 — 순수한 솔리테어 (Pure Solitaire) 방향성

> 작성: 2026-08-09 · 목적: 소스/문서 리서치 + 온라인 벤치마크 정리, 차기 기능 제안의 근거 자료

## 1. 프로젝트 현황 (현재 코드/문서 기준)

- **버전**: v3.12.1 (리브랜딩 완료 — Pure Solitaire / 순수한 솔리테어, 번들 `com.borasarang.puresolitaire`)
- **플랫폼**: macOS 네이티브 (SwiftUI), GameCore (플랫폼 독립 로직) + PureSolitaire (앱) 분리
- **테스트**: 171개 단위 테스트 통과, `swift build` 경고 0건, 릴리스 빌드/설치/실행 정상
- **배포**: GitHub README + 랜딩 페이지(index.html) + CI/Release/Pages 워크플로우 + v3.12.1 릴리즈 + Pages 배포

### 1.1 지원 게임 (11개 변형)

| GameVariant | 특징 |
|---|---|
| `freecell` | 표준 프리셀, 프리셀 4개, 교대색, 수퍼무브 |
| `bakersGame` | 프리셀 없음, 같은 수트, 1장씩만 |
| `klondike` | 7열, 스톡/웨이스트, 교대색, 뒤집힘, 홈셀 4 |
| `spider` | 10열, 스톡 5더미, 같은 수트 K→A, 난이도(1/2/4수트) |
| `seaTower` | 10열×5, 프리셀 4, 같은 수트, 빈 열 K만 |
| `superFreeCell` | 2덱 104, 10열, 프리셀 6, 홈셀 수트당 26 |
| `yukon` | 7열, 유곤 이동(그룹), 교대색, 뒤집힌 카드 |
| `fortyThieves` | 2덱 104, 10열×4, 같은 수트 K→A, 홈셀 8 |
| `golf` | 7열×5+스톡16+웨이스트1, 1차이/같은 랭크 제거 |
| `pyramid` | 피라미드 28장+스톡24, 합 13 제거 |
| `triPeaks` | 3피크+스톡21+웨이스트1, 1랭크 차이 제거 |

### 1.2 이미 갖춘 기능
- 결정론적 딜 (Microsoft RNG, 게임 #1/#617/#11982 검증)
- undo/redo (무제한), 자동 저장/복원 (게임별 키), 자동 플레이
- 힌트: 후보 순환(`⌘H`) + 드래그 왕복 2회 애니메이션 + 소스 하이라이트 (노란 테두리)
- 통계: 변형별 승률/승리수, 선택 게임 요약(최단 승리 포함), 기록(변형별 최대 50건), 초기화
- 승리 연출: 카드 펄스 + 배너 + 파티클(ConfettiView) + 승리 사운드 시퀀스
- 오디오: 효과음/BGM 볼륨 개별, 토글
- 시각: 카드 스타일 2(클래식/심플), 배경 4(그린/블루/다크/화이트), 뒷면 3(클래식/블루/골드), 배경-텍스트 대비(feltTextBase)
- 보드 줌(슬라이더 + ⌘+/⌘-), 창 크기 기억
- 게임 번호 시트: 11종 미니 보드 그리드 + 옵션(Spider 난이도) 자동 렌더, "게임 시작" 버튼
- 사이드바: 상단/하단 그룹 정렬, 게임 전환, 자동 플레이 상태 표시
- 접근성: VoiceOver 라벨 일부(카드 값/보드 그룹/드래그 오버레이 hidden) — 실제 동작은 보류

### 1.3 미완료/보류 항목 (TODO 기준)
- [ ] **T-058**: Klondike 회귀 검증 — 빌드/설치 완료, 수동 검증 대기
- [ ] **T-068**: Spider 회귀 검증 — 72개 테스트 통과, 수동 검증 대기
- 보류: VoiceOver 실제 동작 확인

## 2. 온라인 벤치마크 (2026-08-09 수집)

### 2.1 Microsoft Solitaire Collection
- 5종 모드(Klondike/Spider/FreeCell/Pyramid/TriPeaks) + **데일리 챌린지** 매일 1~5개, **스타클럽**, **이벤트** (5~30개 챌린지)
- 월말 완료 시 배지/업적 76개, XP/레벨/트로피
- 테마(클래식~아쿠아리움) + **사진 커스텀 테마**, 클라우드 동기화(계정)
- 무료+광고/구독 모델 (순수성은 우리 강점)

### 1.2 MobilityWare
- **데일리 챌린지(크라운/트로피, 월별 테마 캘린더)**, 리더보드, 레벨/타이틀
- **"Show Me How To Win"** — 어려운 딜 풀이 시연
- **통계 최상급**: 승률, 현재/최고 연승, 평균/최단 시간, 움직임 수, 완료율 — 변형별
- 표준/베지점 점수, Draw1/Draw3, 무제한 undo/hint, **Auto Complete**, 커스텀 카드/배경

### 2.3 Brainium
- 데일리 게임 + 업적, 통계(승률/연승/최고시간/변형별)
- **커스텀 배경(사진 업로드)**, 다크모드, 좌/우손잡이, 자동 완성, 무제한 hint/undo
- "True Random" (결정론적 딜 강점과 대조적 — 시드 기반에 대한 반감 존재)

### 2.4 기타
| 앱/플랫폼 | 주요 특이점 |
|---|---|
| Solitaire Plus! (Mac) | 30변형, **스마트 드래그/원클릭/오토플레이**, 카드 간격 조절 — 마우스 UX 강점 |
| Solitaire Master | 120+ 변형, 원/더블탭+드래그, 전체 힌트 표시, 즐겨찾기/난이도 필터, 제스처 |
| Solitaired | 500+ 변형, **AI 힌트**, Winnable 딜 옵션, 수집 덱, 온라인 전체/오프 5종 |
| Solitaire Forever II (Steam) | 데일리·업적·리더보드, 클라우드 저장, 갈이/폴-오토플레이, 프로모드 |

## 3. 공통 기능 트렌드 (우선 채택 후보)

1. **데일리 챌린지/캘린더 + 보상(배지/트로피/업적)** — 재방문 동기
2. **"Winnable" 딜 / 난이도 조절** — 승리 보장 딜(선택 가능), MS·Solitaired 다수 채택
3. **자동 완성(Auto-finish)** — 승리 감지 후 잔여를 홈셀/완성으로 자동 정리
4. **통계 고도화** — 연승(현재/최고), 평균/최단 시간, 평균 이동 (MobilityWare 수준)
5. **커스텀 배경/카드면** — 사진 업로드, 배경/카드 스타일 다변화
6. **스마트/전체 힌트** — 유효 이동 전체 강조, 최적 조작 (난이도별)
7. **점수 체계** — 베가스/표준 점수, 콤보 보너스

## 4. 정합성 검토 (프로젝트 원칙 vs 후보)

- 무광고/무마이크로페이먼트/오프라인 우선 — 광고/구독/리더보드 제외 방향
- 결정론적 딜(MS RNG #1/#617 검증) 유지 — "진실된 딜" 정체성 유지, 단 *Winnable 딜*은 시드 기반이라 **선택 옵션**으로만 추가 권장
- 네이티브 macOS + GameCore 순수 로직 — 신규 변형 추가 시 기존 파이프라인(DealGenerator→Game→Saver→ViewModel→View) 재사용

## 5. 제안된 방향 (별도 질문으로 선택 받음, 미확정)

1. **코어 QoL 고도화** — 자동 완성, 연승/최단 시간 통계 확장, 전체 힌트 강조
2. **Winnable + 데일리 딜** — 결정적 RNG로 승리 보장 데일리·선택 난이도 딜
3. **데일리 챌린지 + 업적** — 매일 1개 챌린지 + 별/배지/월달력, 승리 기록 연계
4. **커스텀 배경/카드면** — 사진 업로드 + 카드 스타일/뒷면 확장
5. **추가 변형 1종** — Scorpion/Eight Off/Napoleon 등

> 권장 순서: T-058/T-068 수동 검증 완료 → (사용자 버전 선택) → 코어 QoL → Winnable/데일리 → 챌린지/업적 순

## 6. 참고 자료
- https://www.microsoftcasualgames.com/solitaire
- https://apps.apple.com/us/app/solitaire/id463565130 (Brainium)
- https://apps.apple.com/il/app/solitaire-by-mobilityware/id284791396
- https://apps.apple.com/us/app/solitaire-plus/id412975468 (GamesForOne, Mac)
- https://solitaired.com/guides/app-guide
- https://play.google.com/store/apps/details?id=org.rrl.solitaire.master.pro
- https://soliatre.us/blog/downloads/solitaire-apps-with-statistics