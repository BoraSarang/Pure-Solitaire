/// 변형 게임의 선택 옵션 (난이도 등) — 게임 번호 시트/설정에서 자동 렌더링
///
/// 게임을 추가할 때 `GameVariant.optionDefinitions`에 옵션 정의만 추가하면
/// 게임번호 시트와 설정의 "게임별 옵션"에 자동으로 반영된다.

/// 옵션의 선택지 (예: Spider 난이도 "초급 (1수트)")
public struct GameOptionChoice: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

/// 변형별 옵션 정의 (예: "난이도" — 선택지 3개)
public struct GameOption: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let choices: [GameOptionChoice]

    public init(id: String, title: String, choices: [GameOptionChoice]) {
        self.id = id
        self.title = title
        self.choices = choices
    }
}
