import SwiftUI
import GameCore

/// 게임 메뉴 기능을 좌우 사이드바에 아이콘으로 배치
struct SideBarView: View {
    enum Side {
        case left
        case right
    }

    let side: Side
    @EnvironmentObject private var vm: FreeCellViewModel
    @EnvironmentObject private var settings: UserSettings

    private var fg: Color {
        settings.background == .white ? Color.black : Color.white
    }

    var body: some View {
        VStack(spacing: 0) {
            switch side {
            case .left:
                gameGroup
            case .right:
                helpGroup
            }
            separator
            Spacer(minLength: 12)
            switch side {
            case .left:
                moveGroup
            case .right:
                infoGroup
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
        .padding(.horizontal, 6)
    }

    private var separator: some View {
        Rectangle()
            .fill(fg.opacity(0.2))
            .frame(width: 30, height: 1)
            .padding(.vertical, 10)
    }

    // MARK: - 게임 (좌측 상단)

    private var gameGroup: some View {
        VStack(spacing: 6) {
            SideBarButton(icon: "house.fill", title: "홈", shortcut: "⌘1", fg: fg) {
                vm.goHome()
            }
            SideBarButton(icon: "rectangle.stack.fill", title: "새 게임", shortcut: "⌘N", fg: fg) {
                vm.requestNewGame()
            }
            SideBarButton(icon: "number", title: "게임 번호", shortcut: "⌘G", fg: fg) {
                vm.showingGameNumber = true
            }
            SideBarButton(icon: "calendar", title: "데일리 딜", shortcut: "⌘D", fg: fg) {
                vm.startDailyDeal()
            }
            SideBarButton(icon: "arrow.left.arrow.right", title: "게임 전환", shortcut: "", fg: fg) {
                vm.switchToRandomGame()
            }
        }
    }

    // MARK: - 이동 (좌측 하단)

    private var moveGroup: some View {
        VStack(spacing: 6) {
            SideBarButton(icon: "arrow.uturn.backward", title: "실행 취소", shortcut: "⌘Z", isEnabled: vm.canUndo(), fg: fg) {
                vm.undo()
            }
            SideBarButton(icon: "arrow.uturn.forward", title: "다시 실행", shortcut: "⇧⌘Z", isEnabled: vm.canRedo(), fg: fg) {
                vm.redo()
            }
        }
    }

    // MARK: - 도움 (우측 상단)

    private var helpGroup: some View {
        VStack(spacing: 6) {
            SideBarButton(
                icon: "play.rectangle.fill",
                title: "자동 풀어 보기",
                shortcut: "⇧⌘P",
                isEnabled: vm.canAutoSolve,
                fg: fg
            ) {
                vm.startAutoSolve()
            }
            SideBarButton(
                icon: "arrow.counterclockwise",
                title: "내 이동 리플레이",
                shortcut: "⇧⌘R",
                isEnabled: vm.canReplay,
                fg: fg
            ) {
                vm.startReplay()
            }
            SideBarButton(icon: "lightbulb.fill", title: "힌트", shortcut: "⌘H", fg: fg) {
                vm.hint()
            }
            SideBarButton(
                icon: "lightbulb.max.fill",
                title: "전체 힌트",
                shortcut: "⇧⌘H",
                isActive: vm.showAllHints,
                accessibilityValue: vm.showAllHints ? "켜짐" : "꺼짐",
                fg: fg
            ) {
                vm.toggleAllHints()
            }
            SideBarButton(
                icon: "wand.and.stars",
                title: "자동 플레이",
                shortcut: "⇧⌘A",
                isActive: settings.autoPlayEnabled,
                accessibilityValue: settings.autoPlayEnabled ? "켜짐" : "꺼짐",
                fg: fg
            ) {
                settings.autoPlayEnabled.toggle()
                if settings.autoPlayEnabled {
                    vm.runAutoPlay()
                }
            }
        }
    }

    // MARK: - 정보 (우측 하단)

    private var infoGroup: some View {
        VStack(spacing: 6) {
            SideBarButton(icon: "calendar.badge.checkmark", title: "챌린지", shortcut: "⌥⌘D", fg: fg) {
                vm.showingChallenge = true
            }
            SideBarButton(icon: "trophy.fill", title: "업적", shortcut: "⌥⌘T", fg: fg) {
                vm.showingAchievements = true
            }
            SideBarButton(icon: "chart.bar.fill", title: "통계", shortcut: "⌘T", fg: fg) {
                vm.showingStats = true
            }
            SideBarButton(icon: "gearshape.fill", title: "설정", shortcut: "⌘,", fg: fg) {
                vm.showingSettings = true
            }
        }
    }
}

/// 아이콘 + 라벨 버튼
struct SideBarButton: View {
    let icon: String
    let title: String
    let shortcut: String
    var isEnabled = true
    var isActive: Bool?
    var accessibilityValue: String?
    let fg: Color
    let action: () -> Void

    init(
        icon: String,
        title: String,
        shortcut: String,
        isEnabled: Bool = true,
        isActive: Bool? = nil,
        accessibilityValue: String? = nil,
        fg: Color,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.shortcut = shortcut
        self.isEnabled = isEnabled
        self.isActive = isActive
        self.accessibilityValue = accessibilityValue
        self.fg = fg
        self.action = action
    }

    private var showActive: Bool { isActive == true }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(showActive ? Color.white : fg)
                    .frame(width: 44, height: 44)
                    .background(showActive ? Color.accentColor : fg.opacity(isEnabled ? 0.14 : 0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(showActive ? fg : fg.opacity(0.85))
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isActive == false ? 0.5 : (isEnabled ? 1 : 0.35))
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValue ?? "")
        .accessibilityHint("단축키 \(shortcut)")
        .help("\(title) (\(shortcut))")
    }
}
