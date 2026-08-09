# AGENTS.macos.md — macOS 플랫폼 특화 규칙

> Pure Solitaire (순수한 솔리테어) 프로젝트 (macOS 전용) 특화 지침. 공통 규칙은 AGENTS.md 참조.

## 1. 플랫폼 정보
- OS: macOS 26+ (arm64)
- 툴체인: Xcode 26.6 (Swift 6.3)
- 빌드: SwiftPM CLI (`swift build`), Xcode 프로젝트 사용 안 함
- 배포: `~/Applications/Pure Solitaire.app` (Dock 표시명: 순수한 솔리테어)

## 2. 프로젝트 구조
- `Package.swift`: GameCore + PureSolitaire + GameCoreTests 타깃
- `Sources/GameCore/`: 플랫폼 독립 게임 로직 (SwiftUI 미사용, 단위 테스트 대상)
- `Sources/PureSolitaire/`: SwiftUI 앱 계층
- `scripts/build_and_run.sh`: 빌드 → .app 번들 → 설치 → 실행
- `docs/`: PRD/DESIGN/PLAN/TODO/plans/PLAN_v1.0_macos.md

## 3. 개발 규칙
1. **로직은 GameCore에, UI는 PureSolitaire에**: 뷰에서 게임 규칙을 직접 구현 금지
2. **카드 모델은 값 타입**: `Card`는 Equatable/Hashable/Identifiable, 복사 안전
3. **모든 이동은 `Move`로 기록**: Undo/Redo는 역연산으로만 구현
4. **딜은 게임 번호 기반**: 무작위 셔플 금지, `DealGenerator.deal(gameNumber:)` 필수
5. **상태는 단일 뷰모델**: `FreeCellViewModel`(@StateObject)에 집중, 전역 상태 최소화
6. **지속 저장**: UserDefaults 사용, 파일/외부 DB 금지
7. **한국어 응답/문서 필수**, 코드 주석/로그 영어 허용
8. **검증 명령**:
   - 빌드: `swift build -c debug`
   - 테스트: `swift test` (딜 #1/#617 검증 포함)
   - 배포: `./scripts/build_and_run.sh`

## 4. 빌드/배포 검증 게이트
- [ ] `swift build` 성공
- [ ] `swift test` 전체 통과 (특히 MicrosoftRNGTests 게임 #1/#617)
- [ ] `./scripts/build_and_run.sh` → `~/Applications/Pure Solitaire.app` 설치 + 실행

## 5. 코드 컨벤션
- 카드 무늬: `♣ ♦ ♥ ♠` 글리프 또는 커스텀 Shape, 색은 red/black
- 카드 가로세로비: 0.7
- 뷰 파일은 `Views/`, 모델은 `Models/`, 뷰모델은 `ViewModels/`
- 에러코드: `E-MAC-{CATEGORY}-{NUM4}` (GAME/STOR/BUILD 등)

## 6. 참고
- 마이크로소프트 딜 알고리즘: LCG `state=(state*214013+2531011) mod 2^31`, `rand=state>>16`
- 수퍼무브: `(빈 프리셀 + 1) × 2^(빈 열 수)`, 목적지 빈 열 제외
- 홈셀에서 카드 꺼내기 허용 (MS 규칙)
