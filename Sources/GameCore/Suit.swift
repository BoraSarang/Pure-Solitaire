public enum CardColor: Sendable, Equatable {
    case red
    case black

    public var opposite: CardColor {
        self == .red ? .black : .red
    }
}

public enum Suit: Int, CaseIterable, Sendable, Equatable, Hashable, Codable {
    case clubs = 0
    case diamonds = 1
    case hearts = 2
    case spades = 3

    public var color: CardColor {
        switch self {
        case .clubs, .spades: .black
        case .diamonds, .hearts: .red
        }
    }

    public var symbol: String {
        switch self {
        case .clubs: "♣"
        case .diamonds: "♦"
        case .hearts: "♥"
        case .spades: "♠"
        }
    }

    public var letter: String {
        switch self {
        case .clubs: "C"
        case .diamonds: "D"
        case .hearts: "H"
        case .spades: "S"
        }
    }
}
