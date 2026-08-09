# PLAN v3.1 — Spider(스파이더) 추가 — macOS

> 작성일: 2026-08-06 | platform: macos | 상태: 진행중

## 1. 개요

FreeCell/Baker's/Klondike에 이어 네 번째 게임 **Spider**를 추가한다.

- 구조: **10개 타블로 열**(뒤집힌 카드 포함), **스톡 5더미**(각 10장), 홈셀/프리셀/웨이스트 없음.
- 카드: **2덱(104장)**. 난이도(사용 수트 수) 선택 가능 — 1수트(초급)/2수트(중급)/4수트(고급).
- 규칙: **같은 수트 내림차순(K→A) 시퀀스**만 이동. 빈 열엔 어떤 카드든 배치.
- 완성: 한 열에 **K→A 같은 수트 13장**이 연속이면 자동 제거(완성 수트 카운트 +1). 스톡 클릭 시 각 열에 1장씩 앞면 딜.
- 승리: 완성 수트 **8개**(2덱 기준) 달성.

## 2. 결정 사항

- **D3.1-1 병렬 추가**: 기존 게임/뷰는 유지. `SpiderGame` 신규 struct + ViewModel/보드에 분기. 기존 59개 테스트로 보호.
- **D3.1-2 덱 구성**: `DealGenerator.spiderCards(gameNumber:suitCount:)` — Microsoft RNG로 104장 셔플.
  - 1수트: 수트 1개 × 8세트(13장×8=104), 완성 8개
  - 2수트: 수트 2개 × 4세트(26장씩), 완성 8개
  - 4수트: 수트 4개 × 2세트(52장씩), 완성 8개
- **D3.1-3 Move 확장**: `dealFromStock` 1케이스만 추가(기존 `columnToColumn` 재사용).
- **D3.1-4 딜 배치**: 열 0~3은 6장, 열 4~9는 5장(총 54장) → 맨 위만 앞면. 나머지 50장 스톡(5더미×10).
- **D3.1-5 완성 수트**: 이동 적용 후 각 열에서 K→A 같은 수트 13장 연속 시퀀스를 찾아 자동 제거(`completedSuits` +1).
- **D3.1-6 이동 규칙**: 같은 수트 내림차순 연속 시퀀스만 이동 가능. 목적지 빈 열은 아무 카드/시퀀스 허용. 앞면 카드만 이동.
- **D3.1-7 저장**: `GameSaver`에 `persistence.savedSpider` 키.
- **D3.1-8 통계/기록**: `variant.rawValue` 키 자동 분리. 난이도별 별도 구분은 하지 않음(변형 단위).
- **D3.1-9 난이도 선택**: 게임 번호 시트에 난이도 세그먼트(초급/중급/고급) 추가. 현재 난이도만 저장·복원.
- **D3.1-10 보드**: 상단에 스톡 5더미(뒷면) + 완성 수트 표시, 하단 10열. 카드 크기 파라미터 재조정(10열).

## 3. 구현 단계

### 1단계: GameCore
- [x] T-060: `DealGenerator.spiderCards` (104장 셔플, 수트 구성)
- [x] T-061: `Move.dealFromStock` + `GameVariant.spider` + `SpiderDifficulty`
- [x] T-062: `SpiderGame` 구현 (columns[ColumnCard]/stock/completedSuits + canMove/apply/undo/redo + completeSequence 자동 제거 + hint + Codable)
- [x] T-063: `SpiderGameTests` 작성 (딜 구성/같은 수트 이동/완성 수트/스톡 딜/승리/undo/Codable)

### 2단계: ViewModel
- [x] T-064: ViewModel `spider` 분기 (이동 디스패치, 탭, 스톡 딜, 게임정보)
- [x] T-065: `GameSaver` spider 저장/복원

### 3단계: 보드
- [x] T-066: GameBoardView spider 레이아웃 (상단 스톡 5더미 + 완성 수트, 10열, 뒤집힌 카드)
- [x] T-067: 게임 번호 시트 난이도 선택 + 게임 전환 순환에 spider 포함

### 4단계: 검증
- [x] T-068: 회귀 테스트 + Spider 테스트 통과, release 빌드/설치/실행

## 4. 테스트 계획

- [ ] TC-3.1-01: 덱 구성 — 총 104장, 난이도별 수트 수 (1/2/4)
- [ ] TC-3.1-02: 딜 — 열 0~3은 6장, 열 4~9는 5장, 맨 위만 앞면, 스톡 50장
- [ ] TC-3.1-03: 같은 수트 내림차순 시퀀스 이동, 다른 수트 시퀀스 이동 불가, 빈 열엔 아무 카드
- [ ] TC-3.1-04: 완성 수트 — K→A 13장 자동 제거 + completedSuits 증가
- [ ] TC-3.1-05: 스톡 딜 — 각 열 1장 앞면 추가, 스톡 50장 감소
- [ ] TC-3.1-06: 승리 판정 — completedSuits == 8
- [ ] TC-3.1-07: undo/redo (완성 수트 포함), Codable 왕복
- [ ] TC-3.1-08: 기존 59개 회귀 통과

## 5. 롤백 계획

- 병렬 추가 + variant 분기 → Spider 코드 제거 시 기존 앱 복귀
- GameSaver 새 키 추가 → 기존 저장 무손상

## 6. 성능 예산

- Spider 상태 104장, 보드 10열 — 기존 대비 소폭 증가. undo/redo 스냅샷 ~104카드
- 10열 카드 크기 자동 조정으로 800×600 창에서도 전체 표시
