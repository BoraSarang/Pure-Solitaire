# PLAN_v1.0_macos — 프리셀 MVP 구현 계획

## 1. 개요
- 목표: 마이크로소프트 정통 프리셀 규칙을 재현하는 macOS 네이티브 앱 `Pure FreeCell` v1.0
- 배포: `~/Applications/Pure FreeCell.app` (SwiftPM CLI 빌드)
- 사용자: 로컬 단독 플레이 (로그인/동기화 없음)

## 2. 결정 사항
| 항목 | 결정 | 근거 |
|------|------|------|
| 언어/UI | Swift 6 + SwiftUI | 네이티브, 최신 macOS 지원 |
| 빌드 | SwiftPM (swift build) | CLI 자동화 용이, Xcode 프로젝트 불필요 |
| 카드 렌더링 | 커스텀 벡터 드로잉 | 리소스 불필요, 브랜드 컨셉 부합 |
| 딜 알고리즘 | MS LCG (214013/2531011) | MS 정통 딜 재현 + 게임 번호 검증 |
| 게임 번호 범위 | 1 ~ 1,000,000 | Windows FreeCell 후기 버전 범위 |
| 상태 관리 | FreeCellViewModel (@StateObject) | 단일 화면 게임, 간결 유지 |
| 저장 | UserDefaults | 단순 설정/통계, 외부 의존성 없음 |
| 로그인 | 없음 | 로컬 단독 플레이 |

## 3. 아키텍처
```
GameCore (로직) ← PureFreeCell (SwiftUI 앱)
- Card/Suit/Rank/Deck
- MicrosoftRNG + DealGenerator
- GameRule 프로토콜 + FreeCellRule
- FreeCellGame (상태/Move/Undo/Redo)
- AutoPlay (안전 카드 판정)
```
자세한 설계: `docs/DESIGN.md`

## 4. 구현 단계 (T-번호)
Phase 1 (GameCore) → Phase 2 (SwiftUI) → Phase 3 (배포)
상세: `docs/TODO.md`

### Phase 1 상세
- **T-002**: `Suit`(무늬+색), `Rank`(순서/다음/이전), `Card`(Equatable/Hashable), `Deck`(52장)
- **T-003**: 
  - `MicrosoftRNG`: LCG 구현, `next() -> Int` (0~32767)
  - `DealGenerator`: `deal(gameNumber:) -> [[Card]]` (8열)
  - 게임 #1, #617 기대 결과 하드코딩 테스트
- **T-004**:
  - `canMoveToColumn`, `canMoveToHome`, `canMoveToFreeCell`
  - `movableRun(from:length:)` 시퀀스 추출
  - `supermoveCapacity(emptyFree:emptyColumns:destinationIsEmpty:)`
  - 홈셀 꺼내기 허용, 승리 판정
- **T-005**:
  - `Move` 열거형 + `undo()`/`redo()`
  - `AutoPlay.safeAutoPlayCards()` (MS 안전 규칙)

### Phase 2 상세
- **T-006**: `GameBoardView` — 상단(홈 4 + 프리셀 4), 하단(타블로 8)
- **T-007**: `CardView` — RoundedRect + 랭크/무늬 벡터, 클래식/심플 스타일, 카드 비율 0.7
- **T-008**: `.draggable`/`.dropDestination` 드래그 + 클릭 선택 이동 + 더블클릭 홈 이동, 드롭 대상 하이라이트
- **T-009**: 메뉴(⌘N/⌘Z/⇧⌘Z/⌘G/⌘H/⇧⌘A/⌘,), 게임 번호 시트
- **T-010**: 홈 완성 시 승리, 남은 카드 자동 완성 애니메이션, 오토플레이 토글
- **T-011**: 승/패/연승 통계, StatsView
- **T-012**: 카드 스타일/배경/오토플레이/애니메이션 설정

### Phase 3 상세
- **T-013**: 아이콘 (카드 모양) → `AppIcon.icns`
- **T-014**: `scripts/build_and_run.sh` — 빌드→번들→`~/Applications` 설치→실행
- **T-015**: 검증 (딜 테스트 통과, 앱 실행, 수동 플레이, 스크린샷)

## 5. 테스트 계획
| TC | 내용 | 대상 |
|----|------|------|
| TC-001 | 게임 #1 딜 == MS 원본 | GameCoreTests |
| TC-002 | 게임 #617 딜 == MS 원본 | GameCoreTests |
| TC-003 | 이동 규칙 (타블로 교대색, 홈셀 순서) | GameCoreTests |
| TC-004 | 수퍼무브 용량 공식 경계값 | GameCoreTests |
| TC-005 | Undo/Redo 상태 복원 | GameCoreTests |
| TC-006 | 오토플레이 안전 판정 | GameCoreTests |
| TC-007 | 앱 실행 + 게임 #1 딜 확인 | 수동 |
| TC-008 | 드래그/더블클릭/취소 조작 | 수동 |
| TC-009 | 설정/통계 영속성 (재실행 후 유지) | 수동 |

## 6. 롤백 계획
- 빌드 실패: 이전 `~/Applications/Pure FreeCell.app` 백업본으로 복원
- 딜 불일치: T-003 테스트로 탐지 → RNG/셔플 수정
- 규칙 오류: 단위 테스트 보강 후 수정
- 앱 이상: `rm ~/Applications/Pure FreeCell.app` 후 재설치

## 7. 성능 예산
| 지표 | 목표 |
|------|------|
| Cold Start | ≤ 1.5s |
| 딜 생성 | < 1ms |
| 프레임 | 60fps |

## 8. 에러코드
| 코드 | 내용 | 사용자 메시지 |
|------|------|---------------|
| E-MAC-GAME-1001 | 유효하지 않은 게임 번호 | 1~1,000,000 사이의 번호를 입력하세요. |
| E-MAC-GAME-1002 | 무효한 이동 시도 | 이 카드는 이동할 수 없습니다. |
| E-MAC-STOR-1001 | 통계 저장 실패 | 통계를 저장하지 못했습니다. |
| E-MAC-BUILD-1001 | 빌드 실패 | 빌드에 실패했습니다. 로그를 확인하세요. |

## 9. 권한
- 별도 권한 없음 (오프라인 단독 앱)
