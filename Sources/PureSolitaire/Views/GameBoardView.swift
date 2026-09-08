import SwiftUI
import GameCore

struct GameBoardView: View {
    @EnvironmentObject private var vm: FreeCellViewModel
    @EnvironmentObject private var settings: UserSettings
    @State private var drag: DragState?
    @State private var lastTapAt: Date?
    @State private var lastTapIdentifier: String?
    @State private var hintGeometry: HintDragGeometry?
    @State private var hintDragPosition: CGPoint?
    @State private var hintDragTask: Task<Void, Never>?

    private let overlapFactor: CGFloat = 0.42

    private var columnCount: Int {
        if vm.spider != nil { return SpiderGame.columnCount }
        if vm.klondike != nil { return KlondikeGame.columnCount }
        if vm.yukon != nil { return YukonGame.columnCount }
        if vm.fortyThieves != nil { return FortyThievesGame.columnCount }
        if vm.golf != nil { return GolfGame.columnCount }
        if vm.scorpion != nil { return ScorpionGame.columnCount }
        return FreeCellGame.columnCount(for: vm.game.variant)
    }

    private var freeCellCount: Int {
        FreeCellGame.freeCellCount(for: vm.game.variant)
    }

    var body: some View {
        GeometryReader { geo in
            let size = cardSize(for: geo)
            let step = effectiveStep(cardSize: size, boardSize: geo.size)
            let overlap = size.height - step
            ZStack {
                VStack(spacing: 10) {
                    topRow(cardSize: size)
                        .frame(height: size.height * 1.3)
                    if vm.pyramid == nil && vm.triPeaks == nil {
                        columnsRow(cardSize: size, overlap: overlap, boardSize: geo.size)
                            .frame(maxHeight: .infinity)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                .allowsHitTesting(false)

                if vm.pyramid != nil {
                    pyramidBody(cardSize: size, boardSize: geo.size)
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                        .zIndex(5)
                        .allowsHitTesting(false)
                } else if vm.triPeaks != nil {
                    triPeaksBody(cardSize: size, boardSize: geo.size)
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                        .zIndex(5)
                        .allowsHitTesting(false)
                }

                if let drag {
                    dragOverlay(drag, cardSize: size, boardSize: geo.size)
                        .zIndex(100)
                }
                hintDragOverlay(cardSize: size, boardSize: geo.size)
                    .zIndex(90)

                // 자동 풀어 보기/리플레이 재생 오버레이 — 재생 중 조작 잠금 + 진행 표시
                if vm.isAutoSolving || vm.isReplaying {
                    PlaybackOverlayView()
                        .zIndex(200)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .allowsHitTesting(true)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                if vm.isAutoSolving || vm.isReplaying { return }
                if case .active(let loc) = phase {
                    drag?.location = loc
                }
            }
            .gesture(
                vm.isAutoSolving || vm.isReplaying
                    ? DragGesture().onChanged { _ in }.onEnded { _ in }
                    : DragGesture(minimumDistance: 2)
                        .onChanged { value in
                            if drag == nil {
                                cancelHintDrag()
                                guard let hit = dragSource(at: value.location, boardSize: geo.size, cardSize: size) else { return }
                                let grabPoint = cardBoardOrigin(hit.source, topIndex: hit.topIndex, cardSize: size, boardSize: geo.size)
                                drag = DragState(
                                    source: hit.source,
                                    cardCount: hit.cardCount,
                                    topIndex: hit.topIndex,
                                    startLocation: value.location,
                                    location: value.location,
                                    startCardOrigin: grabPoint
                                )
                            } else {
                                drag?.location = value.location
                            }
                        }
                        .onEnded { _ in
                            finishDrag(boardSize: geo.size, cardSize: size)
                        }
            )
            .simultaneousGesture(
                SpatialTapGesture(count: 1).onEnded { value in
                    guard !(vm.isAutoSolving || vm.isReplaying) else { return }
                    handleBoardTap(at: value.location, boardSize: geo.size, cardSize: size)
                }
            )
            .onChange(of: vm.hintAnimationTick) { _ in
                runHintDragAnimation(boardSize: geo.size, cardSize: size)
            }
        }
        .background(BackgroundLayer(settings: settings))
        .animation(.easeInOut(duration: settings.animationSpeed), value: vm.game)
        .animation(.easeInOut(duration: settings.animationSpeed), value: vm.klondike)
        .animation(.easeInOut(duration: settings.animationSpeed), value: vm.spider)
        .animation(.easeInOut(duration: settings.animationSpeed), value: vm.yukon)
        .animation(.easeInOut(duration: settings.animationSpeed), value: vm.fortyThieves)
        .animation(.easeInOut(duration: settings.animationSpeed), value: vm.golf)
        .animation(.easeInOut(duration: settings.animationSpeed), value: vm.pyramid)
        .animation(.easeInOut(duration: settings.animationSpeed), value: vm.triPeaks)
        .animation(.easeInOut(duration: settings.animationSpeed), value: vm.scorpion)
    }

    // MARK: - 크기 계산

    private func cardSize(for geo: GeometryProxy) -> CGSize {
        let maxStackFactor = 1.0 + Double(12) * Double(overlapFactor)
        let colFactor: CGFloat
        if vm.spider != nil {
            colFactor = 10.7
        } else if vm.klondike != nil || vm.yukon != nil {
            colFactor = 7.7
        } else if vm.fortyThieves != nil {
            colFactor = 10.7
        } else if vm.golf != nil {
            colFactor = 7.7
        } else if vm.scorpion != nil {
            colFactor = 7.7
        } else if vm.pyramid != nil {
            colFactor = 10.7
        } else if vm.triPeaks != nil {
            colFactor = 19.5
        } else if vm.game.variant == .seaTower || vm.game.variant == .superFreeCell {
            colFactor = 10.7
        } else {
            colFactor = 8.7
        }
        let widthLimited = (geo.size.width / colFactor) / 0.7
        let heightLimited = (geo.size.height - 50) / (maxStackFactor + 1.3 + 0.45)
        let cardHeight = min(widthLimited, heightLimited) * settings.boardScale
        return CGSize(width: cardHeight * 0.7, height: cardHeight)
    }

    /// 열 게임에서 현재 가장 긴 열의 카드 수 (Pyramid/TriPeaks는 열 없음 → 0)
    private func maxColumnCards() -> Int {
        var maxCount = 0
        if let s = vm.spider {
            maxCount = s.columns.map(\.count).max() ?? 0
        } else if let k = vm.klondike {
            maxCount = k.columns.map(\.count).max() ?? 0
        } else if let y = vm.yukon {
            maxCount = y.columns.map(\.count).max() ?? 0
        } else if let f = vm.fortyThieves {
            maxCount = f.columns.map(\.count).max() ?? 0
        } else if let g = vm.golf {
            maxCount = g.columns.map(\.count).max() ?? 0
        } else if let s = vm.scorpion {
            maxCount = s.columns.map(\.count).max() ?? 0
        } else if vm.pyramid == nil && vm.triPeaks == nil {
            maxCount = vm.game.columns.map(\.count).max() ?? 0
        }
        return maxCount
    }

    /// 열 카드의 유효 세로 간격(step). 카드가 화면을 넘으면 겹침을 늘려(step 축소) 화면에 맞춘다.
    /// - 기본: 겹침 0.42 (baseStep = cardH*0.58)
    /// - 최대 겹침 70% (minStep = cardH*0.30)
    /// - 열 렌더/드래그/오버레이 좌표계가 모두 동일한 step을 쓰도록 중앙에서 계산한다.
    private func effectiveStep(cardSize: CGSize, boardSize: CGSize) -> CGFloat {
        let baseStep = cardSize.height * (1 - overlapFactor)
        let maxCards = max(maxColumnCards(), 2)
        let availableH = boardSize.height - cardSize.height * 2.3 - 24
        let fitStep = (availableH - cardSize.height) / CGFloat(maxCards - 1)
        let minStep = cardSize.height * 0.30
        return max(minStep, min(baseStep, fitStep))
    }

    // MARK: - 상단 행

    private func topRow(cardSize: CGSize) -> some View {
        ZStack {
            if vm.spider != nil {
                spiderTopRow(cardSize: cardSize)
            } else if vm.klondike != nil {
                klondikeTopRow(cardSize: cardSize)
            } else if vm.yukon != nil {
                yukonTopRow(cardSize: cardSize)
            } else if vm.fortyThieves != nil {
                fortyThievesTopRow(cardSize: cardSize)
            } else if vm.golf != nil {
                golfTopRow(cardSize: cardSize)
            } else if vm.pyramid != nil {
                pyramidTopRow(cardSize: cardSize)
            } else if vm.triPeaks != nil {
                triPeaksTopRow(cardSize: cardSize)
            } else if vm.scorpion != nil {
                scorpionTopRow(cardSize: cardSize)
            } else {
                HStack(spacing: 2) {
                    HStack(spacing: 2) {
                        ForEach(0..<FreeCellGame.homeCount, id: \.self) { i in
                            homeCell(i, cardSize: cardSize)
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("홈셀")
                    Spacer()
                    if vm.game.variant == .freecell || vm.game.variant == .seaTower || vm.game.variant == .superFreeCell {
                        HStack(spacing: 2) {
                            ForEach(0..<freeCellCount, id: \.self) { i in
                                freeCell(i, cardSize: cardSize)
                            }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("프리셀")
                    }
                }
            }
            gameInfoView
        }
    }

    /// Yukon 상단 행: 홈셀 4개 (스톡/웨이스트/프리셀 없음)
    private func yukonTopRow(cardSize: CGSize) -> some View {
        let gap: CGFloat = 2
        return ZStack {
            HStack(spacing: gap) {
                ForEach(0..<YukonGame.homeCount, id: \.self) { i in
                    yukonHomeCell(i, cardSize: cardSize)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("홈셀")
    }

    private func yukonHomeCell(_ index: Int, cardSize: CGSize) -> some View {
        let last = vm.yukon?.homes[index].last
        return CardView(
            card: last,
            style: settings.cardStyle,
            isHintSource: isYukonHomeHintSource(index),
            isPulsing: last == vm.lastHomeCard,
            accessibilityHintText: "홈셀"
        )
        .frame(width: cardSize.width, height: cardSize.height)
        .onTapGesture { vm.tapYukonHome(index) }
    }

    /// 힌트 하이라이트 소스(홈) 여부 — Yukon (해당 수트 홈셀만)
    private func isYukonHomeHintSource(_ index: Int) -> Bool {
        vm.displayedHintMoves.contains { move in
            switch move {
            case let .columnToHome(_, card):
                return vm.yukon?.homes[index].last?.suit == card.suit
            default:
                return false
            }
        }
    }

    /// Forty Thieves 상단 행: 스톡 + 웨이스트(좌), 홈셀 8개(우)
    private func fortyThievesTopRow(cardSize: CGSize) -> some View {
        let gap: CGFloat = 2
        return ZStack {
            HStack(spacing: gap) {
                fortyThievesStockView(cardSize: cardSize)
                fortyThievesWasteView(cardSize: cardSize)
                Spacer()
            }
            HStack(spacing: gap) {
                ForEach(0..<FortyThievesGame.homeCount, id: \.self) { i in
                    fortyThievesHomeCell(i, cardSize: cardSize)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("스톡, 웨이스트, 홈셀")
    }

    /// Forty Thieves 스톡: 카드가 있으면 뒷면 묶음, 없으면 빈 슬롯 (재활용 없음)
    private func fortyThievesStockView(cardSize: CGSize) -> some View {
        let hasStock = !(vm.fortyThieves?.stock.isEmpty ?? true)
        return CardView(
            card: Card(suit: .spades, rank: .ace),
            style: settings.cardStyle,
            isHighlighted: true,
            showBack: true,
            cardBack: settings.cardBack,
            accessibilityHintText: "누르면 1장 드로"
        )
        .opacity(hasStock ? 1 : 0.35)
        .frame(width: cardSize.width, height: cardSize.height)
        .onTapGesture { vm.tapFortyThievesStock() }
        .contentShape(Rectangle())
    }

    private func fortyThievesWasteView(cardSize: CGSize) -> some View {
        let wasteCard = vm.fortyThieves?.waste.last
        return CardView(
            card: wasteCard,
            style: settings.cardStyle,
            isHighlighted: true,
            isSelected: vm.selection?.source == .waste,
            accessibilityHintText: "누르면 선택, 두 번 누르면 홈셀로 이동"
        )
        .frame(width: cardSize.width, height: cardSize.height)
        .onTapGesture {
            handleFortyThievesWasteTap()
        }
        .contentShape(Rectangle())
    }

    private func handleFortyThievesWasteTap() {
        handleTap(identifier: "ft-waste") {
            vm.tapFortyThievesWaste()
        } double: {
            _ = vm.doubleClickFortyThievesWaste()
        }
    }

    private func fortyThievesHomeCell(_ index: Int, cardSize: CGSize) -> some View {
        let last = vm.fortyThieves?.homes[index].last
        return CardView(
            card: last,
            style: settings.cardStyle,
            isHighlighted: true,
            isHintSource: isFortyThievesHomeHintSource(index),
            isPulsing: last == vm.lastHomeCard,
            accessibilityHintText: "누르면 선택 카드 이동"
        )
        .frame(width: cardSize.width, height: cardSize.height)
        .onTapGesture { vm.tapFortyThievesHome(index) }
    }

    /// 힌트 하이라이트 소스(홈) 여부 — Forty Thieves (해당 수트 홈셀만)
    private func isFortyThievesHomeHintSource(_ index: Int) -> Bool {
        vm.displayedHintMoves.contains { move in
            switch move {
            case let .columnToHome(_, card):
                return vm.fortyThieves?.homes[index].last?.suit == card.suit
            default:
                return false
            }
        }
    }

    /// Golf 상단 행: 스톡 + 웨이스트(좌) — 홈셀 없음
    private func golfTopRow(cardSize: CGSize) -> some View {
        let gap: CGFloat = 2
        return ZStack {
            HStack(spacing: gap) {
                golfStockView(cardSize: cardSize)
                golfWasteView(cardSize: cardSize)
                Spacer()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("스톡, 웨이스트")
    }

    /// Golf 스톡: 카드가 있으면 뒷면 묶음, 없으면 빈 슬롯 (재활용 없음)
    private func golfStockView(cardSize: CGSize) -> some View {
        let hasStock = !(vm.golf?.stock.isEmpty ?? true)
        return CardView(
            card: Card(suit: .spades, rank: .ace),
            style: settings.cardStyle,
            isHighlighted: true,
            showBack: true,
            cardBack: settings.cardBack,
            accessibilityHintText: "누르면 1장 드로"
        )
        .opacity(hasStock ? 1 : 0.35)
        .frame(width: cardSize.width, height: cardSize.height)
        .onTapGesture { vm.tapGolfStock() }
        .contentShape(Rectangle())
    }

    /// Golf 웨이스트: 기준 카드 (드로/제거로 갱신, 탭 동작 없음)
    private func golfWasteView(cardSize: CGSize) -> some View {
        let wasteCard = vm.golf?.waste.last
        return CardView(
            card: wasteCard,
            style: settings.cardStyle,
            isHighlighted: true,
            accessibilityHintText: "기준 카드 — 이 카드와 1 차이/같은 랭크 카드 제거"
        )
        .frame(width: cardSize.width, height: cardSize.height)
        .contentShape(Rectangle())
    }

    // MARK: - Pyramid 뷰

    /// Pyramid 상단 행: 스톡 + 웨이스트(좌) — 홈셀 없음
    private func pyramidTopRow(cardSize: CGSize) -> some View {
        let gap: CGFloat = 2
        return ZStack {
            HStack(spacing: gap) {
                pyramidStockView(cardSize: cardSize)
                pyramidWasteView(cardSize: cardSize)
                Spacer()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("스톡, 웨이스트")
    }

    /// Pyramid 스톡: 카드가 있으면 뒷면 묶음(드로), 스톡 비고 재활용 가능이면 유턴 표시, 소진 후엔 빈 슬롯
    private func pyramidStockView(cardSize: CGSize) -> some View {
        let hasStock = !(vm.pyramid?.stock.isEmpty ?? true)
        let canRecycle = (vm.pyramid?.waste.isEmpty == false) && (vm.pyramid?.didRecycle == false)
        return CardView(
            card: Card(suit: .spades, rank: .ace),
            style: settings.cardStyle,
            isHighlighted: true,
            showBack: true,
            cardBack: settings.cardBack,
            accessibilityHintText: hasStock ? "누르면 1장 드로"
                : (canRecycle ? "누르면 1회 재활용" : "재활용 소진 — 드로 불가")
        )
        .opacity(hasStock ? 1 : 0.35)
        .overlay {
            if !hasStock && canRecycle {
                Image(systemName: "arrow.uturn.left.circle")
                    .foregroundStyle(settings.feltTextBase.opacity(0.5))
                    .font(.system(size: cardSize.width * 0.4))
            }
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .onTapGesture { vm.tapPyramidStock() }
        .contentShape(Rectangle())
    }

    /// Pyramid 웨이스트: 기준 카드 (드로로 갱신, 탭 동작 없음)
    private func pyramidWasteView(cardSize: CGSize) -> some View {
        let wasteCard = vm.pyramid?.waste.last
        return CardView(
            card: wasteCard,
            style: settings.cardStyle,
            isHighlighted: true,
            accessibilityHintText: "기준 카드 — 이 카드와 합 13이 되는 노출 카드 제거"
        )
        .frame(width: cardSize.width, height: cardSize.height)
        .contentShape(Rectangle())
    }

    /// 피라미드 본문: 7줄 카드 (노출 카드 선택/드래그 가능, 제거 시 페이드)
    private func pyramidBody(cardSize: CGSize, boardSize: CGSize) -> some View {
        ZStack {
            ForEach(0..<PyramidGame.pyramidCount, id: \.self) { i in
                if let card = vm.pyramid?.pyramid[i] {
                    let origin = pyramidCardOrigin(index: i, cardSize: cardSize, boardSize: boardSize)
                    let isExposed = vm.pyramid?.isExposed(i) == true
                    CardView(
                        card: card,
                        style: settings.cardStyle,
                        isHighlighted: isExposed,
                        isSelected: vm.isPyramidSelected(index: i),
                        isHintSource: isPyramidHintSource(index: i, card: card),
                        accessibilityHintText: isExposed ? "합 13 짝 카드를 탭해 제거" : "덮인 카드"
                    )
                    .frame(width: cardSize.width, height: cardSize.height)
                    .position(x: origin.x + cardSize.width / 2, y: origin.y + cardSize.height / 2)
                    .onTapGesture { vm.tapPyramidCard(index: i) }
                    .contentShape(Rectangle())
                }
            }
        }
        .offset(y: vm.isDealing ? 40 : 0)
        .opacity(vm.isDealing ? 0 : 1)
        .animation(.easeOut(duration: 0.5), value: vm.isDealing)
    }

    // MARK: - TriPeaks 뷰

    /// TriPeaks 상단 행: 스톡 + 웨이스트(좌) — 홈셀 없음
    private func triPeaksTopRow(cardSize: CGSize) -> some View {
        let gap: CGFloat = 2
        return ZStack {
            HStack(spacing: gap) {
                triPeaksStockView(cardSize: cardSize)
                triPeaksWasteView(cardSize: cardSize)
                Spacer()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("스톡, 웨이스트")
    }

    /// TriPeaks 스톡: 카드가 있으면 뒷면 묶음, 없으면 빈 슬롯 (재활용 없음)
    private func triPeaksStockView(cardSize: CGSize) -> some View {
        let hasStock = !(vm.triPeaks?.stock.isEmpty ?? true)
        return CardView(
            card: Card(suit: .spades, rank: .ace),
            style: settings.cardStyle,
            isHighlighted: true,
            showBack: true,
            cardBack: settings.cardBack,
            accessibilityHintText: "누르면 1장 드로"
        )
        .opacity(hasStock ? 1 : 0.35)
        .frame(width: cardSize.width, height: cardSize.height)
        .onTapGesture { vm.tapTriPeaksStock() }
        .contentShape(Rectangle())
    }

    /// TriPeaks 웨이스트: 기준 카드 (드로/제거로 갱신, 탭 동작 없음)
    private func triPeaksWasteView(cardSize: CGSize) -> some View {
        let wasteCard = vm.triPeaks?.waste.last
        return CardView(
            card: wasteCard,
            style: settings.cardStyle,
            isHighlighted: true,
            accessibilityHintText: "기준 카드 — 이 카드와 1 랭크 차이 노출 카드 제거"
        )
        .frame(width: cardSize.width, height: cardSize.height)
        .contentShape(Rectangle())
    }

    /// TriPeaks 본문: 3개 피크 (노출 카드 탭/드래그로 웨이스트 제거)
    private func triPeaksBody(cardSize: CGSize, boardSize: CGSize) -> some View {
        ZStack {
            ForEach(0..<TriPeaksGame.totalPeaksCount, id: \.self) { i in
                if let card = vm.triPeaks?.peaks[i] {
                    let origin = triPeaksCardOrigin(index: i, cardSize: cardSize, boardSize: boardSize)
                    let isExposed = vm.triPeaks?.isExposed(i) == true
                    CardView(
                        card: card,
                        style: settings.cardStyle,
                        isHighlighted: isExposed,
                        isSelected: vm.isTriPeaksSelected(index: i),
                        isHintSource: isTriPeaksHintSource(index: i, card: card),
                        accessibilityHintText: isExposed ? "웨이스트와 1 랭크 차이면 탭해 제거" : "덮인 카드"
                    )
                    .frame(width: cardSize.width, height: cardSize.height)
                    .position(x: origin.x + cardSize.width / 2, y: origin.y + cardSize.height / 2)
                    .onTapGesture { vm.tapTriPeaksCard(index: i) }
                    .contentShape(Rectangle())
                }
            }
        }
        .offset(y: vm.isDealing ? 40 : 0)
        .opacity(vm.isDealing ? 0 : 1)
        .animation(.easeOut(duration: 0.5), value: vm.isDealing)
    }

    /// Klondike 상단 행: 스톡 + 웨이스트(좌), 홈셀(우)
    private func klondikeTopRow(cardSize: CGSize) -> some View {
        let gap: CGFloat = 2
        return ZStack {
            HStack(spacing: gap) {
                stockView(cardSize: cardSize)
                wasteView(cardSize: cardSize)
                Spacer()
            }
            HStack(spacing: gap) {
                ForEach(0..<KlondikeGame.homeCount, id: \.self) { i in
                    klondikeHomeCell(i, cardSize: cardSize)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("스톡, 웨이스트, 홈셀")
    }

    /// Spider 상단 행: 스톡 5더미(좌), 완성 수트 표시(우)
    private func spiderTopRow(cardSize: CGSize) -> some View {
        let gap: CGFloat = 2
        return ZStack {
            HStack(spacing: gap) {
                ForEach(0..<5, id: \.self) { i in
                    spiderStockPile(i, cardSize: cardSize)
                }
                Spacer()
                completedSuitsView(cardSize: cardSize)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("스톡 \(vm.spider?.stock.count ?? 0)장, 완성 수트 \(vm.spider?.completedSuits ?? 0)/8")
    }

    /// Spider 스톡 더미 — 클릭 1회에 10장씩 딜되므로 더미당 10장을 나타냄
    /// (stock 남은 장수가 index*10+1장 이상이면 해당 더미 표시)
    private func spiderStockPile(_ index: Int, cardSize: CGSize) -> some View {
        let cardsLeft = vm.spider?.stock.count ?? 0
        let hasStock = cardsLeft > index * 10
        return CardView(
            card: Card(suit: .spades, rank: .ace),
            style: settings.cardStyle,
            isHighlighted: true,
            showBack: true,
            cardBack: settings.cardBack,
            accessibilityHintText: "누르면 각 열에 1장 딜"
        )
        .opacity(hasStock ? 1 : 0.3)
        .frame(width: cardSize.width, height: cardSize.height)
        .onTapGesture { vm.tapSpiderStock() }
        .contentShape(Rectangle())
    }

    /// 완성 수트 카운트 표시
    private func completedSuitsView(cardSize: CGSize) -> some View {
        let completed = vm.spider?.completedSuits ?? 0
        return VStack(spacing: 4) {
            HStack(spacing: 4) {
                ForEach(0..<8, id: \.self) { i in
                    Image(systemName: i < completed ? "suit.spade.fill" : "suit.spade")
                        .foregroundStyle(i < completed ? .green : settings.feltTextBase.opacity(0.35))
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            Text("완성 \(completed)/8")
                .font(.caption2)
                .foregroundStyle(settings.feltTextBase.opacity(0.65))
        }
        .frame(width: 120)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("완성 수트 \(completed)/8")
    }

    /// Scorpion 상단 행: 예비 더미 1개(우) + 완성 시퀀스 표시(좌)
    private func scorpionTopRow(cardSize: CGSize) -> some View {
        let completed = vm.scorpion?.completedSequencesCount ?? 0
        return ZStack {
            HStack(spacing: 2) {
                Text("완성 \(completed)/4")
                    .font(.caption2)
                    .foregroundStyle(settings.feltTextBase.opacity(0.65))
                    .frame(width: 120)
                Spacer()
                scorpionReservePile(cardSize: cardSize)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("예비 \(vm.scorpion?.reserve.count ?? 0)장, 완성 시퀀스 \(completed)/4")
    }

    /// Scorpion 예비 더미 (남은 카드가 있고 아직 딜 전이면 뒷면 묶음)
    private func scorpionReservePile(cardSize: CGSize) -> some View {
        let hasReserve = !(vm.scorpion?.reserve.isEmpty ?? true) && !(vm.scorpion?.reserveDealt ?? true)
        return CardView(
            card: Card(suit: .spades, rank: .ace),
            style: settings.cardStyle,
            isHighlighted: true,
            showBack: true,
            cardBack: settings.cardBack,
            accessibilityHintText: "누르면 예비 3장을 열 1·2·3에 딜"
        )
        .opacity(hasReserve ? 1 : 0.3)
        .frame(width: cardSize.width, height: cardSize.height)
        .onTapGesture { vm.tapScorpionStock() }
        .contentShape(Rectangle())
    }

    private var gameInfoView: some View {
        VStack(spacing: 3) {
            Text("\(vm.variantDisplayName)")
                .font(.caption2)
                .foregroundStyle(settings.feltTextBase.opacity(0.65))
            Text("게임 번호")
                .font(.caption2)
                .foregroundStyle(settings.feltTextBase.opacity(0.65))
            Text("\(vm.currentGameNumber)")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(settings.feltTextBase)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            difficultyBadge
            Text("이동 \(vm.currentMoveCount)")
                .font(.caption2)
                .foregroundStyle(settings.feltTextBase.opacity(0.6))
                .monospacedDigit()
            Text("점수 \(vm.score)")
                .font(.caption2)
                .foregroundStyle(settings.feltTextBase.opacity(0.6))
                .monospacedDigit()
            HStack(spacing: 3) {
                Text(formatTime(vm.elapsedSeconds))
                    .font(.caption2)
                    .foregroundStyle(settings.feltTextBase.opacity(0.6))
                    .monospacedDigit()
                if vm.isPaused {
                    Text("일시정지")
                        .font(.caption2.bold())
                        .foregroundStyle(.yellow)
                }
            }
        }
        .frame(width: 100)
        .overlay(alignment: .topTrailing) {
            if vm.isInProgress {
                Button(action: { vm.togglePause() }) {
                    Image(systemName: vm.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .foregroundStyle(settings.feltTextBase.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help(vm.isPaused ? "재개" : "일시정지")
                .accessibilityLabel(vm.isPaused ? "재개" : "일시정지")
                .padding(.trailing, 6)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(vm.variantDisplayName), 게임 번호 \(vm.currentGameNumber), 난이도 \(difficultyBadgeContent.0), 이동 \(vm.currentMoveCount), 시간 \(formatTime(vm.elapsedSeconds))")
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// 난이도 뱃지 (변형 고정값) — 게임 번호 아래 표시 (T-226)
    private var difficultyBadge: some View {
        let (text, color) = difficultyBadgeContent
        return Text(text)
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.18)))
            .foregroundStyle(color)
    }

    private var difficultyBadgeContent: (String, Color) {
        switch vm.variant.baseDifficulty {
        case .easy: ("쉬움", .green)
        case .medium: ("보통", .orange)
        case .hard: ("어려움", .red)
        case .unmeasured: ("미측정", .gray)
        }
    }

    // MARK: - 홈셀 / 프리셀 / 스톡 / 웨이스트

    private func homeCell(_ index: Int, cardSize: CGSize) -> some View {
        CardView(
            card: vm.game.homes[index].last,
            style: settings.cardStyle,
            isHighlighted: true,
            isHintSource: isHomeHintSource(index),
            isPulsing: vm.game.homes[index].last == vm.lastHomeCard,
            accessibilityHintText: "누르면 선택, 홈에서 꺼낼 수 있음"
        )
        .frame(width: cardSize.width, height: cardSize.height)
        .overlay(alignment: .topLeading) {
            if vm.game.homes[index].isEmpty, let suit = Suit(rawValue: index) {
                SuitSymbolView(suit: suit)
                    .opacity(0.35)
                    .frame(width: cardSize.width * 0.28, height: cardSize.width * 0.28)
                    .padding(5)
            }
        }
        .onTapGesture { vm.tapHome(index) }
    }

    private func klondikeHomeCell(_ index: Int, cardSize: CGSize) -> some View {
        let last = vm.klondike?.homes[index].last
        return CardView(
            card: last,
            style: settings.cardStyle,
            isHighlighted: true,
            isHintSource: isKlondikeHomeHintSource(index),
            isPulsing: last == vm.lastHomeCard,
            accessibilityHintText: "누르면 선택 카드 이동"
        )
        .frame(width: cardSize.width, height: cardSize.height)
        .overlay(alignment: .topLeading) {
            if last == nil, let suit = Suit(rawValue: index) {
                SuitSymbolView(suit: suit)
                    .opacity(0.35)
                    .frame(width: cardSize.width * 0.28, height: cardSize.width * 0.28)
                    .padding(5)
            }
        }
        .onTapGesture { vm.tapKlondikeHome(index) }
    }

    /// Klondike 스톡: 카드가 있으면 카드 뒷면 묶음, 없으면 빈 슬롯
    private func stockView(cardSize: CGSize) -> some View {
        let hasStock = !(vm.klondike?.stock.isEmpty ?? true)
        return CardView(
            card: Card(suit: .spades, rank: .ace),
            style: settings.cardStyle,
            isHighlighted: true,
            showBack: true,
            cardBack: settings.cardBack,
            accessibilityHintText: "누르면 1장 드로"
        )
        .opacity(hasStock ? 1 : 0.35)
        .overlay {
            if !hasStock {
                Image(systemName: "arrow.uturn.left.circle")
                    .foregroundStyle(settings.feltTextBase.opacity(0.5))
                    .font(.system(size: cardSize.width * 0.4))
            }
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .onTapGesture { vm.tapKlondikeStock() }
        .contentShape(Rectangle())
    }

    private func wasteView(cardSize: CGSize) -> some View {
        let wasteCard = vm.klondike?.waste.last
        return CardView(
            card: wasteCard,
            style: settings.cardStyle,
            isHighlighted: true,
            isSelected: vm.selection?.source == .waste,
            accessibilityHintText: "누르면 선택, 두 번 누르면 홈셀로 이동"
        )
        .frame(width: cardSize.width, height: cardSize.height)
        .onTapGesture {
            handleWasteTap()
        }
        .contentShape(Rectangle())
    }

    private func handleWasteTap() {
        handleTap(identifier: "waste") {
            vm.tapKlondikeWaste()
        } double: {
            _ = vm.doubleClickKlondikeWaste()
        }
    }

    private func freeCell(_ index: Int, cardSize: CGSize) -> some View {
        CardView(
            card: vm.game.freeCells[index],
            style: settings.cardStyle,
            isHintSource: isFreeCellHintSource(index),
            accessibilityHintText: "누르면 선택, 두 번 누르면 홈셀로 이동"
        )
        .frame(width: cardSize.width, height: cardSize.height)
        .onTapGesture { handleFreeCellTap(index: index) }
        .contentShape(Rectangle())
    }

    /// 힌트 하이라이트 소스(홈) 여부 — FreeCell
    private func isHomeHintSource(_ index: Int) -> Bool {
        vm.displayedHintMoves.contains {
            if case let .homeToColumn(homeIndex, _, _) = $0 { return homeIndex == index }
            return false
        }
    }

    /// 힌트 하이라이트 소스(홈) 여부 — Klondike
    private func isKlondikeHomeHintSource(_ index: Int) -> Bool {
        vm.displayedHintMoves.contains { move in
            switch move {
            case .wasteToFoundation: return false
            case let .columnToHome(_, card):
                return vm.klondike?.homes[index].last?.suit == card.suit
            default:
                return false
            }
        }
    }

    /// 힌트 하이라이트 소스(프리셀) 여부
    private func isFreeCellHintSource(_ index: Int) -> Bool {
        vm.displayedHintMoves.contains {
            if case let .freeCellToColumn(fc, _, _) = $0 { return fc == index }
            return false
        }
    }

    // MARK: - 타블로 열

    private func columnsRow(cardSize: CGSize, overlap: CGFloat, boardSize: CGSize) -> some View {
        HStack(alignment: .top, spacing: 2) {
            ForEach(0..<columnCount, id: \.self) { i in
                columnView(i, cardSize: cardSize, overlap: overlap)
            }
        }
        .offset(y: vm.isDealing ? 40 : 0)
        .opacity(vm.isDealing ? 0 : 1)
        .animation(.easeOut(duration: 0.5), value: vm.isDealing)
    }

    @ViewBuilder
    private func columnView(_ column: Int, cardSize: CGSize, overlap: CGFloat) -> some View {
        if vm.spider != nil {
            spiderColumnView(column, cardSize: cardSize, overlap: overlap)
        } else if vm.klondike != nil {
            klondikeColumnView(column, cardSize: cardSize, overlap: overlap)
        } else if vm.yukon != nil {
            yukonColumnView(column, cardSize: cardSize, overlap: overlap)
        } else if vm.fortyThieves != nil {
            fortyThievesColumnView(column, cardSize: cardSize, overlap: overlap)
        } else if vm.golf != nil {
            golfColumnView(column, cardSize: cardSize, overlap: overlap)
        } else if vm.scorpion != nil {
            scorpionColumnView(column, cardSize: cardSize, overlap: overlap)
        } else {
            freeCellColumnView(column, cardSize: cardSize, overlap: overlap)
        }
    }

    private func freeCellColumnView(_ column: Int, cardSize: CGSize, overlap: CGFloat) -> some View {
        let cards = vm.game.columns[column]
        return VStack(spacing: 0) {
            if cards.isEmpty {
                CardView(card: nil, style: settings.cardStyle, isHighlighted: true)
                    .frame(width: cardSize.width, height: cardSize.height)
            } else {
                ForEach(Array(cards.enumerated()), id: \.offset) { i, card in
                    CardView(
                        card: card,
                        style: settings.cardStyle,
                        isSelected: vm.isSelected(column: column, cardIndex: i),
                        isHintSource: isHintSource(card: card, cardIndex: i, column: column),
                        showBack: vm.isDealing,
                        cardBack: settings.cardBack,
                        accessibilityHintText: "누르면 선택, 두 번 누르면 홈셀로 이동"
                    )
                    .frame(width: cardSize.width, height: cardSize.height)
                    .offset(y: -overlap * CGFloat(i))
                    .zIndex(Double(i))
                    .onTapGesture {
                        handleCardTap(column: column, cardIndex: i)
                    }
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(width: cardSize.width)
        .frame(maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("열 \(column + 1)")
    }

    private func klondikeColumnView(_ column: Int, cardSize: CGSize, overlap: CGFloat) -> some View {
        let cards = vm.klondike?.columns[column] ?? []
        return VStack(spacing: 0) {
            if cards.isEmpty {
                CardView(card: nil, style: settings.cardStyle, isHighlighted: true)
                    .frame(width: cardSize.width, height: cardSize.height)
            } else {
                ForEach(Array(cards.enumerated()), id: \.offset) { i, cc in
                    CardView(
                        card: cc.card,
                        style: settings.cardStyle,
                        isSelected: vm.isKlondikeSelected(column: column, cardIndex: i),
                        isHintSource: isKlondikeHintSource(column: column, cardIndex: i, card: cc.card),
                        showBack: !cc.faceUp,
                        cardBack: settings.cardBack,
                        accessibilityHintText: cc.faceUp ? "누르면 선택, 두 번 누르면 홈셀로 이동" : "누르면 뒤집기"
                    )
                    .frame(width: cardSize.width, height: cardSize.height)
                    .offset(y: -overlap * CGFloat(i))
                    .zIndex(Double(i))
                    .onTapGesture {
                        handleKlondikeCardTap(column: column, cardIndex: i)
                    }
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(width: cardSize.width)
        .frame(maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("열 \(column + 1)")
    }

    /// 힌트 하이라이트 소스(타블로) 여부 — FreeCell
    private func isHintSource(card: Card, cardIndex: Int, column: Int) -> Bool {
        vm.displayedHintMoves.contains { move in
            switch move {
            case let .columnToColumn(from, _, count):
                guard from == column else { return false }
                let fromBottom = vm.game.columns[column].count - 1 - cardIndex
                return fromBottom < count
            case let .columnToHome(ci, _):
                return ci == column && cardIndex == vm.game.columns[column].count - 1
            case let .columnToFreeCell(ci, _, _):
                return ci == column && cardIndex == vm.game.columns[column].count - 1
            default:
                return false
            }
        }
    }

    /// 힌트 하이라이트 소스(타블로) 여부 — Klondike
    private func isKlondikeHintSource(column: Int, cardIndex: Int, card: Card) -> Bool {
        guard let k = vm.klondike else { return false }
        return vm.displayedHintMoves.contains { move in
            switch move {
            case let .columnToColumn(from, _, count):
                guard from == column else { return false }
                let fromBottom = k.columns[column].count - 1 - cardIndex
                return fromBottom < count
            case let .columnToHome(ci, c):
                return ci == column && cardIndex == k.columns[column].count - 1 && c == card
            case let .flipColumnCard(ci, c):
                return ci == column && cardIndex == k.columns[column].count - 1 && c == card
            default:
                return false
            }
        }
    }

    /// Spider 타블로 열 (뒤집힌 카드 + 같은 수트 시퀀스 이동)
    private func spiderColumnView(_ column: Int, cardSize: CGSize, overlap: CGFloat) -> some View {
        let cards = vm.spider?.columns[column] ?? []
        return VStack(spacing: 0) {
            if cards.isEmpty {
                CardView(card: nil, style: settings.cardStyle, isHighlighted: true)
                    .frame(width: cardSize.width, height: cardSize.height)
            } else {
                ForEach(Array(cards.enumerated()), id: \.offset) { i, cc in
                    CardView(
                        card: cc.card,
                        style: settings.cardStyle,
                        isSelected: vm.isSpiderSelected(column: column, cardIndex: i),
                        isHintSource: isSpiderHintSource(column: column, cardIndex: i, card: cc.card),
                        showBack: !cc.faceUp,
                        cardBack: settings.cardBack,
                        accessibilityHintText: cc.faceUp ? "누르면 선택, 두 번 누르면 이동" : "뒤집힌 카드"
                    )
                    .frame(width: cardSize.width, height: cardSize.height)
                    .offset(y: -overlap * CGFloat(i))
                    .zIndex(Double(i))
                    .onTapGesture {
                        handleSpiderCardTap(column: column, cardIndex: i)
                    }
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(width: cardSize.width)
        .frame(maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("열 \(column + 1)")
    }

    /// Scorpion 타블로 열 (뒤집힌 카드 + 그룹 이동)
    private func scorpionColumnView(_ column: Int, cardSize: CGSize, overlap: CGFloat) -> some View {
        let cards = vm.scorpion?.columns[column] ?? []
        return VStack(spacing: 0) {
            if cards.isEmpty {
                CardView(card: nil, style: settings.cardStyle, isHighlighted: true)
                    .frame(width: cardSize.width, height: cardSize.height)
            } else {
                ForEach(Array(cards.enumerated()), id: \.offset) { i, cc in
                    CardView(
                        card: cc.card,
                        style: settings.cardStyle,
                        isSelected: vm.isScorpionSelected(column: column, cardIndex: i),
                        isHintSource: isScorpionHintSource(column: column, cardIndex: i, card: cc.card),
                        showBack: !cc.faceUp,
                        cardBack: settings.cardBack,
                        accessibilityHintText: cc.faceUp ? "누르면 선택, 두 번 누르면 이동" : "뒤집힌 카드"
                    )
                    .frame(width: cardSize.width, height: cardSize.height)
                    .offset(y: -overlap * CGFloat(i))
                    .zIndex(Double(i))
                    .onTapGesture {
                        handleScorpionCardTap(column: column, cardIndex: i)
                    }
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(width: cardSize.width)
        .frame(maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("열 \(column + 1)")
    }

    /// Forty Thieves 타블로 열 (전부 앞면, 같은 수트 시퀀스 이동)
    private func fortyThievesColumnView(_ column: Int, cardSize: CGSize, overlap: CGFloat) -> some View {        let cards = vm.fortyThieves?.columns[column] ?? []
        return VStack(spacing: 0) {
            if cards.isEmpty {
                CardView(card: nil, style: settings.cardStyle, isHighlighted: true)
                    .frame(width: cardSize.width, height: cardSize.height)
            } else {
                ForEach(Array(cards.enumerated()), id: \.offset) { i, card in
                    CardView(
                        card: card,
                        style: settings.cardStyle,
                        isSelected: vm.isFortyThievesSelected(column: column, cardIndex: i),
                        isHintSource: isFortyThievesHintSource(column: column, cardIndex: i, card: card),
                        showBack: vm.isDealing,
                        cardBack: settings.cardBack,
                        accessibilityHintText: "누르면 선택, 두 번 누르면 홈셀로 이동"
                    )
                    .frame(width: cardSize.width, height: cardSize.height)
                    .offset(y: -overlap * CGFloat(i))
                    .zIndex(Double(i))
                    .onTapGesture {
                        handleFortyThievesCardTap(column: column, cardIndex: i)
                    }
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(width: cardSize.width)
        .frame(maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("열 \(column + 1)")
    }

    /// 힌트 하이라이트 소스(타블로) 여부 — Forty Thieves
    private func isFortyThievesHintSource(column: Int, cardIndex: Int, card: Card) -> Bool {
        guard let f = vm.fortyThieves else { return false }
        return vm.displayedHintMoves.contains { move in
            switch move {
            case let .columnToColumn(from, _, count):
                guard from == column else { return false }
                let fromBottom = f.columns[column].count - 1 - cardIndex
                return fromBottom < count
            case let .columnToHome(ci, c):
                return ci == column && cardIndex == f.columns[column].count - 1 && c == card
            default:
                return false
            }
        }
    }

    private func handleFortyThievesCardTap(column: Int, cardIndex: Int) {
        handleTap(identifier: "ftc\(column)-\(cardIndex)") {
            vm.tapFortyThievesColumn(column: column, cardIndex: cardIndex)
        } double: {
            _ = vm.doubleClickFortyThievesToHome(column: column, cardIndex: cardIndex)
        }
    }

    /// Golf 타블로 열 (전부 앞면, 맨 아래 카드만 웨이스트로 제거 가능)
    private func golfColumnView(_ column: Int, cardSize: CGSize, overlap: CGFloat) -> some View {
        let cards = vm.golf?.columns[column] ?? []
        return VStack(spacing: 0) {
            if cards.isEmpty {
                CardView(card: nil, style: settings.cardStyle, isHighlighted: true)
                    .frame(width: cardSize.width, height: cardSize.height)
            } else {
                ForEach(Array(cards.enumerated()), id: \.offset) { i, card in
                    CardView(
                        card: card,
                        style: settings.cardStyle,
                        isHighlighted: i == cards.count - 1,
                        isHintSource: isGolfHintSource(column: column, cardIndex: i),
                        showBack: vm.isDealing,
                        cardBack: settings.cardBack,
                        accessibilityHintText: i == cards.count - 1 ? "누르면 웨이스트로 제거" : "뒷면 위 카드"
                    )
                    .frame(width: cardSize.width, height: cardSize.height)
                    .offset(y: -overlap * CGFloat(i))
                    .zIndex(Double(i))
                    .onTapGesture {
                        handleGolfCardTap(column: column, cardIndex: i)
                    }
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(width: cardSize.width)
        .frame(maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("열 \(column + 1)")
    }

    private func handleGolfCardTap(column: Int, cardIndex: Int) {
        vm.tapGolfColumn(column: column, cardIndex: cardIndex)
    }

    /// 힌트 하이라이트 소스(타블로) 여부 — Golf (열 맨 아래 카드 → 웨이스트)
    private func isGolfHintSource(column: Int, cardIndex: Int) -> Bool {
        guard let g = vm.golf else { return false }
        return vm.displayedHintMoves.contains { move in
            if case let .columnToWaste(ci, _) = move {
                return ci == column && cardIndex == g.columns[column].count - 1
            }
            return false
        }
    }

    /// 힌트 하이라이트 소스 여부 — Pyramid (합 13 노출 카드)
    private func isPyramidHintSource(index: Int, card: Card) -> Bool {
        guard let p = vm.pyramid else { return false }
        let isCardAt = p.pyramid.indices.contains(index) && p.pyramid[index] == card
        return vm.displayedHintMoves.contains { move in
            switch move {
            case let .pyramidRemovePair(first, _):
                return isCardAt && p.pyramid[index] == first
            case let .pyramidRemoveWastePair(c), let .pyramidRemoveSingle(c):
                return isCardAt && p.pyramid[index] == c
            default:
                return false
            }
        }
    }

    /// 힌트 하이라이트 소스 여부 — TriPeaks (웨이스트와 1 랭크 차이 노출 카드)
    private func isTriPeaksHintSource(index: Int, card: Card) -> Bool {
        guard let t = vm.triPeaks else { return false }
        return vm.displayedHintMoves.contains { move in
            if case let .triPeaksRemove(c) = move {
                return t.peaks.indices.contains(index) && t.peaks[index] == c
            }
            return false
        }
    }

    /// Yukon 타블로 열 (뒤집힌 카드 + 유콘 그룹 이동)
    private func yukonColumnView(_ column: Int, cardSize: CGSize, overlap: CGFloat) -> some View {
        let cards = vm.yukon?.columns[column] ?? []
        return VStack(spacing: 0) {
            if cards.isEmpty {
                CardView(card: nil, style: settings.cardStyle, isHighlighted: true)
                    .frame(width: cardSize.width, height: cardSize.height)
            } else {
                ForEach(Array(cards.enumerated()), id: \.offset) { i, cc in
                    CardView(
                        card: cc.card,
                        style: settings.cardStyle,
                        isSelected: vm.isYukonSelected(column: column, cardIndex: i),
                        isHintSource: isYukonHintSource(column: column, cardIndex: i, card: cc.card),
                        showBack: !cc.faceUp,
                        cardBack: settings.cardBack,
                        accessibilityHintText: cc.faceUp ? "누르면 선택, 두 번 누르면 홈셀로 이동" : "뒤집힌 카드"
                    )
                    .frame(width: cardSize.width, height: cardSize.height)
                    .offset(y: -overlap * CGFloat(i))
                    .zIndex(Double(i))
                    .onTapGesture {
                        handleYukonCardTap(column: column, cardIndex: i)
                    }
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(width: cardSize.width)
        .frame(maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("열 \(column + 1)")
    }

    /// 힌트 하이라이트 소스(타블로) 여부 — Yukon
    private func isYukonHintSource(column: Int, cardIndex: Int, card: Card) -> Bool {
        guard let y = vm.yukon else { return false }
        return vm.displayedHintMoves.contains { move in
            switch move {
            case let .columnToColumn(from, _, count):
                guard from == column else { return false }
                let fromBottom = y.columns[column].count - 1 - cardIndex
                return fromBottom < count
            case let .columnToHome(ci, c):
                return ci == column && cardIndex == y.columns[column].count - 1 && c == card
            default:
                return false
            }
        }
    }

    private func handleYukonCardTap(column: Int, cardIndex: Int) {
        handleTap(identifier: "yc\(column)-\(cardIndex)") {
            vm.tapYukonColumn(column: column, cardIndex: cardIndex)
        } double: {
            _ = vm.doubleClickYukonToHome(column: column, cardIndex: cardIndex)
        }
    }

    /// 힌트 하이라이트 소스(타블로) 여부 — Spider
    private func isSpiderHintSource(column: Int, cardIndex: Int, card: Card) -> Bool {
        guard let s = vm.spider else { return false }
        return vm.displayedHintMoves.contains { move in
            switch move {
            case let .columnToColumn(from, _, count):
                guard from == column else { return false }
                let fromBottom = s.columns[column].count - 1 - cardIndex
                return fromBottom < count
            default:
                return false
            }
        }
    }

    private func isScorpionHintSource(column: Int, cardIndex: Int, card: Card) -> Bool {
        guard let s = vm.scorpion else { return false }
        return vm.displayedHintMoves.contains { move in
            switch move {
            case let .columnToColumn(from, _, count):
                guard from == column else { return false }
                let fromBottom = s.columns[column].count - 1 - cardIndex
                return fromBottom < count
            default:
                return false
            }
        }
    }

    // MARK: - 드래그 상태

    private struct DragState {
        var source: CardSource
        var cardCount: Int
        var topIndex: Int
        var startLocation: CGPoint
        var location: CGPoint
        var startCardOrigin: CGPoint
    }

    /// 힌트 드래그 애니메이션 (실제 이동 없음)의 정적 기하 정보
    private struct HintDragGeometry {
        let cards: [Card]
        let from: CGPoint
        let to: CGPoint
    }

    // MARK: - 힌트 드래그 애니메이션

    /// 힌트로 제시된 이동을 카드가 실제로 움직이는 것처럼 소스→목적지 왕복 2회 표시
    private func runHintDragAnimation(boardSize: CGSize, cardSize: CGSize) {
        hintDragTask?.cancel()
        hintGeometry = nil
        hintDragPosition = nil
        guard let move = vm.hintAnimationMove,
              let g = hintGeometry(for: move, boardSize: boardSize, cardSize: cardSize) else { return }
        hintGeometry = g
        hintDragPosition = g.from
        hintDragTask = Task {
            do {
                for _ in 0..<2 {
                    try await animateHint(to: g.to)
                    try Task.checkCancellation()
                    try await Task.sleep(nanoseconds: 180_000_000)
                    try await animateHint(to: g.from)
                    try Task.checkCancellation()
                    try await Task.sleep(nanoseconds: 180_000_000)
                }
            } catch {
                // 취소/오류 시 상태 정리
            }
            hintGeometry = nil
            hintDragPosition = nil
        }
    }

    private func animateHint(to point: CGPoint) async throws {
        let duration = 0.45
        withAnimation(.easeInOut(duration: duration)) {
            hintDragPosition = point
        }
        try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
    }

    private func cancelHintDrag() {
        hintDragTask?.cancel()
        hintDragTask = nil
        hintGeometry = nil
        hintDragPosition = nil
    }

    /// 힌트 드래그 오버레이 — 소스 카드 묶음이 소스→목적지로 이동하는 모습
    @ViewBuilder
    private func hintDragOverlay(cardSize: CGSize, boardSize: CGSize) -> some View {
        if let g = hintGeometry, let pos = hintDragPosition {
            let step = effectiveStep(cardSize: cardSize, boardSize: boardSize)
            let count = max(g.cards.count, 1)
            let stackHeight = CGFloat(count - 1) * step + cardSize.height
            ZStack(alignment: .topLeading) {
                ForEach(Array(g.cards.enumerated()), id: \.element.id) { i, card in
                    CardView(card: card, style: settings.cardStyle)
                        .frame(width: cardSize.width, height: cardSize.height)
                        .offset(y: CGFloat(i) * step)
                }
            }
            .compositingGroup()
            .shadow(radius: 6)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .position(
                x: pos.x + cardSize.width / 2,
                y: pos.y + stackHeight / 2
            )
        }
    }

    /// 힌트 이동을 소스/카드수/topIndex/목적지로 매핑 (드래그 애니메이션 대상)
    private func hintGeometry(for move: Move, boardSize: CGSize, cardSize: CGSize) -> HintDragGeometry? {
        guard let (source, count, topIndex, destination) = hintSourceDestination(for: move) else { return nil }
        let from = cardBoardOrigin(source, topIndex: topIndex, cardSize: cardSize, boardSize: boardSize)
        let to = destinationOrigin(destination, cardSize: cardSize, boardSize: boardSize)
        let cards = hintCards(source: source, count: count)
        guard !cards.isEmpty else { return nil }
        return HintDragGeometry(cards: cards, from: from, to: to)
    }

    /// Move → (소스, 카드수, topIndex, 목적지) — 드래그 부적합(스톡/플립)은 nil
    private func hintSourceDestination(for move: Move) -> (source: CardSource, count: Int, topIndex: Int, destination: Destination)? {
        switch move {
        case let .columnToColumn(from, to, count):
            return (.column(from), count, columnCards(from).count - count, .column(to))
        case let .columnToFreeCell(columnIndex, freeCellIndex, _):
            return (.column(columnIndex), 1, columnCards(columnIndex).count - 1, .freeCell(freeCellIndex))
        case let .freeCellToColumn(freeCellIndex, columnIndex, _):
            return (.freeCell(freeCellIndex), 1, 0, .column(columnIndex))
        case let .columnToHome(columnIndex, card):
            return (.column(columnIndex), 1, columnCards(columnIndex).count - 1, .home(hintHomeIndex(for: card)))
        case let .freeCellToHome(freeCellIndex, card):
            return (.freeCell(freeCellIndex), 1, 0, .home(hintHomeIndex(for: card)))
        case let .homeToColumn(homeIndex, columnIndex, _):
            return (.home(homeIndex), 1, 0, .column(columnIndex))
        case let .homeToFreeCell(homeIndex, freeCellIndex, _):
            return (.home(homeIndex), 1, 0, .freeCell(freeCellIndex))
        case let .wasteToColumn(columnIndex, _):
            return (.waste, 1, 0, .column(columnIndex))
        case let .wasteToFoundation(card):
            return (.waste, 1, 0, .home(hintHomeIndex(for: card)))
        case let .columnToWaste(columnIndex, _):
            return (.column(columnIndex), 1, columnCards(columnIndex).count - 1, .waste)
        case let .pyramidRemovePair(first, _):
            guard let idx = pyramidIndex(of: first) else { return nil }
            return (.pyramid(idx), 1, 0, .waste)
        case let .pyramidRemoveWastePair(card), let .pyramidRemoveSingle(card):
            guard let idx = pyramidIndex(of: card) else { return nil }
            return (.pyramid(idx), 1, 0, .waste)
        case let .triPeaksRemove(card):
            guard let idx = triPeaksIndex(of: card) else { return nil }
            return (.triPeaks(idx), 1, 0, .waste)
        case .drawFromStock, .recycleStock, .dealFromStock, .flipColumnCard, .dealReserve:
            return nil
        }
    }

    /// 현재 게임의 해당 열 카드 목록
    private func columnCards(_ col: Int) -> [Card] {
        if let s = vm.spider { return s.columns[col].map(\.card) }
        if let k = vm.klondike { return k.columns[col].map(\.card) }
        if let y = vm.yukon { return y.columns[col].map(\.card) }
        if let f = vm.fortyThieves { return Array(f.columns[col]) }
        if let g = vm.golf { return Array(g.columns[col]) }
        if let s = vm.scorpion { return s.columns[col].map(\.card) }
        return Array(vm.game.columns[col])
    }

    /// 힌트 오버레이에 표시할 카드 묶음
    private func hintCards(source: CardSource, count: Int) -> [Card] {
        switch source {
        case .column(let i):
            return Array(columnCards(i).suffix(count))
        case .freeCell(let i):
            return vm.game.freeCells[i].map { [$0] } ?? []
        case .home(let i):
            return vm.game.homes[i].last.map { [$0] } ?? []
        case .waste:
            return vm.klondike?.waste.last.map { [$0] }
                ?? vm.fortyThieves?.waste.last.map { [$0] }
                ?? []
        case .pyramid(let i):
            return vm.pyramid?.pyramid[i].map { [$0] } ?? []
        case .triPeaks(let i):
            return vm.triPeaks?.peaks[i].map { [$0] } ?? []
        }
    }

    /// 해당 카드가 놓일 홈셀 인덱스 (게임별 규칙 반영)
    private func hintHomeIndex(for card: Card) -> Int {
        if let f = vm.fortyThieves { return f.homeIndex(for: card) ?? 0 }
        if let k = vm.klondike { return k.homeIndex(for: card) ?? 0 }
        if let y = vm.yukon { return y.homeIndex(for: card) ?? 0 }
        return vm.game.homeIndex(for: card) ?? 0
    }

    private func pyramidIndex(of card: Card) -> Int? {
        vm.pyramid?.pyramid.firstIndex(where: { $0 == card })
    }

    private func triPeaksIndex(of card: Card) -> Int? {
        vm.triPeaks?.peaks.firstIndex(where: { $0 == card })
    }

    /// 목적지의 카드 원점(보드 좌표) — 홈/프리셀/웨이스트/열 배치 로직 공유
    private func destinationOrigin(_ destination: Destination, cardSize: CGSize, boardSize: CGSize) -> CGPoint {
        let gap: CGFloat = 2
        let left = cardSize.width + gap
        let columnsStartY = cardSize.height * 1.3 + 10
        let topRowCardY = (cardSize.height * 1.3 - cardSize.height) / 2
        switch destination {
        case .column(let col):
            let colsStartX = columnsStartX(boardSize: boardSize, cardSize: cardSize)
            let step = effectiveStep(cardSize: cardSize, boardSize: boardSize)
            let y = columnsStartY + CGFloat(columnCards(col).count) * step
            return CGPoint(x: colsStartX + CGFloat(col) * left, y: y)
        case .freeCell(let i):
            let freeStartX = boardSize.width - 14 - CGFloat(freeCellCount) * cardSize.width - CGFloat(freeCellCount - 1) * gap
            return CGPoint(x: freeStartX + CGFloat(i) * left, y: topRowCardY)
        case .home(let i):
            return CGPoint(x: 14 + CGFloat(i) * left, y: topRowCardY)
        case .waste:
            let stockX: CGFloat = 14
            return CGPoint(x: stockX + left, y: topRowCardY)
        }
    }

    // MARK: - 탭 / 더블클릭 (시간 기반 판정)

    private func handleCardTap(column: Int, cardIndex: Int) {
        handleTap(identifier: "c\(column)-\(cardIndex)") {
            vm.tapCard(column: column, cardIndex: cardIndex)
        } double: {
            _ = vm.doubleClickToHome(column: column, cardIndex: cardIndex)
        }
    }

    private func handleKlondikeCardTap(column: Int, cardIndex: Int) {
        handleTap(identifier: "kc\(column)-\(cardIndex)") {
            vm.tapKlondikeColumn(column: column, cardIndex: cardIndex)
        } double: {
            _ = vm.doubleClickKlondikeToHome(column: column, cardIndex: cardIndex)
        }
    }

    private func handleSpiderCardTap(column: Int, cardIndex: Int) {
        handleTap(identifier: "sc\(column)-\(cardIndex)") {
            vm.tapSpiderColumn(column: column, cardIndex: cardIndex)
        } double: {
            // 스파이더: 더블클릭은 첫 클릭에서 이미 선택 처리됨 (홈 이동 없음)
        }
    }

    private func handleScorpionCardTap(column: Int, cardIndex: Int) {
        handleTap(identifier: "x\(column)-\(cardIndex)") {
            vm.tapScorpionColumn(column: column, cardIndex: cardIndex)
        } double: {
            // 스콜피온: 더블클릭은 첫 클릭에서 이미 선택 처리됨 (홈 이동 없음)
        }
    }

    private func handleFreeCellTap(index: Int) {
        handleTap(identifier: "f\(index)") {
            vm.tapFreeCell(index)
        } double: {
            if vm.game.freeCells[index] != nil {
                _ = vm.move(cardAt: .freeCell(index), cardCount: 1, to: .home(0))
            }
        }
    }

    private func handleTap(identifier: String, single: () -> Void, double: () -> Void) {
        let now = Date()
        if lastTapIdentifier == identifier,
           let last = lastTapAt,
           now.timeIntervalSince(last) < 0.35 {
            lastTapIdentifier = nil
            lastTapAt = nil
            double()
        } else {
            lastTapAt = now
            lastTapIdentifier = identifier
            single()
        }
    }

    // MARK: - 보드 탭 라우팅 (SpatialTapGesture 기반, T-비동기: macOS SwiftUI 보드 내 개별 탭 인식 불가 대응)

    /// 보드 좌표의 탭 지점을 현재 변형의 탭 핸들러로 라우팅
    private func handleBoardTap(at point: CGPoint, boardSize: CGSize, cardSize: CGSize) {
        let columnsStartY = cardSize.height * 1.3 + 10

        if vm.pyramid != nil {
            handlePyramidTap(at: point, boardSize: boardSize, cardSize: cardSize)
            return
        }
        if vm.triPeaks != nil {
            handleTriPeaksTap(at: point, boardSize: boardSize, cardSize: cardSize)
            return
        }
        if point.y < columnsStartY {
            handleTopRowTap(at: point, boardSize: boardSize, cardSize: cardSize)
            return
        }
        handleColumnTap(at: point, boardSize: boardSize, cardSize: cardSize)
    }

    private func handlePyramidTap(at point: CGPoint, boardSize: CGSize, cardSize: CGSize) {
        let stockRect = CGRect(x: 14, y: 0, width: cardSize.width, height: cardSize.height)
        if stockRect.contains(point) {
            vm.tapPyramidStock()
            return
        }
        for i in 0..<PyramidGame.pyramidCount {
            guard let p = vm.pyramid, p.pyramid.indices.contains(i), p.pyramid[i] != nil, p.isExposed(i) else { continue }
            let origin = pyramidCardOrigin(index: i, cardSize: cardSize, boardSize: boardSize)
            if CGRect(x: origin.x, y: origin.y, width: cardSize.width, height: cardSize.height).contains(point) {
                vm.tapPyramidCard(index: i)
                return
            }
        }
    }

    private func handleTriPeaksTap(at point: CGPoint, boardSize: CGSize, cardSize: CGSize) {
        let stockRect = CGRect(x: 14, y: 0, width: cardSize.width, height: cardSize.height)
        if stockRect.contains(point) {
            vm.tapTriPeaksStock()
            return
        }
        for i in 0..<TriPeaksGame.totalPeaksCount {
            guard let t = vm.triPeaks, t.peaks.indices.contains(i), t.peaks[i] != nil, t.isExposed(i) else { continue }
            let origin = triPeaksCardOrigin(index: i, cardSize: cardSize, boardSize: boardSize)
            if CGRect(x: origin.x, y: origin.y, width: cardSize.width, height: cardSize.height).contains(point) {
                vm.tapTriPeaksCard(index: i)
                return
            }
        }
    }

    private func handleTopRowTap(at point: CGPoint, boardSize: CGSize, cardSize: CGSize) {
        let gap: CGFloat = 2
        let left = cardSize.width + gap

        if vm.spider != nil {
            for i in 0..<5 {
                let x = 14 + CGFloat(i) * left
                if CGRect(x: x, y: 0, width: cardSize.width, height: cardSize.height).contains(point) {
                    vm.tapSpiderStock()
                    return
                }
            }
            return
        }
        if vm.klondike != nil {
            let stockX: CGFloat = 14
            let wasteX = stockX + left
            if CGRect(x: stockX, y: 0, width: cardSize.width, height: cardSize.height).contains(point) {
                vm.tapKlondikeStock()
                return
            }
            if CGRect(x: wasteX, y: 0, width: cardSize.width, height: cardSize.height).contains(point) {
                handleWasteTap()
                return
            }
            let homeStartX = boardSize.width - 14 - CGFloat(KlondikeGame.homeCount) * cardSize.width - CGFloat(KlondikeGame.homeCount - 1) * gap
            for i in 0..<KlondikeGame.homeCount {
                if CGRect(x: homeStartX + CGFloat(i) * left, y: 0, width: cardSize.width, height: cardSize.height).contains(point) {
                    vm.tapKlondikeHome(i)
                    return
                }
            }
            return
        }
        if vm.yukon != nil {
            let homeStartX = boardSize.width - 14 - CGFloat(YukonGame.homeCount) * cardSize.width - CGFloat(YukonGame.homeCount - 1) * gap
            for i in 0..<YukonGame.homeCount {
                if CGRect(x: homeStartX + CGFloat(i) * left, y: 0, width: cardSize.width, height: cardSize.height).contains(point) {
                    vm.tapYukonHome(i)
                    return
                }
            }
            return
        }
        if vm.fortyThieves != nil {
            let stockX: CGFloat = 14
            let wasteX = stockX + left
            if CGRect(x: stockX, y: 0, width: cardSize.width, height: cardSize.height).contains(point) {
                vm.tapFortyThievesStock()
                return
            }
            if CGRect(x: wasteX, y: 0, width: cardSize.width, height: cardSize.height).contains(point) {
                handleFortyThievesWasteTap()
                return
            }
            let homeStartX = boardSize.width - 14 - CGFloat(FortyThievesGame.homeCount) * cardSize.width - CGFloat(FortyThievesGame.homeCount - 1) * gap
            for i in 0..<FortyThievesGame.homeCount {
                if CGRect(x: homeStartX + CGFloat(i) * left, y: 0, width: cardSize.width, height: cardSize.height).contains(point) {
                    vm.tapFortyThievesHome(i)
                    return
                }
            }
            return
        }
        if vm.golf != nil {
            let stockX: CGFloat = 14
            if CGRect(x: stockX, y: 0, width: cardSize.width, height: cardSize.height).contains(point) {
                vm.tapGolfStock()
            }
            return
        }
        if vm.scorpion != nil {
            let reserveX = boardSize.width - 14 - cardSize.width
            if CGRect(x: reserveX, y: 0, width: cardSize.width, height: cardSize.height).contains(point) {
                vm.tapScorpionStock()
            }
            return
        }

        for i in 0..<FreeCellGame.homeCount {
            let x = 14 + CGFloat(i) * left
            if CGRect(x: x, y: 0, width: cardSize.width, height: cardSize.height).contains(point) {
                vm.tapHome(i)
                return
            }
        }
        let freeStartX = boardSize.width - 14 - CGFloat(freeCellCount) * cardSize.width - CGFloat(freeCellCount - 1) * gap
        for i in 0..<freeCellCount {
            let x = freeStartX + CGFloat(i) * left
            if CGRect(x: x, y: 0, width: cardSize.width, height: cardSize.height).contains(point) {
                handleFreeCellTap(index: i)
                return
            }
        }
    }

    private func handleColumnTap(at point: CGPoint, boardSize: CGSize, cardSize: CGSize) {
        let gap: CGFloat = 2
        let left = cardSize.width + gap
        let colsStartX = columnsStartX(boardSize: boardSize, cardSize: cardSize)
        let col = Int((point.x - colsStartX) / left)
        guard col >= 0, col < columnCount else { return }
        let columnsStartY = cardSize.height * 1.3 + 10
        let step = effectiveStep(cardSize: cardSize, boardSize: boardSize)

        let cardCount: Int
        if let s = vm.spider {
            cardCount = s.columns[col].count
        } else if let k = vm.klondike {
            cardCount = k.columns[col].count
        } else if let y = vm.yukon {
            cardCount = y.columns[col].count
        } else if let f = vm.fortyThieves {
            cardCount = f.columns[col].count
        } else if let g = vm.golf {
            cardCount = g.columns[col].count
        } else if let s = vm.scorpion {
            cardCount = s.columns[col].count
        } else {
            cardCount = vm.game.columns[col].count
        }
        guard cardCount > 0 else { return }

        let yOffset = point.y - columnsStartY
        guard yOffset >= 0 else { return }
        let lastCardBottom = CGFloat(cardCount - 1) * step + cardSize.height
        guard yOffset <= lastCardBottom else { return }
        let i = min(Int(yOffset / step), cardCount - 1)

        if vm.spider != nil {
            handleSpiderCardTap(column: col, cardIndex: i)
        } else if vm.klondike != nil {
            handleKlondikeCardTap(column: col, cardIndex: i)
        } else if vm.yukon != nil {
            handleYukonCardTap(column: col, cardIndex: i)
        } else if vm.fortyThieves != nil {
            handleFortyThievesCardTap(column: col, cardIndex: i)
        } else if vm.golf != nil {
            vm.tapGolfColumn(column: col, cardIndex: i)
        } else if vm.scorpion != nil {
            handleScorpionCardTap(column: col, cardIndex: i)
        } else {
            handleCardTap(column: col, cardIndex: i)
        }
    }

    /// 타블로 열 묶음이 중앙 정렬될 때 첫 열의 좌측 x(보드 좌표)
    private func columnsStartX(boardSize: CGSize, cardSize: CGSize) -> CGFloat {
        let columnsRowWidth = CGFloat(columnCount) * cardSize.width + 2 * CGFloat(columnCount - 1)
        return 14 + (boardSize.width - 28 - columnsRowWidth) / 2
    }

    /// 드래그 시작 위치(보드 좌표)에서 잡은 카드 소스 판정
    private func dragSource(at point: CGPoint, boardSize: CGSize, cardSize: CGSize) -> (source: CardSource, cardCount: Int, topIndex: Int)? {
        let gap: CGFloat = 2
        let left = cardSize.width + gap
        let columnsStartY = cardSize.height * 1.3 + 10
        let step = effectiveStep(cardSize: cardSize, boardSize: boardSize)

        if vm.pyramid != nil {
            // 상단(스톡/웨이스트)은 드래그 소스 없음 — 노출 피라미드 카드만 드래그 가능
            if point.y < columnsStartY { return nil }
            for i in 0..<PyramidGame.pyramidCount {
                guard let p = vm.pyramid, p.pyramid[i] != nil, p.isExposed(i) else { continue }
                let origin = pyramidCardOrigin(index: i, cardSize: cardSize, boardSize: boardSize)
                let rect = CGRect(x: origin.x, y: origin.y, width: cardSize.width, height: cardSize.height)
                if rect.contains(point) { return (.pyramid(i), 1, i) }
            }
            return nil
        }

        if vm.triPeaks != nil {
            // 상단(스톡/웨이스트)은 드래그 소스 없음 — 노출 피크 카드만 드래그 가능
            if point.y < columnsStartY { return nil }
            for i in 0..<TriPeaksGame.totalPeaksCount {
                guard let t = vm.triPeaks, t.peaks[i] != nil, t.isExposed(i) else { continue }
                let origin = triPeaksCardOrigin(index: i, cardSize: cardSize, boardSize: boardSize)
                let rect = CGRect(x: origin.x, y: origin.y, width: cardSize.width, height: cardSize.height)
                if rect.contains(point) { return (.triPeaks(i), 1, i) }
            }
            return nil
        }

        if point.y < columnsStartY {
            if vm.spider != nil {
                // 스파이더 상단은 스톡/완성 표시만 — 드래그 소스 없음
                return nil
            }
            if vm.klondike != nil {
                // 스톡/웨이스트 (좌), 홈셀(우)
                let stockX: CGFloat = 14
                let wasteX = stockX + left
                if point.x >= wasteX, point.x <= wasteX + cardSize.width {
                    if vm.klondike?.waste.last != nil { return (.waste, 1, 0) }
                    return nil
                }
                let homeStartX = boardSize.width - 14 - CGFloat(KlondikeGame.homeCount) * cardSize.width - CGFloat(KlondikeGame.homeCount - 1) * gap
                for i in 0..<KlondikeGame.homeCount {
                    let x = homeStartX + CGFloat(i) * left
                    if point.x >= x, point.x <= x + cardSize.width {
                        return nil
                    }
                }
                return nil
            }
            if vm.fortyThieves != nil {
                // 스톡/웨이스트 (좌), 홈셀(우) — 스톡/홈셀은 드래그 소스 없음
                let stockX: CGFloat = 14
                let wasteX = stockX + left
                if point.x >= wasteX, point.x <= wasteX + cardSize.width {
                    if vm.fortyThieves?.waste.last != nil { return (.waste, 1, 0) }
                    return nil
                }
                return nil
            }
            if vm.golf != nil {
                // 스톡/웨이스트만 — 드래그 소스 없음 (웨이스트는 기준 카드)
                return nil
            }
            if vm.yukon != nil {
                // 유콘 상단은 홈셀만 — 드래그 소스 없음 (홈셀에서 꺼내기 없음)
                return nil
            }
            if vm.scorpion != nil {
                // 스콜피온 상단은 예비 더미만 — 드래그 소스 없음 (탭으로 딜)
                return nil
            }
            for i in 0..<FreeCellGame.homeCount {
                let x = 14 + CGFloat(i) * left
                if point.x >= x, point.x <= x + cardSize.width {
                    if vm.game.homes[i].last != nil { return (.home(i), 1, 0) }
                    return nil
                }
            }
            let freeStartX = boardSize.width - 14 - CGFloat(freeCellCount) * cardSize.width - CGFloat(freeCellCount - 1) * gap
            for i in 0..<freeCellCount {
                let x = freeStartX + CGFloat(i) * left
                if point.x >= x, point.x <= x + cardSize.width {
                    if vm.game.freeCells[i] != nil { return (.freeCell(i), 1, 0) }
                    return nil
                }
            }
            return nil
        }

        let colsStartX = columnsStartX(boardSize: boardSize, cardSize: cardSize)
        let col = Int((point.x - colsStartX) / left)
        guard col >= 0, col < columnCount else { return nil }
        if let s = vm.spider {
            let cards = s.columns[col]
            guard !cards.isEmpty else { return nil }
            let lastIndex = cards.count - 1
            let yOffset = point.y - columnsStartY
            guard yOffset >= 0 else { return nil }
            let lastCardBottom = CGFloat(lastIndex) * step + cardSize.height
            guard yOffset <= lastCardBottom else { return nil }
            let i = min(Int(yOffset / step), lastIndex)
            let fromBottom = cards.count - 1 - i
            let run = s.movableRun(from: col)
            guard fromBottom < run.count else { return nil }
            return (.column(col), fromBottom + 1, i)
        }
        if let k = vm.klondike {
            let cards = k.columns[col]
            guard !cards.isEmpty else { return nil }
            let lastIndex = cards.count - 1
            let yOffset = point.y - columnsStartY
            guard yOffset >= 0 else { return nil }
            let lastCardBottom = CGFloat(lastIndex) * step + cardSize.height
            guard yOffset <= lastCardBottom else { return nil }
            let i = min(Int(yOffset / step), lastIndex)
            let fromBottom = cards.count - 1 - i
            let run = k.movableRun(from: col)
            guard fromBottom < run.count else { return nil }
            return (.column(col), fromBottom + 1, i)
        }
        if let y = vm.yukon {
            let cards = y.columns[col]
            guard !cards.isEmpty else { return nil }
            let lastIndex = cards.count - 1
            let yOffset = point.y - columnsStartY
            guard yOffset >= 0 else { return nil }
            let lastCardBottom = CGFloat(lastIndex) * step + cardSize.height
            guard yOffset <= lastCardBottom else { return nil }
            let i = min(Int(yOffset / step), lastIndex)
            guard cards[i].faceUp else { return nil }
            let fromBottom = cards.count - 1 - i
            let run = y.movableGroup(from: col, topIndex: i) ?? []
            guard fromBottom < run.count else { return nil }
            return (.column(col), fromBottom + 1, i)
        }
        if let f = vm.fortyThieves {
            let cards = f.columns[col]
            guard !cards.isEmpty else { return nil }
            let lastIndex = cards.count - 1
            let yOffset = point.y - columnsStartY
            guard yOffset >= 0 else { return nil }
            let lastCardBottom = CGFloat(lastIndex) * step + cardSize.height
            guard yOffset <= lastCardBottom else { return nil }
            let i = min(Int(yOffset / step), lastIndex)
            let fromBottom = cards.count - 1 - i
            let run = f.movableRun(from: col)
            guard fromBottom < run.count else { return nil }
            return (.column(col), fromBottom + 1, i)
        }
        if let g = vm.golf {
            let cards = g.columns[col]
            guard !cards.isEmpty else { return nil }
            let lastIndex = cards.count - 1
            let yOffset = point.y - columnsStartY
            guard yOffset >= 0 else { return nil }
            let lastCardBottom = CGFloat(lastIndex) * step + cardSize.height
            guard yOffset <= lastCardBottom else { return nil }
            let i = min(Int(yOffset / step), lastIndex)
            // 골프는 맨 아래 카드만 제거 가능 (카드 1장 드래그)
            guard i == lastIndex else { return nil }
            return (.column(col), 1, i)
        }
        if let s = vm.scorpion {
            let cards = s.columns[col]
            guard !cards.isEmpty else { return nil }
            let lastIndex = cards.count - 1
            let yOffset = point.y - columnsStartY
            guard yOffset >= 0 else { return nil }
            let lastCardBottom = CGFloat(lastIndex) * step + cardSize.height
            guard yOffset <= lastCardBottom else { return nil }
            let i = min(Int(yOffset / step), lastIndex)
            guard cards[i].faceUp else { return nil }
            let fromBottom = cards.count - 1 - i
            let run = s.movableGroup(from: col, startIndex: i) ?? []
            guard fromBottom < run.count else { return nil }
            return (.column(col), fromBottom + 1, i)
        }
        let cards = vm.game.columns[col]
        guard !cards.isEmpty else { return nil }
        let lastIndex = cards.count - 1
        let yOffset = point.y - columnsStartY
        guard yOffset >= 0 else { return nil }
        let lastCardBottom = CGFloat(lastIndex) * step + cardSize.height
        guard yOffset <= lastCardBottom else { return nil }
        let i = min(Int(yOffset / step), lastIndex)
        let fromBottom = cards.count - 1 - i
        let run = FreeCellRule.movableRun(from: cards)
        guard fromBottom < run.count else { return nil }
        return (.column(col), fromBottom + 1, i)
    }

    /// 원본 카드 위치(보드 좌표) — 드래그 시 카드가 정확히 이 위치에서 시작해 마우스를 따라다님
    private func cardBoardOrigin(_ source: CardSource, topIndex: Int, cardSize: CGSize, boardSize: CGSize) -> CGPoint {
        let gap: CGFloat = 2
        let left = cardSize.width + gap
        let columnsStartY = cardSize.height * 1.3 + 10
        let topRowCardY = (cardSize.height * 1.3 - cardSize.height) / 2
        switch source {
        case .column(let col):
            let colsStartX = columnsStartX(boardSize: boardSize, cardSize: cardSize)
            let step = effectiveStep(cardSize: cardSize, boardSize: boardSize)
            return CGPoint(
                x: colsStartX + CGFloat(col) * left,
                y: columnsStartY + CGFloat(topIndex) * step
            )
        case .freeCell(let i):
            let freeStartX = boardSize.width - 14 - CGFloat(freeCellCount) * cardSize.width - CGFloat(freeCellCount - 1) * gap
            return CGPoint(x: freeStartX + CGFloat(i) * left, y: topRowCardY)
        case .home(let i):
            return CGPoint(x: 14 + CGFloat(i) * left, y: topRowCardY)
        case .waste:
            let stockX: CGFloat = 14
            return CGPoint(x: stockX + left, y: topRowCardY)
        case .pyramid(let index):
            return pyramidCardOrigin(index: index, cardSize: cardSize, boardSize: boardSize)
        case .triPeaks(let index):
            return triPeaksCardOrigin(index: index, cardSize: cardSize, boardSize: boardSize)
        }
    }

    /// 피라미드 카드의 보드 좌표 (렌더와 동일한 배치 로직)
    private func pyramidCardOrigin(index: Int, cardSize: CGSize, boardSize: CGSize) -> CGPoint {
        let row = pyramidRowOf(index)
        let pos = index - PyramidGame.rowStart(row)
        let rowCount = row + 1
        let hGap = cardSize.width * 0.55
        let rowHeight = cardSize.height * 0.65
        let columnsStartY = cardSize.height * 1.3 + 10
        let totalWidth = CGFloat(rowCount) * cardSize.width + CGFloat(rowCount - 1) * hGap
        let x = (boardSize.width - totalWidth) / 2 + CGFloat(pos) * (cardSize.width + hGap)
        let y = columnsStartY + CGFloat(row) * rowHeight
        return CGPoint(x: x, y: y)
    }

    /// 글로벌 인덱스가 속한 피라미드 줄 (0~6)
    private func pyramidRowOf(_ index: Int) -> Int {
        var row = 0
        while PyramidGame.rowStart(row + 1) <= index { row += 1 }
        return row
    }

    /// TriPeaks 카드의 보드 좌표 (렌더·드래그·드롭 공유 — 3피크 가로 배치)
    private func triPeaksCardOrigin(index: Int, cardSize: CGSize, boardSize: CGSize) -> CGPoint {
        let (peak, local) = TriPeaksGame.peakAndLocal(of: index)
        var row = 0
        while TriPeaksGame.rowStart(row + 1) <= local { row += 1 }
        let pos = local - TriPeaksGame.rowStart(row)
        let rowCount = row + 1

        let hGap = cardSize.width * 0.55
        let rowHeight = cardSize.height * 0.65
        let peakGap = cardSize.width * 1.0
        let peakWidth = CGFloat(TriPeaksGame.rowsPerPeak) * cardSize.width + CGFloat(TriPeaksGame.rowsPerPeak - 1) * hGap
        let totalWidth = CGFloat(TriPeaksGame.peakCount) * peakWidth + CGFloat(TriPeaksGame.peakCount - 1) * peakGap
        let columnsStartY = cardSize.height * 1.3 + 10

        let peakStartX = (boardSize.width - totalWidth) / 2 + CGFloat(peak) * (peakWidth + peakGap)
        let rowWidth = CGFloat(rowCount) * cardSize.width + CGFloat(rowCount - 1) * hGap
        let x = peakStartX + (peakWidth - rowWidth) / 2 + CGFloat(pos) * (cardSize.width + hGap)
        let y = columnsStartY + CGFloat(row) * rowHeight
        return CGPoint(x: x, y: y)
    }

    /// 드래그 종료 시 마우스 포인트 위치로 드롭 목적지 판단 후 이동
    private func finishDrag(boardSize: CGSize, cardSize: CGSize) {
        guard let drag else { return }
        let target = dropTarget(at: drag.location, boardSize: boardSize, cardSize: cardSize)
        if let target {
            _ = vm.move(cardAt: drag.source, cardCount: drag.cardCount, to: target)
        }
        self.drag = nil
    }

    /// 보드 좌표 기반 드롭 목적지 결정
    private func dropTarget(at point: CGPoint, boardSize: CGSize, cardSize: CGSize) -> Destination? {
        let gap: CGFloat = 2
        let left = cardSize.width + gap
        let columnsStartY = cardSize.height * 1.3 + 10
        if point.y < columnsStartY {
            if vm.spider != nil {
                // 스파이더 상단은 드롭 목적지 없음
                return nil
            }
            if vm.klondike != nil {
                let homeStartX = boardSize.width - 14 - CGFloat(KlondikeGame.homeCount) * cardSize.width - CGFloat(KlondikeGame.homeCount - 1) * gap
                for i in 0..<KlondikeGame.homeCount {
                    let x = homeStartX + CGFloat(i) * left
                    if point.x >= x, point.x <= x + cardSize.width { return .home(i) }
                }
                return nil
            }
            if vm.fortyThieves != nil {
                let homeStartX = boardSize.width - 14 - CGFloat(FortyThievesGame.homeCount) * cardSize.width - CGFloat(FortyThievesGame.homeCount - 1) * gap
                for i in 0..<FortyThievesGame.homeCount {
                    let x = homeStartX + CGFloat(i) * left
                    if point.x >= x, point.x <= x + cardSize.width { return .home(i) }
                }
                return nil
            }
            if vm.golf != nil {
                // Golf 웨이스트(좌)가 드롭 목적지
                let stockX: CGFloat = 14
                let wasteX = stockX + left
                if point.x >= wasteX, point.x <= wasteX + cardSize.width { return .waste }
                return nil
            }
            if vm.pyramid != nil {
                // Pyramid 웨이스트(좌)가 드롭 목적지 (피라미드 카드 → 웨이스트 짝 제거)
                let stockX: CGFloat = 14
                let wasteX = stockX + left
                if point.x >= wasteX, point.x <= wasteX + cardSize.width { return .waste }
                return nil
            }
            if vm.triPeaks != nil {
                // TriPeaks 웨이스트(좌)가 드롭 목적지 (피크 카드 → 웨이스트 제거)
                let stockX: CGFloat = 14
                let wasteX = stockX + left
                if point.x >= wasteX, point.x <= wasteX + cardSize.width { return .waste }
                return nil
            }
            if vm.yukon != nil {
                let homeStartX = boardSize.width - 14 - CGFloat(YukonGame.homeCount) * cardSize.width - CGFloat(YukonGame.homeCount - 1) * gap
                for i in 0..<YukonGame.homeCount {
                    let x = homeStartX + CGFloat(i) * left
                    if point.x >= x, point.x <= x + cardSize.width { return .home(i) }
                }
                return nil
            }
            for i in 0..<FreeCellGame.homeCount {
                let x = 14 + CGFloat(i) * left
                if point.x >= x, point.x <= x + cardSize.width { return .home(i) }
            }
            let freeStartX = boardSize.width - 14 - CGFloat(freeCellCount) * cardSize.width - CGFloat(freeCellCount - 1) * gap
            for i in 0..<freeCellCount {
                let x = freeStartX + CGFloat(i) * left
                if point.x >= x, point.x <= x + cardSize.width { return .freeCell(i) }
            }
        } else {
            let colsStartX = columnsStartX(boardSize: boardSize, cardSize: cardSize)
            let col = Int((point.x - colsStartX) / left)
            if col >= 0, col < columnCount { return .column(col) }
        }
        return nil
    }

    /// 드래그된 카드가 원본 위치에서 시작해 마우스 이동을 그대로 따라가는 오버레이
    /// (보드와 동일하게 카드가 0.42 겹쳐 쌓임 — 간격은 step = 카드높이 - 겹침)
    /// 잡은 카드(원본 topIndex = 오버레이 i=0)가 커서를 정확히 추종하도록 위치 보정.
    private func dragOverlay(_ drag: DragState, cardSize: CGSize, boardSize: CGSize) -> some View {
        let cards = draggedCards(for: drag)
        let padding: CGFloat = 6
        let step = effectiveStep(cardSize: cardSize, boardSize: boardSize)
        let count = max(cards.count, 1)
        let contentHeight = CGFloat(count - 1) * step + cardSize.height
        let fullWidth = cardSize.width + padding * 2
        let fullHeight = contentHeight + padding * 2
        // 카드 0(잡은 카드)이 프레임 top-left+padding에 배치되므로 center 기준 오프셋에서 padding만큼 보정.
        let dx = drag.startCardOrigin.x + fullWidth / 2 - drag.startLocation.x - padding
        let dy = drag.startCardOrigin.y + fullHeight / 2 - drag.startLocation.y - padding
        return ZStack(alignment: .topLeading) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { i, card in
                CardView(card: card, style: settings.cardStyle)
                    .frame(width: cardSize.width, height: cardSize.height)
                    .offset(y: CGFloat(i) * step)
            }
        }
        .frame(width: cardSize.width, height: contentHeight, alignment: .topLeading)
        .padding(padding)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.06)))
        .compositingGroup()
        .shadow(radius: 6)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .position(
            x: drag.location.x + dx,
            y: drag.location.y + dy
        )
    }

    private func draggedCards(for drag: DragState) -> [Card] {
        switch drag.source {
        case .column(let i):
            if let s = vm.spider {
                return s.columns[i].suffix(drag.cardCount).map(\.card)
            }
            if let k = vm.klondike {
                return k.columns[i].suffix(drag.cardCount).map(\.card)
            }
            if let y = vm.yukon {
                return y.columns[i].suffix(drag.cardCount).map(\.card)
            }
            if let f = vm.fortyThieves {
                return Array(f.columns[i].suffix(drag.cardCount))
            }
            if let g = vm.golf {
                return Array(g.columns[i].suffix(drag.cardCount))
            }
            return Array(vm.game.columns[i].suffix(drag.cardCount))
        case .freeCell(let i):
            return vm.game.freeCells[i].map { [$0] } ?? []
        case .home(let i):
            return vm.game.homes[i].last.map { [$0] } ?? []
        case .waste:
            return vm.klondike?.waste.last.map { [$0] }
                ?? vm.fortyThieves?.waste.last.map { [$0] }
                ?? []
        case .pyramid(let i):
            return vm.pyramid?.pyramid[i].map { [$0] } ?? []
        case .triPeaks(let i):
            return vm.triPeaks?.peaks[i].map { [$0] } ?? []
        }
    }
}

private extension View {
    @ViewBuilder
    func ifApply<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
