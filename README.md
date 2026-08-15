<p align="center">
  <img src="images/AppIcon-1024.png" width="160" alt="Pure Solitaire 아이콘">
</p>

<h1 align="center">Pure Solitaire · 순수한 솔리테어</h1>

<p align="center">
  맥을 위해 재탄생한 군더더기 없는 클래식 카드 게임 모음.<br>
  광고 없이, 로그인 없이, 깔끔하게 — 마이크로소프트 정통 규칙 그대로.
</p>

<p align="center">
  <strong>macOS 네이티브</strong> · <strong>Swift 6 + SwiftUI</strong> · <strong>12가지 게임 형식</strong>
</p>

<p align="center">
  <a href="https://github.com/BoraSarang/Pure-Solitaire/releases"><img src="https://img.shields.io/github/v/release/BoraSarang/Pure-Solitaire?label=최신 릴리스&color=2ea44f" alt="최신 릴리스"></a>
  <a href="https://github.com/BoraSarang/Pure-Solitaire/actions/workflows/release.yml"><img src="https://img.shields.io/github/actions/workflow/status/BoraSarang/Pure-Solitaire/release.yml?label=빌드&color=2ea44f" alt="빌드 상태"></a>
  <a href="https://github.com/BoraSarang/Pure-Solitaire"><img src="https://img.shields.io/github/repo-size/BoraSarang/Pure-Solitaire?label=저장소&color=2ea44f" alt="저장소 크기"></a>
</p>

<p align="center">
  ✦ 제작자 <a href="https://github.com/BoraSarang">BoRaSaRang</a> &nbsp;·&nbsp;
  ✉️ 문의 <a href="mailto:leeborasarang@gmail.com">leeborasarang@gmail.com</a>
</p>

---

## 🖼️ 미리보기

<p align="center">
  <img src="docs/screenshots/macos/v3.22/home.png" width="620" alt="홈 화면">
</p>
<p align="center">
  <img src="docs/screenshots/macos/v3.22/play.png" width="620" alt="게임 보드">
</p>

## 🎮 지원 게임 (12종)

| 게임 | 특징 |
|------|------|
| **FreeCell** | 마이크로소프트 정통 규칙, 8열 + 프리셀 4 + 홈셀 4, 수퍼무브 |
| **Baker's Game** | 프리셀 없이 같은 수트로만 정리하는 순수 프리셀 |
| **Klondike** | 스톡·웨이스트 + 7열, 교대색, 뒤집힌 카드, 스톡 재활용 (1/3장 선택) |
| **Spider** | 10열 + 스톡 5더미, 같은 수트 K→A 완성 (4가지 난이도) |
| **Sea Tower** | 10열×5장 + 프리셀 2장, 같은 수트, 빈 열엔 K만 |
| **Super FreeCell** | 2덱 104장 + 프리셀 6, 홈셀 수트당 26장 |
| **Yukon** | 앞면 카드와 그 위 전체를 그룹으로 자유 이동 |
| **Forty Thieves** | 2덱, 10열×4장 전부 앞면, 홈셀 8개 |
| **Golf** | 7열 전부 앞면, 웨이스트와 1 차이/같은 랭크 카드 제거 |
| **Pyramid** | 피라미드 28장, 합 13인 노출 카드 제거 |
| **TriPeaks** | 3개 봉우리, 웨이스트와 1 랭크 차이 제거 |
| **Scorpion** | 7열×7장 + 예비 더미 3장, 그룹 이동, 빈 열엔 K만 |

## ✨ 주요 기능

- **홈 화면**: 앱 시작 시 게임 선택 화면 먼저 표시 — 카테고리 4그룹(FreeCell/스톡/스파이더/카드 제거) + 그룹 내 난이도순 정렬 + 난이도 뱃지(쉬움/보통/어려움), 하던 게임 이어하기 카드
- **게임 번호 기반 딜**: 1 ~ 1,000,000 사이 게임 번호로 마이크로소프트와 동일한 배치 재현 (검증: 게임 #1/#617)
- **승리 보장 (Winnable)**: FreeCell 계열에서 풀리지 않는 번호를 건너뛰고 풀리는 번호로 자동 시작 (내장 솔버)
- **자동 풀어 보기 (⇧⌘P)**: 내장 DFS 솔버가 승리 경로를 찾아 자동으로 끝까지 재생 (진행률·속도 3단계·일시정지/중단, 시연 후 원상 복원)
- **내 이동 리플레이 (⇧⌘R)**: 승리한 판을 처음부터 내 이동 그대로 재생
- **데일리 도전**: 날짜 시드 고정 · 매일 9판 셔플 · 3개월 달력(날짜별 ★완료) · 별점(승리·시간·이동) · 월 통계·월 배지(브론즈/실버/골드/다이아) · 판별 난이도 태그
- **업적 10개**: 첫 승리부터 50승·5연승·변형 완주·챌린지 별 3까지 배지로 도전
- **점수 체계**: 게임별 표준 점수로 이동마다 누적, 승리 보너스, 최종 점수 통계 기록
- **직관적인 조작**: 드래그 & 드롭, 클릭 이동, 더블클릭 홈 자동 이동
- **무제한 실행 취소 / 다시 실행** + 상태 스냅샷 기반이라 크래시에 안전
- **자동 플레이**: 안전한 카드(에이스 등)를 홈셀로 자동 이동
- **힌트**: 이동 가능한 최적 후보를 표시 + 전체 힌트(모든 유효 이동 강조) + 드래그 경로 애니메이션
- **승리 연출**: 파티클(컨페티) + 사운드 시퀀스 + 배너
- **통계 & 기록**: 게임별 통계·최단 승리·최근 승리 기록 (자동 저장)
- **설정**: 카드 스타일(클래식/심플/레트로/딥) · 카드 뒷면 패턴(5종) · 배경색·커스텀 배경(사진 업로드) · 보드 줌 · BGM/효과음 볼륨
- **접근성**: VoiceOver 카드 힌트/값 제공, 화이트 배경 대응 검정 텍스트

## ⌨️ 단축키

| 단축키 | 동작 |
|--------|------|
| `⌘1` | 홈 화면 |
| `⌘N` | 새 게임 |
| `⌘G` | 게임 번호 선택 |
| `⌘D` | 데일리 딜 |
| `⌥⌘D` | 데일리 도전 |
| `⇧⌘P` | 자동 풀어 보기 |
| `⇧⌘R` | 내 이동 리플레이 |
| `⌥⌘T` | 업적 |
| `⌘Z` / `⇧⌘Z` | 실행 취소 / 다시 실행 |
| `⌘H` / `⇧⌘H` | 힌트 / 전체 힌트 |
| `⏎` | 힌트 적용 |
| `⇧⌘A` | 자동 플레이 |
| `⌘T` | 통계 |
| `⌘,` | 설정 |
| `⌘+` / `⌘-` | 보드 줌 |

## 🔧 시스템 요구 사항

- macOS 13 이상 (macOS 26, arm64에서 개발·검증)
- 기타 추가 설치 없음 — 로컬 실행 독립 앱

## 🚀 설치

GitHub Releases에서 최신 `.app` 번들을 받거나, 소스에서 직접 빌드:

```bash
# 빌드 · 테스트
swift build -c release
swift test -c release

# .app 번들을 ~/Applications 에 설치하고 실행
./scripts/build_and_run.sh release
```

> 앱 이름: **Pure Solitaire.app** — Dock에서는 **"순수한 솔리테어"**로 표시됩니다.

## 🛠️ 기술 스택

- **Swift 6 + SwiftUI**, Swift Package Manager (Xcode 프로젝트 불필요)
- 2개 타깃: `GameCore`(플랫폼 독립 규칙 로직, 단위 테스트) + `PureSolitaire`(SwiftUI 앱)
- 지속 저장: UserDefaults (설정·통계·저장 게임)
- 마이크로소프트 딜 알고리즘: LCG `state = (state×214013 + 2531011) mod 2³¹`, `rand = state >> 16`

## 🧪 테스트

- 단위 테스트 **253개** 통과 (딜 재현 · 이동 규칙 · 수퍼무브 용량 · 승리 판정 · 저장/복원 · 데일리 도전/챌린지/업적 · Winnable 솔버 · 자동 풀어 보기 · 난이도 판정 · 카테고리/난이도 표시)

```bash
swift test -c release
```

## 📄 문서

- [PRD — 제품 요구사항](docs/PRD.md)
- [DESIGN — 기술 설계](docs/DESIGN.md)
- [변경 이력 (CHANGELOG)](docs/CHANGELOG.md)

## ⚖️ 라이선스

© 2026 Pure Solitaire — 모든 권리 보유.

## 🙌 만든 사람

- **제작자**: [BoRaSaRang](https://github.com/BoraSarang)
- **문의 메일**: [leeborasarang@gmail.com](mailto:leeborasarang@gmail.com)
- 버그 제보, 기능 제안, 여러 의견은 언제든 메일로 보내 주세요. 😊