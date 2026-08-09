import SwiftUI
import GameCore

// MARK: - 무늬 Shape (커스텀 벡터)

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.95))
        p.addCurve(to: CGPoint(x: 0, y: h * 0.40),
                    control1: CGPoint(x: w * 0.5, y: h * 0.75),
                    control2: CGPoint(x: 0, y: h * 0.60))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.20),
                    control1: CGPoint(x: 0, y: h * 0.15),
                    control2: CGPoint(x: w * 0.20, y: h * 0.05))
        p.addCurve(to: CGPoint(x: w, y: h * 0.40),
                    control1: CGPoint(x: w * 0.80, y: h * 0.05),
                    control2: CGPoint(x: w, y: h * 0.15))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.95),
                    control1: CGPoint(x: w, y: h * 0.60),
                    control2: CGPoint(x: w * 0.5, y: h * 0.75))
        p.closeSubpath()
        return p
    }
}

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addLine(to: CGPoint(x: w, y: h * 0.5))
        p.addLine(to: CGPoint(x: w * 0.5, y: h))
        p.addLine(to: CGPoint(x: 0, y: h * 0.5))
        p.closeSubpath()
        return p
    }
}

struct ClubShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.62))
        p.addCurve(to: CGPoint(x: w * 0.12, y: h * 0.30),
                    control1: CGPoint(x: w * 0.22, y: h * 0.60),
                    control2: CGPoint(x: w * 0.04, y: h * 0.50))
        p.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.36),
                    control1: CGPoint(x: w * 0.20, y: h * 0.08),
                    control2: CGPoint(x: w * 0.42, y: h * 0.20))
        p.addCurve(to: CGPoint(x: w * 0.88, y: h * 0.30),
                    control1: CGPoint(x: w * 0.58, y: h * 0.20),
                    control2: CGPoint(x: w * 0.96, y: h * 0.08))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.62),
                    control1: CGPoint(x: w * 0.96, y: h * 0.50),
                    control2: CGPoint(x: w * 0.78, y: h * 0.60))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h),
                    control1: CGPoint(x: w * 0.55, y: h * 0.75),
                    control2: CGPoint(x: w * 0.55, y: h * 0.92))
        p.closeSubpath()
        return p
    }
}

struct SpadeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.05))
        p.addCurve(to: CGPoint(x: 0, y: h * 0.45),
                    control1: CGPoint(x: w * 0.22, y: h * 0.08),
                    control2: CGPoint(x: 0, y: h * 0.22))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.58),
                    control1: CGPoint(x: 0, y: h * 0.66),
                    control2: CGPoint(x: w * 0.30, y: h * 0.62))
        p.addCurve(to: CGPoint(x: w, y: h * 0.45),
                    control1: CGPoint(x: w * 0.70, y: h * 0.62),
                    control2: CGPoint(x: w, y: h * 0.66))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.05),
                    control1: CGPoint(x: w, y: h * 0.22),
                    control2: CGPoint(x: w * 0.78, y: h * 0.08))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.95),
                    control1: CGPoint(x: w * 0.55, y: h * 0.68),
                    control2: CGPoint(x: w * 0.55, y: h * 0.90))
        p.closeSubpath()
        return p
    }
}

// MARK: - 무늬 심볼

struct SuitSymbolView: View {
    let suit: Suit

    var body: some View {
        Group {
            switch suit {
            case .hearts:
                HeartShape().fill(Color(red: 0.85, green: 0.10, blue: 0.10))
            case .diamonds:
                DiamondShape().fill(Color(red: 0.85, green: 0.10, blue: 0.10))
            case .clubs:
                ClubShape().fill(Color(red: 0.10, green: 0.10, blue: 0.10))
            case .spades:
                SpadeShape().fill(Color(red: 0.10, green: 0.10, blue: 0.10))
            }
        }
    }
}

// MARK: - 카드 뷰

struct CardView: View {
    let card: Card?
    let style: UserSettings.CardStyle
    var isHighlighted = false
    var isSelected = false
    var isHintSource = false
    var isPulsing = false
    var showBack = false
    var cardBack: UserSettings.CardBack = .classic
    var accessibilityHintText: String?

    private var isRed: Bool {
        card?.color == .red
    }

    private var faceColor: Color {
        isRed ? Color(red: 0.80, green: 0.10, blue: 0.10) : Color(red: 0.12, green: 0.12, blue: 0.12)
    }

    private var fontDesign: Font.Design {
        style == .classic ? .serif : .rounded
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.09)
                    .fill(background)
                RoundedRectangle(cornerRadius: w * 0.09)
                    .stroke(borderColor, lineWidth: isSelected ? 3 : 1.2)
                if showBack, card != nil {
                    backView(w: w, h: h)
                } else if let card {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(card.rank.label)
                            .font(.system(size: w * 0.30, weight: .bold, design: fontDesign))
                            .foregroundStyle(faceColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        SuitSymbolView(suit: card.suit)
                            .frame(width: w * 0.18, height: w * 0.18)
                    }
                    .frame(width: w * 0.24, alignment: .leading)
                    .position(x: w * 0.20, y: h * 0.20)

                    VStack(alignment: .trailing, spacing: 1) {
                        Text(card.rank.label)
                            .font(.system(size: w * 0.30, weight: .bold, design: fontDesign))
                            .foregroundStyle(faceColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        SuitSymbolView(suit: card.suit)
                            .frame(width: w * 0.18, height: w * 0.18)
                    }
                    .rotationEffect(.degrees(180))
                    .frame(width: w * 0.24, alignment: .trailing)
                    .position(x: w * 0.80, y: h * 0.80)

                    SuitSymbolView(suit: card.suit)
                        .frame(width: w * 0.62, height: w * 0.62)
                        .position(x: w * 0.5, y: h * 0.52)

                    if isSelected {
                        RoundedRectangle(cornerRadius: w * 0.09)
                            .stroke(Color.blue, lineWidth: 2)
                    } else if isHintSource {
                        RoundedRectangle(cornerRadius: w * 0.09)
                            .stroke(Color.yellow, lineWidth: 3)
                    } else if isPulsing {
                        RoundedRectangle(cornerRadius: w * 0.09)
                            .stroke(Color.green, lineWidth: 3)
                    }
                } else {
                    RoundedRectangle(cornerRadius: w * 0.09)
                        .strokeBorder(
                            Color.primary.opacity(0.25),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
                        )
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isSelected ? "선택됨" : "")
        .accessibilityHint(accessibilityHintText ?? "")
    }

    private var accessibilityLabel: String {
        if showBack, card != nil {
            return "뒷면 카드"
        }
        if let card {
            return "\(card.rank.label) \(card.suit.symbol)"
        }
        return "빈 자리"
    }

    /// 카드 뒷면 패턴 — `CardBackArtwork` 공용 컴포넌트 (설정 미리보기와 동일)
    private func backView(w: CGFloat, h: CGFloat) -> some View {
        CardBackArtwork(tint: cardBack.tint, accent: cardBack.accent)
    }

    private var background: Color {
        if card != nil {
            switch style {
            case .classic:
                Color.white
            case .simple:
                Color(red: 0.92, green: 0.93, blue: 0.90)
            }
        } else {
            if isHighlighted {
                Color.white.opacity(0.18)
            } else {
                Color.white.opacity(0.06)
            }
        }
    }

    private var borderColor: Color {
        if isSelected { return .blue }
        if card != nil {
            switch style {
            case .classic:
                return Color(red: 0.45, green: 0.45, blue: 0.45)
            case .simple:
                return Color(red: 0.70, green: 0.72, blue: 0.68)
            }
        }
        return Color.clear
    }
}
