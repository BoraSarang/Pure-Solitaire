public enum Deck {
    /// 표준 52장 덱 (rawValue 0..51 순서: A♣ ... K♠)
    public static func standard() -> [Card] {
        (0..<52).map { Card(rawValue: $0) }
    }
}
