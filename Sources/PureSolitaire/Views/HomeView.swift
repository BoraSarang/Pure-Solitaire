import SwiftUI
import GameCore

/// 홈 화면 — 앱 시작 시 먼저 표시. 카테고리 섹션 게임 그리드 + 진입 항목 (T-224)
struct HomeView: View {
    @EnvironmentObject private var vm: FreeCellViewModel
    @EnvironmentObject private var settings: UserSettings
    /// 게임 시작 시 홈을 닫고 게임 화면으로 전환하는 클로저 (ContentView에서 주입)
    let onStartGame: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    quickActions
                    categorySections
                }
                .padding(24)
            }
        }
        .background(BackgroundLayer(settings: settings))
    }

    // MARK: - 상단 헤더

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("순수한 솔리테어")
                    .font(.largeTitle.bold())
                Text("Pure Solitaire")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: - 빠른 진입 (데일리/게임 번호/무작위)

    private var quickActions: some View {
        HStack(spacing: 12) {
            quickButton(
                icon: "calendar.badge.checkmark",
                title: "데일리 도전",
                subtitle: "하루 9판",
                shortcut: "⌥⌘D"
            ) {
                vm.showingChallenge = true
            }
            quickButton(
                icon: "number",
                title: "게임 번호",
                subtitle: "1~1,000,000",
                shortcut: "⌘G"
            ) {
                vm.showingGameNumber = true
            }
            quickButton(
                icon: "shuffle",
                title: "무작위 게임",
                subtitle: "아무 게임",
                shortcut: ""
            ) {
                onStartGame()
                vm.requestNewGame()
            }
            Spacer()
            infoButtonGroup
        }
    }

    private func quickButton(icon: String, title: String, subtitle: String, shortcut: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                Text(title)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 120, height: 74, alignment: .leading)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
        }
        .buttonStyle(.plain)
        .help(shortcut.isEmpty ? title : "\(title) (\(shortcut))")
        .accessibilityLabel("\(title) \(subtitle)")
    }

    // MARK: - 통계/업적/설정

    private var infoButtonGroup: some View {
        HStack(spacing: 8) {
            iconButton(icon: "chart.bar.fill", title: "통계", shortcut: "⌘T") { vm.showingStats = true }
            iconButton(icon: "trophy.fill", title: "업적", shortcut: "⌥⌘T") { vm.showingAchievements = true }
            iconButton(icon: "gearshape.fill", title: "설정", shortcut: "⌘,") { vm.showingSettings = true }
        }
    }

    private func iconButton(icon: String, title: String, shortcut: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.08)))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .help("\(title) (\(shortcut))")
        .accessibilityLabel(title)
    }

    // MARK: - 카테고리 섹션

    private var categorySections: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(GameCategory.allCases, id: \.self) { category in
                categorySection(category)
            }
        }
    }

    private func categorySection(_ category: GameCategory) -> some View {
        let variants = GameVariant.homeOrderedVariants.filter { $0.category == category }
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(category.displayName)
                    .font(.title3.bold())
                Text("\(variants.count)종")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4),
                spacing: 16
            ) {
                ForEach(variants, id: \.self) { variant in
                    homeTile(variant)
                }
            }
        }
    }

    private func homeTile(_ variant: GameVariant) -> some View {
        let boardColor = settings.backgroundColor(for: settings.background)
        return Button {
            onStartGame()
            vm.requestNewGame(variant: variant)
        } label: {
            VStack(spacing: 8) {
                GamePreviewCard(variant: variant, isSelected: false, boardColor: boardColor)
                HStack(spacing: 5) {
                    Text(variant.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    difficultyBadge(variant.baseDifficulty)
                }
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.06)))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(variant.displayName) 게임 시작, 난이도 \(difficultyText(variant.baseDifficulty))")
    }

    private func difficultyBadge(_ difficulty: Difficulty) -> some View {
        Text(difficultyText(difficulty))
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(Capsule().fill(difficultyColor(difficulty).opacity(0.15)))
            .foregroundStyle(difficultyColor(difficulty))
    }

    private func difficultyText(_ difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy: "쉬움"
        case .medium: "보통"
        case .hard: "어려움"
        case .unmeasured: "미측정"
        }
    }

    private func difficultyColor(_ difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy: .green
        case .medium: .orange
        case .hard: .red
        case .unmeasured: .gray
        }
    }
}