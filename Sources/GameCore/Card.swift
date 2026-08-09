public struct Card: Equatable, Hashable, Identifiable, Sendable, Codable {
    public let suit: Suit
    public let rank: Rank

    public init(suit: Suit, rank: Rank) {
        self.suit = suit
        self.rank = rank
    }

    /// rawValue: rank index (0..12) * 4 + suit index (0..3).
    /// A♣ = 0, A♦ = 1, A♥ = 2, A♠ = 3, 2♣ = 4, ... K♠ = 51
    public init(rawValue: Int) {
        self.suit = Suit(rawValue: rawValue % 4)!
        self.rank = Rank(rawValue: rawValue / 4 + 1)!
    }

    public var rawValue: Int {
        (rank.rawValue - 1) * 4 + suit.rawValue
    }

    public var id: String {
        "\(rank.shortLabel)\(suit.letter)"
    }

    public var color: CardColor {
        suit.color
    }

    public var shortDescription: String {
        "\(rank.shortLabel)\(suit.letter)"
    }
}
