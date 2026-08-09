/// 카드 게임 규칙 추상화 (추후 다른 게임 형식 확장용)
public protocol GameRule {
    var isWon: Bool { get }
    func hint() -> Move?
    func autoPlayMoves() -> [Move]
}
