public enum Rank: Int, CaseIterable, Sendable, Equatable, Hashable, Comparable, Codable {
    case ace = 1
    case two, three, four, five, six, seven, eight, nine, ten, jack, queen, king

    public var next: Rank? {
        Rank(rawValue: rawValue + 1)
    }

    public var previous: Rank? {
        Rank(rawValue: rawValue - 1)
    }

    /// UI 표시용 (A, 2..10, J, Q, K)
    public var label: String {
        switch self {
        case .ace: "A"
        case .ten: "10"
        case .jack: "J"
        case .queen: "Q"
        case .king: "K"
        default: String(rawValue)
        }
    }

    /// 마이크로소프트 딜 표기용 (A, 2..9, T, J, Q, K)
    public var shortLabel: String {
        switch self {
        case .ace: "A"
        case .ten: "T"
        case .jack: "J"
        case .queen: "Q"
        case .king: "K"
        default: String(rawValue)
        }
    }

    public static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
