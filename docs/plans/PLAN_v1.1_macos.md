# PLAN — v1.1 [macos] — 자동 저장 (T-017)

## 개요
- 프리셀 게임 도중 앱 종료/크래시/실수로 닫는 상황에서 **진행 상태를 UserDefaults에 자동 저장**하고, 재시작 시 이어서 복구한다.
- 배경: v1.0.6-2에서 실행취소 크래시(PID 30711)를 겪으면서, 게임 진행을 잃지 않는 안전망 필요성 대두.

## 결정 사항
- 저장 포맷: **`FreeCellGame` 전체를 Codable(JSON)로 직렬화** → cols/freeCells/homes/gameNumber/moveCount/**undo/redo 스택(Snapshot)**까지 복원. 상태 스냅샷 방식이므로 이동 기반 재연산 없이 완전 복구 가능.
- 저장소: `UserDefaults.standard`, 키 `"persistence.savedGame"` (JSON Data).
- 저장 타이밍: 모든 상태 변경 지점(이동/undo/redo/자동 이동/새 게임) + 앱 scenePhase가 비활성/백그라운드 전환 시 안전 저장.
- 승리 시: 저장 클리어 → 재시작 시 완료된 게임 대신 새 게임.
- 복구 실패/없음: 기존 신규 게임 로직 그대로.

## 아키텍처
- `GameCore`:
  - `Card`, `Suit`, `Rank`에 `Codable` 추가 (Int raw-value enum → 자동 합성).
  - `FreeCellGame: Codable`, 내부 `Snapshot: Codable` (undo/redo 포함 전체 저장).
- `PureFreeCell` (신규 `Persistence/GameSaver.swift`):
  - `save(_ game:)` / `restore() -> FreeCellGame?` / `clear()`.
- `FreeCellViewModel`:
  - `init()` 에서 저장 상태 복원 시도 → 성공 시 복원(자동 플레이 재실행 금지), 실패 시 `stats.lastGameNumber` 기반 신규 게임.
  - 상태 변경 지점에서 `persist()` 호출.
- `PureFreeCellApp`: `.scenePhase` 감지로 백그라운드 진입 시 `vm.persist()`.

## 구현 단계 (T-￾번호 매핑)
- [ ] 1. Card/Suit/Rank `Codable` 추가 (GameCore)
- [ ] 2. `FreeCellGame` + `Snapshot` `Codable` 추가 (GameCore)
- [ ] 3. `GameSaver` 구현 (PureFreeCell/Persistence)
- [ ] 4. ViewModel `init` 복구 + 상태 변경 지점 `persist()`/`clearSave()` 연결
- [ ] 5. `PureFreeCellApp` scenePhase 안전 저장
- [ ] 6. 테스트 + release 빌드/설치/실행 검증 + 문서(TODO/CHANGELOG/session) 갱신

## 테스트 계획 (TC-번호)
- TC-017-001: Card/FreeCellGame JSON round-trip → 원본과 동일(Equatable). 이동 적용 후 상태 + undoStack 포함 복원 확인.
- TC-017-002: 코딩 후 앱 실행 → 아무 이동 → 앱 종료 → 재실행 → 동일 상태 이어지기 수동 확인.
- TC-017-003: 승리 상태가 저장되면 재시작 시 새 게임(클리어) 확인.

## 롤백 계획
- UserDefaults 키 제거/버전 구분으로 안전. 문제 시 `GameSaver` 호출부만 제거.

## 성능 예산
- 저장 호출 오버헤드 미미(JSON ~1~3KB), 액션당 1회. UI 스레드 부담 없음.

## 에러 코드
- E-MAC-STOR-1001: "저장된 게임 상태를 불러오지 못했습니다." (복구 실패 시 자동 신규 게임, 사용자 무경고)

## 권한 목록
- 신규 권한 없음 (UserDefaults 기존 사용 범위 내).