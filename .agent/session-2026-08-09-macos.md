# 세션 로그 — 2026-08-09 (macos) — v3.14.0 릴리스

## 1. 무엇을
- v3.14 전체 힌트 강조 릴리스 완료:
  - T-175 VM 상태: `showAllHints` + `currentHintCandidates()`(게임별 후보 공용 추출, 기존 `hint()` 리팩터) + `displayedHintMoves` + `toggleAllHints()/clearAllHints()` — 이동(`apply`)·새 게임(`newGame`) 시 자동 해제
  - T-176 GameBoardView 소스 헬퍼 13개를 `displayedHintMoves` 기반 `contains`로 일반화 (FreeCell/Klondike/Yukon/FortyThieves/Golf/Pyramid/TriPeaks/Spider + 홈/프리셀)
  - T-177 SideBar "전체 힌트" 토글 버튼(isActive) + GameCommands `⇧⌘H` 메뉴 추가
  - T-178 회귀(`swift test` **178개** 통과) + debug·release 빌드 경고 0 + release 설치·실행 + 문서

## 2. 플랫폼
- macos (단일 앱). 표시 계층만 변경 — GameCore/저장 무변경.

## 3. 빌드/검증 결과
- `swift build`(debug·release) 경고 0건. `swift test` 178개 전부 통과 (변경 회귀 없음).
- `bash scripts/package_release.sh 3.14.0` → `Pure-Solitaire-3.14.0-macos.zip`, 재설치 + 실행 확인 (PID 27391).
- AX/스크린샷: 텍스트 전용 모델 세션 — 화면 캡처 대신 PAIN 수동 검증 가이드 `docs/tests/v3.14_macos.md` 위임.

## 4. 남은 TODO
- (없음 — v3.14 마감). 차기 후보(v3.15): RESEARCH.md §5 — 커스텀 배경/카드면, Winnable+데일리, 챌린지/업적, 추가 변형 등. 수동 검증 가이드 실행 대기.

## 5. 다음 에이전트 전달 로그
- 에러코드: 없음.
- 주의: `processHint()` 내부 게임별 후보 추출 로직이 `currentHintCandidates()`로 이전됨 — 이후 힌트 관련 수정은 공용 메서드 참조. 소스 강조 판정은 이제 `displayedHintMoves` 기준.
- 상태 키: `showAllHints`(세션 메모리 — 영구 저장 없음).

## 6. 문서 업데이트 목록
- docs/plans/PLAN_v3.14_macos.md (T-175~178 체크), docs/TODO.md (v3.14 완료), docs/DESIGN.md (§3.16 추가), docs/CHANGELOG.md ([3.14.0]), docs/tests/v3.14_macos.md (신규), 본 세션 로그.

## 7. 오프라인 큐 상태
- 해당 없음 (오프라인 큐 없는 단일 macOS 앱).

## 8. E2E/k6
- 해당 없음. 단위 테스트 178개 통과.