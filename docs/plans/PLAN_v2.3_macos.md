# PLAN v2.3 — 기록/승리연출/BGM/보드줌 — macOS

> 작성일: 2026-08-05 | platform: macos | 상태: **완료 (2026-08-05, 사용자 "다 잘됨")**

## 1. 개요

v2.2 완료 후 다음 4개 작업.

1. **T-036 게임 기록/통계 고도화** — 승리 기록(게임 번호·소요 시간·날짜) 저장, 기록 리스트 표시
2. **T-037 승리 연출 강화** — 홈 쌓기 모션 + 승리 배너 강화(효과)
3. **T-038 배경음악(BGM)** — 설정 토글 + 루프 재생
4. **T-039 보드 줌** — ⌘+/⌘- 스케일 조절 (보드 배율 저장)

## 2. 결정 사항

- **D2.3-1 기록 구조**: `RecordStore`(UserDefaults)에 승리 기록 `[GameRecord]` 변형별 저장. 각 항목: gameNumber, variant, seconds, date. (GameCore의 `RecordStore.swift`, public + max 50)
- **D2.3-2 기록 뷰**: StatsView에 "최근 승리" 섹션(최대 10개) 표시, 변형별 세그먼트 연동.
- **D2.3-3 홈 쌓기 모션**: 카드 홈 도착 시 `lastHomeCard` 0.5초 초록 테두리 펄스 (CardView `isPulsing`).
- **D2.3-4 승리 배너**: 승리 시 중앙 상단 "🎉 승리!" + "게임 N 클리어" 배너, 스케일+페이드인 spring 애니메이션 (`WinBanner`).
- **D2.3-5 BGM**: **코드 생성 WAV로 실제 배경 트랙 제공** — `scripts/gen_bgm.swift`(사인 합성 아르페지오 12초 루프) → `resources/bgm.wav` 번들 내장, `BGMPLayer`(AVAudioPlayer numberOfLoops=-1) 재생, 설정 "배경음악" 토글(기본 꺼짐) + App onAppear.
- **D2.3-6 보드 줌**: `settings.boardScale`(0.7~1.4, 기본 1.0) * GameBoardView 카드 크기. GameCommands ⌘+/⌘- 단축키 + 설정 슬라이더.

## 3. 구현 단계

- [x] T-036: RecordStore + 승리 기록 저장 + 기록 뷰
- [x] T-037: 승리 연출 강화 (배너 + 홈 도착 펄스)
- [x] T-038: BGM (bgm.wav 생성 + 루프 재생 + 설정 토글)
- [x] T-039: 보드 줌 (boardScale + ⌘+/⌘- + 설정 슬라이더)

## 4. 테스트 계획

- [x] TC-2.3-01: RecordStore 승리 기록 저장/조회 (변형별) — RecordStoreTests 2개
- [x] TC-2.3-02: boardScale 범위 클램프 — GameCommands min/max 적용 (빌드 검증)
- [x] **단위 테스트 47개 전체 통과**

## 5. 롤백 계획

- RecordStore/boardScale은 새 키 추가 → 기존 데이터 무손상
- 승리 연출은 UI 변경 → 제거 시 복귀
- BGM: bgm.wav 번들 제거 + 토글 제거 시 무해

## 6. 성능 예산

- boardScale: 카드 크기 곱셈뿐 — 무시 가능. GeometryReader 재계산 발생
- 기록: UserDefaults 소량 — 무시 가능

## 7. 빌드/검증

- [x] swift build 성공, release 설치·실행, bgm.wav 번들 포함 확인
- [x] 사용자 수동 검증 완료 ("다 잘됨")