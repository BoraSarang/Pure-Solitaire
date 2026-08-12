/// 게임 번호 기반 마이크로소프트 딜 생성기
public enum DealGenerator {
    public static let minGameNumber = 1
    public static let maxGameNumber = 1_000_000

    /// 게임 번호로 셔플된 52장 카드 (딜 순서)
    ///
    /// 마이크로소프트 알고리즘:
    /// 1. RNG 시드 = 게임 번호
    /// 2. 배열 [51, 50, ..., 0] 준비
    /// 3. i = 0..50: j = 51 - (rand % (52 - i)), swap(i, j)
    public static func shuffledCards(gameNumber: Int) -> [Card] {
        var rng = MicrosoftRNG(seed: gameNumber)
        var cards = (0..<52).map { Card(rawValue: 51 - $0) }
        for i in 0..<51 {
            let j = 51 - (rng.next() % (52 - i))
            cards.swapAt(i, j)
        }
        return cards
    }

    /// 8개 타블로 열로 딜 (왼→오 교대로 1장씩)
    /// 첫 4열 7장, 다음 4열 6장
    public static func deal(gameNumber: Int) -> [[Card]] {
        let shuffled = shuffledCards(gameNumber: gameNumber)
        var columns = Array(repeating: [Card](), count: 8)
        for (index, card) in shuffled.enumerated() {
            columns[index % 8].append(card)
        }
        return columns
    }

    /// 딜을 검증용 문자열로 출력 (랭크+무늬, 8개씩 줄바꿈)
    public static func dealString(gameNumber: Int) -> String {
        let shuffled = shuffledCards(gameNumber: gameNumber)
        return shuffled.map { $0.shortDescription }
            .enumerated()
            .reduce(into: "") { result, pair in
                result += pair.element
                result += (pair.offset + 1) % 8 == 0 ? "\n" : " "
            }
    }

    /// Spider용 104장 덱(2덱)을 게임 번호로 셔플
    ///
    /// - 수트 구성: suitCount가 1이면 스페이드 8세트, 2면 스페이드/하트 4세트씩,
    ///   4면 전 수트 2세트씩 → 항상 104장.
    /// - 셔플은 마이크로소프트 방식(RNG 시드 = 게임 번호)을 재사용.
    public static func spiderCards(gameNumber: Int, suitCount: Int) -> [Card] {
        let suits: [Suit]
        switch suitCount {
        case 1: suits = [.spades]
        case 2: suits = [.spades, .hearts]
        default: suits = Suit.allCases
        }
        let copies = 104 / (13 * suits.count)
        var deck: [Card] = []
        for suit in suits {
            for _ in 0..<copies {
                for rank in Rank.allCases {
                    deck.append(Card(suit: suit, rank: rank))
                }
            }
        }
        var rng = MicrosoftRNG(seed: gameNumber)
        for i in 0..<(deck.count - 1) {
            let j = (deck.count - 1) - (rng.next() % (deck.count - i))
            deck.swapAt(i, j)
        }
        return deck
    }

    /// Sea Tower 딜: 52장 셔플 → 10열에 교대로 50장(각 5장), 나머지 2장은 프리셀 배치용.
    /// 반환: (columns: [[Card]], freeCellStarts: [Card]) — freeCellStarts는 2장(프리셀 0, 1에 배치).
    public static func seaTowerDeal(gameNumber: Int) -> (columns: [[Card]], freeCellStarts: [Card]) {
        let shuffled = shuffledCards(gameNumber: gameNumber)
        var columns = Array(repeating: [Card](), count: 10)
        for (index, card) in shuffled.prefix(50).enumerated() {
            columns[index % 10].append(card)
        }
        let freeCellStarts = Array(shuffled.suffix(2))
        return (columns, freeCellStarts)
    }

    /// Super FreeCell 딜: 2덱 104장 셔플 → 10열에 교대로 배치.
    /// (52장 1덱을 두 번 만들지 않고 2덱 전체를 한 번에 셔플) — 열별 11/11/11/11/10×6.
    public static func superFreeCellDeal(gameNumber: Int) -> [[Card]] {
        var rng = MicrosoftRNG(seed: gameNumber)
        var deck: [Card] = []
        for _ in 0..<2 {
            for raw in 0..<52 {
                deck.append(Card(rawValue: raw))
            }
        }
        for i in 0..<(deck.count - 1) {
            let j = (deck.count - 1) - (rng.next() % (deck.count - i))
            deck.swapAt(i, j)
        }
        var columns = Array(repeating: [Card](), count: 10)
        for (index, card) in deck.enumerated() {
            columns[index % 10].append(card)
        }
        return columns
    }

    /// Forty Thieves 딜: 2덱 104장 셔플 → 10열에 교대로 4장씩(40장, 전부 앞면), 나머지 64장은 스톡.
    /// 반환: (columns: [[Card]], stock: [Card])
    public static func fortyThievesDeal(gameNumber: Int) -> (columns: [[Card]], stock: [Card]) {
        var rng = MicrosoftRNG(seed: gameNumber)
        var deck: [Card] = []
        for _ in 0..<2 {
            for raw in 0..<52 {
                deck.append(Card(rawValue: raw))
            }
        }
        for i in 0..<(deck.count - 1) {
            let j = (deck.count - 1) - (rng.next() % (deck.count - i))
            deck.swapAt(i, j)
        }
        var columns = Array(repeating: [Card](), count: 10)
        for (index, card) in deck.prefix(40).enumerated() {
            columns[index % 10].append(card)
        }
        let stock = Array(deck.suffix(64))
        return (columns, stock)
    }

    /// Golf 딜: 52장 셔플 → 7열에 교대로 5장씩(35장, 전부 앞면), 나머지 17장은 스톡 16장 + 웨이스트 1장.
    /// 반환: (columns: [[Card]], stock: [Card], waste: [Card])
    public static func golfDeal(gameNumber: Int) -> (columns: [[Card]], stock: [Card], waste: [Card]) {
        let shuffled = shuffledCards(gameNumber: gameNumber)
        var columns = Array(repeating: [Card](), count: 7)
        for (index, card) in shuffled.prefix(35).enumerated() {
            columns[index % 7].append(card)
        }
        let stock = Array(shuffled[35..<51])
        let waste = Array(shuffled.suffix(1))
        return (columns, stock, waste)
    }

    /// Pyramid 딜: 52장 셔플 → 앞 28장은 피라미드(7줄, 글로벌 인덱스 순서로), 뒤 24장은 스톡.
    /// 피라미드 배치 순서: row0=인덱스0, row1=1~2, row2=3~5, ... row6=21~27.
    /// 반환: (pyramid: [Card], stock: [Card])
    public static func pyramidDeal(gameNumber: Int) -> (pyramid: [Card], stock: [Card]) {
        let shuffled = shuffledCards(gameNumber: gameNumber)
        let pyramid = Array(shuffled.prefix(28))
        let stock = Array(shuffled.suffix(24))
        return (pyramid, stock)
    }

    /// TriPeaks 딜: 52장 셔플 → 앞 30장은 3개 피크(각 4줄: 1+2+3+4, 피크별 글로벌 인덱스 순서),
    /// 그다음 1장은 웨이스트(딜 시 오픈), 뒤 21장은 스톡.
    /// 반환: (peaks: [Card], stock: [Card], waste: [Card])
    public static func triPeaksDeal(gameNumber: Int) -> (peaks: [Card], stock: [Card], waste: [Card]) {
        let shuffled = shuffledCards(gameNumber: gameNumber)
        let peaks = Array(shuffled.prefix(30))
        let waste = [shuffled[30]]
        let stock = Array(shuffled[31..<52])
        return (peaks, stock, waste)
    }

    /// Yukon 딜: 52장 셔플 → 7열 배치.
    /// 열0 = 1장(앞면), 열1~6 = 5장(뒤집힘)+각각 1~6장(앞면) → 합 52장.
    /// 스톡/웨이스트 없음 — 전부 타블로에 배치.
    public static func yukonDeal(gameNumber: Int) -> [[KlondikeGame.ColumnCard]] {
        let shuffled = shuffledCards(gameNumber: gameNumber)
        var columns = Array(repeating: [KlondikeGame.ColumnCard](), count: 7)
        var index = 0
        // 열0: 1장 앞면
        columns[0].append(KlondikeGame.ColumnCard(card: shuffled[index], faceUp: true))
        index += 1
        // 열1~6: 뒤집힌 5장 + 앞면 (col)장
        for col in 1..<7 {
            var pile: [KlondikeGame.ColumnCard] = []
            for _ in 0..<5 {
                pile.append(KlondikeGame.ColumnCard(card: shuffled[index], faceUp: false))
                index += 1
            }
            for _ in 0..<col {
                pile.append(KlondikeGame.ColumnCard(card: shuffled[index], faceUp: true))
                index += 1
            }
            columns[col] = pile
        }
        return columns
    }

    /// Scorpion 딜: 52장 셔플 → 7열 × 7장(49장) + 예비 3장.
    /// 앞 4열(0~3): 밑 3장 뒤집힘 + 위 4장 앞면 / 뒤 3열(4~6): 전부 앞면.
    /// 반환: (columns: [[ColumnCard]], reserve: [Card])
    public static func scorpionDeal(gameNumber: Int) -> (columns: [[KlondikeGame.ColumnCard]], reserve: [Card]) {
        let shuffled = shuffledCards(gameNumber: gameNumber)
        var columns = Array(repeating: [KlondikeGame.ColumnCard](), count: 7)
        var index = 0
        for col in 0..<7 {
            var pile: [KlondikeGame.ColumnCard] = []
            let faceDownCount = col < 4 ? 3 : 0
            for _ in 0..<faceDownCount {
                pile.append(KlondikeGame.ColumnCard(card: shuffled[index], faceUp: false))
                index += 1
            }
            for _ in faceDownCount..<7 {
                pile.append(KlondikeGame.ColumnCard(card: shuffled[index], faceUp: true))
                index += 1
            }
            columns[col] = pile
        }
        let reserve = Array(shuffled[index...])
        return (columns, reserve)
    }
}
