# PLAN v2.4 — 볼륨/창기억/승리연출/카드뒷면/타이머/통계초기화 — macOS

> 작성일: 2026-08-06 | platform: macos | 상태: **완료 (2026-08-06, 빌드/48테스트/설치 확인, 사용자 검증 대기)**

## 1. 개요

v2.3 완료 후 사용자가 선택한 다음 6개 작업.

1. **T-041 효과음/BGM 볼륨 조절** — 설정에 볼륨 슬라이더 (현재 on/off만)
2. **T-042 창 크기·위치 기억** — 종료 시 창 크기/위치 저장, 다음 실행 시 복원
3. **T-043 승리 사운드/효과 확장** — 승리 시 전용 사운드 + 축하 파티클 연출
4. **T-044 카드 뒷면 패턴 선택** — 리버스 디자인 몇 종 중 선택 (딜 애니메이션에서 표시)
5. **T-045 게임 중 경과 시간 표시** — 보드 상단에 현재 진행 시간 실시간 표시 + 중지/재개
6. **T-046 통계/기록 초기화** — 설정에서 통계/승리 기록 초기화 버튼

## 2. 결정 사항

- **D2.4-1 볼륨**: UserSettings에 `soundVolume`(0~1, 기본 1.0), `bgmVolume`(0~1, 기본 0.5). `SoundPlayer.play`가 volume 적용(NSSound.volume), `BGMPLayer`는 `setVolume`/재생 시 반영. 설정 게임플레이 섹션에 슬라이더 2개.
- **D2.4-2 창 기억**: `WindowAccessor`(NSViewRepresentable)로 NSWindow를 얻어 `setFrameAutosaveName("MainWindow")` 호출 → macOS 자동 프레임 저장/복원. (수동 저장 불필요, 위치+크기 복원)
- **D2.4-3 승리 연출**: 사운드는 Hero 1회 + Tink/Glass 짧은 시퀀스로 확장. 파티클은 `ConfettiView`(TimelineView(.animation) + Canvas)로 승리 배너 뒤에 색종이/별 낙하. (emotion 타입체크 주의 — 별도 뷰 분리)
- **D2.4-4 카드 뒷면**: UserSettings에 `CardBack` enum(클래식/심플/스타) + `cardBackRaw`. CardView에 `showBack` 파라미터. **딜 애니메이션(isDealing) 동안 열 카드를 뒷면으로 렌더**, isDealing 종료 시 앞면 전환.
- **D2.4-5 타이머**: ViewModel에 `elapsedTimer`(Timer 1초) + `@Published elapsedSeconds`. newGame 시작, 승리/일시정지 시 정지. `isPaused` 토글(일시정지/재개). gameInfoView에 "시간 mm:ss" + 사이드바 또는 게임정보에 중지/재개 버튼.
- **D2.4-6 초기화**: StatsStore `resetAll()`(전체+변형별 키 삭제) + RecordStore `clearAll()`. SettingsView "통계 초기화" 섹션 → confirmationDialog(destructive) → `vm.resetStats()`(objectWillChange).

## 3. 구현 단계

- [x] T-041: 볼륨 슬라이더 (soundVolume/bgmVolume + SoundPlayer/BGMPLayer 적용)
- [x] T-042: 창 크기·위치 기억 (WindowAccessor + setFrameAutosaveName)
- [x] T-043: 승리 사운드 확장 + ConfettiView 파티클
- [x] T-044: 카드 뒷면 패턴 (CardBack enum + showBack + 딜 중 뒷면)
- [x] T-045: 경과 시간 표시 + 중지/재개
- [x] T-046: 통계/기록 초기화

## 4. 테스트 계획

- [x] TC-2.4-01: StatsStore.resetAll — 모든 키 삭제 확인 (빌드 검증)
- [x] TC-2.4-02: RecordStore.clearAll — 변형별 기록 삭제 확인 (RecordStoreTests 신규 1개)
- [x] TC-2.4-03: 기존 47개 + 신규 1개 = **48개 통과**

## 5. 롤백 계획

- 볼륨/카드뒷면/타이머/창기억: 새 키 추가 → 기존 데이터 무손상. 창기억은 setFrameAutosaveName 제거 시 기본 크기로 복귀
- 초기화: 파괴적 작업이나 명시적 버튼+확인 다이얼로그 경유 → 실수 방지

## 6. 성능 예산

- 타이머: 1초 Timer — 무시 가능. 화면 새로고침은 gameInfoView만
- Confetti: 승리 시에만 표시, 60fps 단기 — 무시 가능
- 나머지: 설정 저장뿐 — 무시 가능
