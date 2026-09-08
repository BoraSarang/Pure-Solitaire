import SwiftUI
import GameCore

/// 미니 보드 레이아웃 종류
enum GamePreviewKind {
    case columns
    case pyramid
    case triPeaks
}

/// 게임별 미니 보드 레이아웃 디스크립터 — 게임 클래스 static 상수 재사용 (중복 없음, 새 게임 자동 확장)
struct GamePreviewLayout {
    let kind: GamePreviewKind
    let columns: Int
    let homes: Int
    let freeCells: Int
    let hasStock: Bool
    let hasWaste: Bool
    let hasFaceDown: Bool
    let stockPiles: Int

    static func layout(for variant: GameVariant) -> GamePreviewLayout {
        switch variant {
        case .freecell, .bakersGame, .seaTower, .superFreeCell:
            return GamePreviewLayout(
                kind: .columns,
                columns: FreeCellGame.columnCount(for: variant),
                homes: FreeCellGame.homeCount,
                freeCells: FreeCellGame.freeCellCount(for: variant),
                hasStock: false,
                hasWaste: false,
                hasFaceDown: false,
                stockPiles: 0
            )
        case .klondike:
            return GamePreviewLayout(
                kind: .columns,
                columns: KlondikeGame.columnCount,
                homes: KlondikeGame.homeCount,
                freeCells: 0,
                hasStock: true,
                hasWaste: true,
                hasFaceDown: true,
                stockPiles: 0
            )
        case .spider:
            return GamePreviewLayout(
                kind: .columns,
                columns: SpiderGame.columnCount,
                homes: 0,
                freeCells: 0,
                hasStock: true,
                hasWaste: false,
                hasFaceDown: true,
                stockPiles: 5
            )
        case .yukon:
            return GamePreviewLayout(
                kind: .columns,
                columns: YukonGame.columnCount,
                homes: YukonGame.homeCount,
                freeCells: 0,
                hasStock: false,
                hasWaste: false,
                hasFaceDown: true,
                stockPiles: 0
            )
        case .fortyThieves:
            return GamePreviewLayout(
                kind: .columns,
                columns: FortyThievesGame.columnCount,
                homes: FortyThievesGame.homeCount,
                freeCells: 0,
                hasStock: true,
                hasWaste: true,
                hasFaceDown: false,
                stockPiles: 0
            )
        case .golf:
            return GamePreviewLayout(
                kind: .columns,
                columns: GolfGame.columnCount,
                homes: 0,
                freeCells: 0,
                hasStock: true,
                hasWaste: true,
                hasFaceDown: false,
                stockPiles: 0
            )
        case .pyramid:
            return GamePreviewLayout(
                kind: .pyramid,
                columns: 0,
                homes: 0,
                freeCells: 0,
                hasStock: true,
                hasWaste: true,
                hasFaceDown: false,
                stockPiles: 0
            )
        case .triPeaks:
            return GamePreviewLayout(
                kind: .triPeaks,
                columns: 0,
                homes: 0,
                freeCells: 0,
                hasStock: true,
                hasWaste: true,
                hasFaceDown: false,
                stockPiles: 0
            )
        case .scorpion:
            return GamePreviewLayout(
                kind: .columns,
                columns: ScorpionGame.columnCount,
                homes: 0,
                freeCells: 0,
                hasStock: true,
                hasWaste: false,
                hasFaceDown: true,
                stockPiles: 1
            )
        }
    }
}

/// 게임 대표 미니 보드 미리보기 카드 — 카드 타일 안에 해당 게임의 보드 배치를 축소 렌더
struct GamePreviewCard: View {
    let variant: GameVariant
    let isSelected: Bool
    let boardColor: Color

    private var layout: GamePreviewLayout {
        .layout(for: variant)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let board = boardRect(w: w, h: h)
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.08)
                    .fill(Color.white)
                RoundedRectangle(cornerRadius: w * 0.08)
                    .stroke(
                        isSelected ? Color.blue : Color(red: 0.62, green: 0.62, blue: 0.62),
                        lineWidth: isSelected ? 3 : 1
                    )
                RoundedRectangle(cornerRadius: w * 0.045)
                    .fill(boardColor)
                    .frame(width: board.width, height: board.height)
                    .position(x: board.midX, y: board.midY)
                MiniBoard(layout: layout)
                    .frame(width: board.width, height: board.height)
                    .position(x: board.midX, y: board.midY)
            }
        }
        .aspectRatio(0.7, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(variant.displayName) 게임, \(isSelected ? "선택됨" : "선택 안 됨")")
    }

    private func boardRect(w: CGFloat, h: CGFloat) -> CGRect {
        let inset = w * 0.08
        return CGRect(x: inset, y: inset, width: w - inset * 2, height: h - inset * 2)
    }
}

// MARK: - 미니 보드 렌더

private enum SlotKind {
    case home
    case freeCell
    case stock
    case waste
    case completed
}

private struct MiniBoard: View {
    let layout: GamePreviewLayout

    var body: some View {
        GeometryReader { geo in
            let bw = geo.size.width
            let bh = geo.size.height
            let gap: CGFloat = 2
            ZStack(alignment: .topLeading) {
                switch layout.kind {
                case .columns:
                    columnsLayout(bw: bw, bh: bh, gap: gap)
                case .pyramid:
                    pyramidLayout(bw: bw, gap: gap)
                case .triPeaks:
                    triPeaksLayout(bw: bw, gap: gap)
                }
            }
        }
    }

    // MARK: - 열 기반 게임 (FreeCell 계열/Klondike/Spider/Yukon/FortyThieves/Golf)

    private var leftSlots: [SlotKind] {
        if layout.hasStock {
            var arr: [SlotKind] = Array(repeating: .stock, count: layout.stockPiles > 0 ? layout.stockPiles : 1)
            if layout.hasWaste { arr.append(.waste) }
            return arr
        }
        if layout.homes > 0 {
            return Array(repeating: .home, count: layout.homes)
        }
        return []
    }

    private var rightSlots: [SlotKind] {
        var arr: [SlotKind] = []
        if layout.freeCells > 0 {
            arr.append(contentsOf: Array(repeating: .freeCell, count: layout.freeCells))
        }
        if layout.homes > 0 && (layout.hasStock || layout.hasWaste) {
            arr.append(contentsOf: Array(repeating: .home, count: layout.homes))
        }
        if layout.stockPiles > 0 {
            arr.append(.completed)
        }
        return arr
    }

    @ViewBuilder
    private func columnsLayout(bw: CGFloat, bh: CGFloat, gap: CGFloat) -> some View {
        let topSlots = max(leftSlots.count + rightSlots.count, layout.columns)
        let sw = (bw - CGFloat(topSlots - 1) * gap) / CGFloat(topSlots)
        let ch = sw / 0.7
        let rightWidth = CGFloat(rightSlots.count) * sw + CGFloat(max(rightSlots.count - 1, 0)) * gap

        slotsRow(leftSlots, startX: 0, y: 2, sw: sw, ch: ch, gap: gap)
        slotsRow(rightSlots, startX: bw - rightWidth, y: 2, sw: sw, ch: ch, gap: gap)
        columnsContent(sw: sw, ch: ch, topY: 2 + ch + 4, bh: bh, gap: gap)
    }

    @ViewBuilder
    private func columnsContent(sw: CGFloat, ch: CGFloat, topY: CGFloat, bh: CGFloat, gap: CGFloat) -> some View {
        let step = ch * 0.5
        let avail = bh - topY - 2
        let count = max(2, min(7, Int((avail - ch) / step) + 1))
        ForEach(0..<layout.columns, id: \.self) { col in
            let x = CGFloat(col) * (sw + gap)
            ForEach(0..<count, id: \.self) { k in
                let y = bh - 2 - ch - CGFloat(k) * step
                MiniCard(
                    faceDown: layout.hasFaceDown && k > 0,
                    suit: suitFor(col + k * layout.columns)
                )
                .frame(width: sw, height: ch)
                .position(x: x + sw / 2, y: y + ch / 2)
            }
        }
    }

    // MARK: - 피라미드 (Pyramid)

    @ViewBuilder
    private func pyramidLayout(bw: CGFloat, gap: CGFloat) -> some View {
        let rows = 7
        let pw = bw * 0.108
        let ph = pw / 0.7
        let step = ph * 0.76
        let centerX = bw / 2
        ForEach(0..<rows, id: \.self) { r in
            let count = r + 1
            let totalW = CGFloat(count) * pw + CGFloat(count - 1) * gap
            let startX = centerX - totalW / 2
            ForEach(0..<count, id: \.self) { c in
                MiniCard(faceDown: false, suit: suitFor(r * count + c))
                    .frame(width: pw, height: ph)
                    .position(x: startX + pw / 2 + CGFloat(c) * (pw + gap), y: 2 + CGFloat(r) * step + ph / 2)
            }
        }
    }

    // MARK: - 트리피크 (TriPeaks)

    @ViewBuilder
    private func triPeaksLayout(bw: CGFloat, gap: CGFloat) -> some View {
        let rows = TriPeaksGame.rowsPerPeak
        let pw = bw * 0.078
        let ph = pw / 0.7
        let step = ph * 0.76
        let centers: [CGFloat] = [0.21, 0.5, 0.79]
        ForEach(0..<3, id: \.self) { p in
            let centerX = bw * centers[p]
            let topY = 2 + CGFloat(p == 1 ? 0 : 1) * step * 1.05
            ForEach(0..<rows, id: \.self) { r in
                let count = r + 1
                let totalW = CGFloat(count) * pw + CGFloat(count - 1) * gap
                let startX = centerX - totalW / 2
                ForEach(0..<count, id: \.self) { c in
                    MiniCard(faceDown: false, suit: suitFor(p * 10 + r * count + c))
                        .frame(width: pw, height: ph)
                        .position(x: startX + pw / 2 + CGFloat(c) * (pw + gap), y: topY + CGFloat(r) * step + ph / 2)
                }
            }
        }
    }

    // MARK: - 공용 요소

    @ViewBuilder
    private func slotsRow(_ kinds: [SlotKind], startX: CGFloat, y: CGFloat, sw: CGFloat, ch: CGFloat, gap: CGFloat) -> some View {
        ForEach(Array(kinds.enumerated()), id: \.offset) { index, kind in
            slotView(kind)
                .frame(width: sw, height: ch)
                .position(x: startX + sw / 2 + CGFloat(index) * (sw + gap), y: y + ch / 2)
        }
    }

    @ViewBuilder
    private func slotView(_ kind: SlotKind) -> some View {
        switch kind {
        case .stock:
            MiniCard(faceDown: true)
        case .waste:
            MiniCard(faceDown: false, suit: .hearts)
        case .home, .freeCell, .completed:
            MiniSlot()
        }
    }

    private func suitFor(_ index: Int) -> Suit {
        let all: [Suit] = [.hearts, .spades, .diamonds, .clubs]
        return all[abs(index) % 4]
    }
}

/// 미니 카드 (앞면: 흰 바탕 + 무늬, 뒷면: 회색)
private struct MiniCard: View {
    var faceDown = false
    var suit: Suit = .spades

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: s * 0.12)
                    .fill(faceDown ? Color(red: 0.32, green: 0.34, blue: 0.44) : Color.white)
                if !faceDown {
                    SuitSymbolView(suit: suit)
                        .frame(width: s * 0.55, height: s * 0.55)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: s * 0.12)
                    .stroke(
                        faceDown
                            ? Color.white.opacity(0.35)
                            : suit.uiColor,
                        lineWidth: 0.7
                    )
            )
        }
    }
}

/// 미니 빈 슬롯 (홈셀/프리셀/완성 수트)
private struct MiniSlot: View {
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            RoundedRectangle(cornerRadius: s * 0.12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: s * 0.12)
                        .strokeBorder(Color.white.opacity(0.55), style: StrokeStyle(lineWidth: 0.8, dash: [2, 2]))
                )
        }
    }
}
