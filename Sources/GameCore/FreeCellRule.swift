/// 프리셀 이동 규칙 (마이크로소프트 정통)
public enum FreeCellRule {

    /// 타블로 열 이동 규칙: 내림차순 + 교대 색(프리셀/슈퍼) 또는 같은 수트(Baker's/Sea Tower). 빈 열은 프리셀/슈퍼만 아무 카드나, Sea Tower는 K만.
    public static func canMoveToColumn(_ card: Card, topCard: Card?, variant: GameVariant = .freecell) -> Bool {
        if let topCard {
            guard card.rank == topCard.rank.previous else { return false }
            switch variant {
            case .freecell, .klondike, .superFreeCell, .yukon: return card.color != topCard.color
            case .bakersGame, .seaTower, .fortyThieves: return card.suit == topCard.suit
            case .spider: return true
            case .golf, .pyramid, .triPeaks: return false
            }
        } else {
            // 빈 열: Sea Tower는 K만, 나머지는 아무 카드나
            if variant == .seaTower { return card.rank == .king }
            return true
        }
    }

    /// 홈셀 이동 규칙: 같은 무늬, A부터 시작, 이전 랭크 위로만.
    public static func canMoveToHome(_ card: Card, topCard: Card?) -> Bool {
        guard let topCard else { return card.rank == .ace }
        return card.suit == topCard.suit && card.rank == topCard.rank.next
    }

    /// 프리셀 이동 규칙: 빈 칸에 아무 카드 1장.
    public static func canMoveToFreeCell(current: Card?) -> Bool {
        current == nil
    }

    /// 타블로 열 맨 아래(bottom)에서 연속된 내림차순+교대색(프리셀/슈퍼) 또는 같은 수트(Baker's/Sea Tower) 시퀀스 추출
    /// (bottom → top 방향으로 랭크가 1씩 증가, 색 교대 또는 같은 수트). 반환 순서: top → bottom.
    public static func movableRun(from column: [Card], variant: GameVariant = .freecell) -> [Card] {
        var run: [Card] = []
        for card in column.reversed() {
            if run.isEmpty {
                run.append(card)
            } else if let top = run.last,
                      card.rank == top.rank.next {
                let sameColorRule: Bool
                switch variant {
                case .freecell, .klondike, .superFreeCell, .yukon: sameColorRule = card.color != top.color
                case .bakersGame, .seaTower, .fortyThieves: sameColorRule = card.suit == top.suit
                case .spider: sameColorRule = true
                case .golf, .pyramid, .triPeaks: sameColorRule = false
                }
                if sameColorRule {
                    run.append(card)
                } else {
                    break
                }
            } else {
                break
            }
        }
        return Array(run.reversed())
    }

    /// 수퍼무브 용량: (빈 프리셀 수 + 1) × 2^(빈 열 수)
    /// 목적지가 빈 열이면 그 열은 임시 저장으로 사용 불가 → 제외
    public static func supermoveCapacity(
        emptyFreeCells: Int,
        emptyColumns: Int,
        destinationIsEmpty: Bool
    ) -> Int {
        let free = max(0, emptyFreeCells)
        var columns = max(0, emptyColumns)
        if destinationIsEmpty && columns > 0 {
            columns -= 1
        }
        return (free + 1) << columns
    }
}
