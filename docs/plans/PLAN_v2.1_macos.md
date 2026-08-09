# PLAN v2.1 — 통계 분리 + 사운드 + 키보드/접근성 + 힌트 고도화 — macOS

> 작성일: 2026-08-05 | platform: macos | 상태: 진행중

## 1. 개요

v2.0(Baker's Game)이 완료된 후의 후속 4개 작업. 변형 프리셀(Sea Tower/Super FreeCell)은 **보류**.

1. **T-026 통계 형식별 분리** — 현재 통계는 전 게임 합산. FreeCell/Baker's 별 개별 통계 + 전체 합계 표시
2. **T-027 사운드/효과** — 카드 이동/배치/승리 효과음 + 설정 토글
3. **T-028 키보드/접근성 후속** — Esc 선택 해제, 스페이스 홈 이동, VoiceOver 라벨 보강
4. **T-029 힌트 고도화** — 힌트 후보 하이라이트 + 반복 시 다음 후보 순환

## 2. 결정 사항

- **D2.1-1 통계 키 구조**: 기존 `stats.totalGames` 등은 **전체 합계로 유지**, 변형별 키 `stats.{variant}.{key}` 추가. 기존 저장 데이터 무손상(총계 그대로 유지됨).
- **D2.1-2 통계 화면**: 세그먼트(전체 / FreeCell / Baker's Game)로 전환해 개별 통계 표시.
- **D2.1-3 마지막 게임 번호**: `lastGameNumber`도 변형별로 저장 → 변형 전환 시 그 변형의 마지막 번호 이어감.
- **D2.1-4 사운드**: 시스템 사운드(NSSound) 사용, 파일 임베드 없음. `UserSettings.soundEnabled` 추가.
  - 이동: Glass, 홈 배치: Tink, 승리: Hero
- **D2.1-5 키보드**: Esc=선택 해제, Space=선택 카드 홈 이동(더블클릭 동일). macOS 기본 키보드 포커스는 SwiftUI가 처리하므로 화살표 내비는 생략.
- **D2.1-6 힌트**: `hint()`는 기존 유지(홈 우선). ViewModel에 `hintCandidates` 순환 상태 추가 — ⌘H 반복 시 다음 후보, GameBoardView에서 해당 카드 하이라이트.

## 3. 구현 단계

- [ ] T-026: StatsStore 변형별 분리 + StatsView 세그먼트 + lastGameNumber 변형별
- [ ] T-027: SoundPlayer + 사운드 트리거(apply/승리) + 설정 토글
- [ ] T-028: 키보드(Esc/Space) + VoiceOver 후속 라벨
- [ ] T-029: 힌트 후보 + 하이라이트 + 순환

## 4. 테스트 계획

- [ ] TC-2.1-01: StatsStore 변형별 기록 분리 (freecell/bakers 총게임·승리·승률)
- [ ] TC-2.1-02: legacy 키(전체)와 변형별 키 분리 유지
- [ ] TC-2.1-03: (사운드/키보드/힌트는 UI 로직 — 수동 확인)

## 5. 롤백 계획

- 통계 키 추가만이라 기존 키와 무관 → 삭제 시 기존 데이터 유지
- 사운드/키보드/힌트는 독립 기능 → 설정 끔/코드 제거

## 6. 성능 예산

- 사운드: NSSound 메모리 캐시(3개) — 미미
- 통계: UserDefaults 키 2배 — 미미
- 힌트: 후보 탐색은 hint()와 동일 O(n²) — 미미