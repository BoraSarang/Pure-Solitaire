/// 홈셀 자동 이동(오토플레이) — 마이크로소프트 "안전" 규칙
///
/// 안전 규칙: 카드 C(rank r)를 홈으로 보내도 타블로 진행이 막히지 않는 경우에만 자동 이동.
/// C 위에 쌓일 수 있는 카드들(rank r-1, 반대 색 2장)이 모두
/// 이미 홈에 있거나, 그 자체로 홈 이동이 안전한 경우 C는 안전하다.
public enum AutoPlay {

    /// 현재 상태에서 안전하게 홈으로 자동 이동 가능한 이동 목록
    public static func safeAutoPlayMoves(in game: FreeCellGame) -> [Move] {
        var moves: [Move] = []
        for i in game.columns.indices {
            guard let card = game.columns[i].last else { continue }
            if game.canMoveToHome(card),
               isSafeToAutoplay(card, in: game),
               game.canMove(.columnToHome(columnIndex: i, card: card)) {
                moves.append(.columnToHome(columnIndex: i, card: card))
            }
        }
        for i in game.freeCells.indices {
            guard let card = game.freeCells[i] else { continue }
            if game.canMoveToHome(card),
               isSafeToAutoplay(card, in: game),
               game.canMove(.freeCellToHome(freeCellIndex: i, card: card)) {
                moves.append(.freeCellToHome(freeCellIndex: i, card: card))
            }
        }
        return moves
    }

    public static func isSafeToAutoplay(_ card: Card, in game: FreeCellGame) -> Bool {
        if card.rank == .ace { return true }
        guard game.canMoveToHome(card) else { return false }
        guard let lowerRank = card.rank.previous else { return true }

        let blockers = game.allCardsInPlay.filter {
            $0.rank == lowerRank && $0.color == card.color.opposite
        }
        for blocker in blockers {
            if game.isHomeCard(blocker) { continue }
            guard game.canMoveToHome(blocker), isSafeToAutoplay(blocker, in: game) else {
                return false
            }
        }
        return true
    }
}
