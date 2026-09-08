import SwiftUI
import GameCore

/// 게임 선택 그리드 — 카테고리 4그룹 섹션 + 그룹 내 난이도순 + 난이도 뱃지 (T-223)
struct GameSelectorView: View {
    @Binding var selection: GameVariant
    let boardColor: Color
    @EnvironmentObject private var settings: UserSettings

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(GameCategory.allCases, id: \.self) { category in
                    categorySection(category)
                }
            }
            .padding(6)
        }
        .accessibilityLabel("게임 선택")
    }

    private func categorySection(_ category: GameCategory) -> some View {
        let variants = GameVariant.visibleVariants(mode: settings.gameMode)
            .filter { $0.category == category }
            .sorted { lhs, rhs in
                let ld = difficultyRank(lhs.baseDifficulty)
                let rd = difficultyRank(rhs.baseDifficulty)
                if ld != rd { return ld < rd }
                return lhs.categoryOrder < rhs.categoryOrder
            }
        if variants.isEmpty {
            return AnyView(EmptyView())
        }
        return AnyView(VStack(alignment: .leading, spacing: 8) {
            Text(category.displayName)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(variants, id: \.self) { variant in
                    GameTile(
                        variant: variant,
                        isSelected: selection == variant,
                        boardColor: boardColor
                    ) {
                        selection = variant
                    }
                }
            }
        })
    }

    private func difficultyRank(_ d: Difficulty) -> Int {
        switch d {
        case .easy: 0
        case .medium: 1
        case .hard: 2
        case .unmeasured: 3
        }
    }
}

/// 개별 게임 타일 — 미리보기 카드 + 게임명 + 난이도 뱃지
private struct GameTile: View {
    let variant: GameVariant
    let isSelected: Bool
    let boardColor: Color
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        VStack(spacing: 6) {
            GamePreviewCard(variant: variant, isSelected: isSelected, boardColor: boardColor)
            Text(variant.displayName)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? Color.blue : Color.secondary)
                .lineLimit(1)
            difficultyBadge
        }
        .padding(6)
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture { action() }
        .onHover { hovered = $0 }
        .scaleEffect(hovered && !isSelected ? 1.04 : 1)
        .animation(.easeOut(duration: 0.15), value: hovered)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(variant.displayName) 게임, 난이도 \(difficultyText)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var difficultyText: String {
        switch variant.baseDifficulty {
        case .easy: "쉬움"
        case .medium: "보통"
        case .hard: "어려움"
        case .unmeasured: "미측정"
        }
    }

    private var difficultyColor: Color {
        switch variant.baseDifficulty {
        case .easy: .green
        case .medium: .orange
        case .hard: .red
        case .unmeasured: .gray
        }
    }

    private var difficultyBadge: some View {
        Text(difficultyText)
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(Capsule().fill(difficultyColor.opacity(0.15)))
            .foregroundStyle(difficultyColor)
    }
}