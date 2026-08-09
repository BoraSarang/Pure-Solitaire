# PLAN v2.0 — 두 번째 게임: Baker's Game — macOS

> 작성일: 2026-08-05 | platform: macos | 상태: 진행중

## 1. 개요

기존 프리셀(`FreeCellGame`)과 같은 딜 번호(#1~#1,000,000)를 사용하면서 규칙이 다른 두 번째 게임 **Baker's Game**을 추가한다.
프리셀 MVP에서 검증된 딜 생성(DealGenerator/MicrosoftRNG), 게임 번호 선택 UI, 자동저장, 실행취소/다시실행, 드래그&드롭, 접근성 구조를 그대로 재사용한다.

## 2. Baker's Game 규칙

표준 프리셀과의 차이점만 정리한다.

| 항목 | 기존 프리셀 | Baker's Game |
|------|-------------|--------------|
| 딜 | 52장 · 8열 · 게임 번호 | **동일** (같은 딜 번호 그대로) |
| 프리셀(무료셀) | 4개 | **없음 (0개)** |
| 홈셀 | 4개 · A→K · 같은 무늬 | 동일 |
| 타블로 쌓기 | **내림차순 + 교대색** | **내림차순 + 같은 무늬(같은 수트)** |
| 이동(열→열) | 여러 장(수퍼무브) 가능 | **한 번에 한 장만** 이동 |
| 빈 열 활용 | 임시 저장 가능 (용량 공식) | 임시 저장 가능 (빈 열 1개 = 1칸) |
| 홈셀에서 꺼내기 | 허용 | 허용 (동일) |

- 수퍼무브: Baker's Rule은 "한 번에 한 장만"이 공식. 용량 공식에서 프리셀이 0이므로 `(0+1) × 2^(빈 열 수)` = `2^(빈 열 수)`가 된다.
  단 "한 장만 이동"을 엄격히 하면 수퍼무브가 의미가 없으므로, **열→열 이동은 카드 수에 무관하게 규칙이 허용하되 фактически 빈 열 개수만으로 수퍼무브 용량을 계산**한다. (`cardCount` 검사는 `2^(빈열)` 이하)

  > 사용자 협의 필요: "한 번에 한 장만" vs "수퍼무브 허용". 기본값은 표준 Baker's Game 공식에 맞춰 수퍼무브 허용(빈 열 기반 용량)으로 구현.

## 3. 결정 사항 (결정 로그)

- **D2.0-1**: 게임 형식은 `GameVariant` enum (`freecell` / `bakersGame`)으로 모델에 저장. 같은 시나리오, 같은 딜 번호, 같은 보드 구조.
- **D2.0-2**: FreeCellGame에 `variant` 필드 추가. `freeCellCount`가 variant에 따라 달라짐 (프리셀 0 / 4).
- **D2.0-3**: 기존 저장 데이터 호환 — 새 `variant` 필드는 Codable에서 `decodeIfPresent`로 기본 `freecell` 처리 (기존 저장 게임 무손상 복구).
- **D2.0-4**: 뷰/ViewModel은 `variant`를 보고 프리셀 행을 숨기고, 규칙(같은 수트/수퍼무브)을 분기. 공용 컴포넌트 재사용.
- **D2.0-5**: 이동/홈/프리셀 검증 분기는 `FreeCellRule`에 variant 파라미터를 넘기는 대신, `FreeCellGame.canMove` 내부에서 variant 분기 (리팩터링 최소화).

## 4. 아키텍처

```
FreeCellGame (기존 확장)
 ├─ variant: GameVariant (신규)
 ├─ freeCells: [Card?]  → variant == freecell ? 4개 : 0개
 ├─ canMove / apply / hint / undo / redo (variant 분기)
 └─ FreeCellRule.canMoveToColumn: 변형 파라미터 추가

FreeCellViewModel (신규 분기)
 ├─ 새 게임: variant 선택 UI / 명령
 ├─ 프리셀 행 HStack 조건부 렌더
 └─ 미사용 이동(프리셀) 무시

GameBoardView (기존 재사용)
 └─ topRow 프리셀 영역을 variant에 따라 숨김
```

## 5. 구현 단계

- [x] T-019: 게임 형식 결정 (Baker's Game) + PLAN 작성 — 예정
- [ ] T-020: `GameVariant` enum + `FreeCellRule` 같은-수트/수퍼무브 분기 + 테스트
- [ ] T-021: `FreeCellGame` variant 통합 (freeCellCount, canMove, 즉시 이동 로직)
- [ ] T-022: ViewModel — variant 선택(새 게임), 실전 규칙 연동
- [ ] T-023: GameBoardView/SideBar/CardSource — 프리셀 조건부 렌더, 접근성 유지
- [ ] T-024: 자동저장 variant 호환 (decodeIfPresent) + 기존 데이터 무손상 테스트
- [ ] T-025: 빌드/실행/수동 플레이 검증 + 문서 갱신 (CHANGELOG/TODO/session)

## 6. 테스트 계획

- [ ] TC-2.0-01: 같은 딜 번호 → freecell/bakersGame 모두 같은 초기 columns (쌍 검증)
- [ ] TC-2.0-02: Baker's — 타블로 같은 수트만 쌓기 (교대색 카드는 거부, 같은 수트 내림차순 허용)
- [ ] TC-2.0-03: Baker's — 프리셀 이동 인덱스가 비어도 거부 (freeCellCount=0)
- [ ] TC-2.0-04: Baker's — 수퍼무브 용량 (빈 열 1개 → 최대 2장, 허용)
- [ ] TC-2.0-05: variant == freecell 기본값 (기존 게임 복구 무손상)
- [ ] TC-2.0-06: Codable 왕복 (variant 유지)

## 7. 롤백 계획

- `git revert` 또는 모델 필드 제거. variant는 기존 데이터에 안전(기본 freecell)하므로 롤백 시 손실 없음.
- 런타임: 앱 재시작으로 자동저장 상태 복구.

## 8. 성능 예산

- 커스텀 로직 오버헤드: variant 분기뿐이라 p95/메모리 영향 없음.
- 보드 렌더: 프리셀 행 제거로 요소 수 감소.

## 9. 에러코드

기존 에러코드 체계에 신규 코드 없음 (신규 모드이지만 유효하지 않은 이동은 기존 E-COM-VALID 류로 처리).