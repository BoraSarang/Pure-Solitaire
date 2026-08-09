import SwiftUI

/// 앱 메뉴 / 단축키
struct GameCommands: Commands {
    let viewModel: FreeCellViewModel
    let settings: UserSettings

    private func zoomIn() {
        settings.boardScale = min(1.4, settings.boardScale + 0.1)
    }

    private func zoomOut() {
        settings.boardScale = max(0.7, settings.boardScale - 0.1)
    }

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("새 게임") { viewModel.requestNewGame() }
                .keyboardShortcut("n", modifiers: .command)
        }

        CommandMenu("게임") {
            Button("게임 번호...") { viewModel.showingGameNumber = true }
                .keyboardShortcut("g", modifiers: .command)

            Divider()

            Button("실행 취소") { viewModel.undo() }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!viewModel.canUndo())
            Button("다시 실행") { viewModel.redo() }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!viewModel.canRedo())

            Divider()

            Button("힌트") { viewModel.hint() }
                .keyboardShortcut("h", modifiers: .command)
            Button("전체 힌트") { viewModel.toggleAllHints() }
                .keyboardShortcut("h", modifiers: [.command, .shift])
            Button("힌트 적용") { _ = viewModel.applyHighlightedHint() }
                .keyboardShortcut(.return)
                .disabled(viewModel.highlightedMove == nil)
            Button {
                settings.autoPlayEnabled.toggle()
                if settings.autoPlayEnabled {
                    viewModel.runAutoPlay()
                }
            } label: {
                if settings.autoPlayEnabled {
                    Label("자동 플레이", systemImage: "checkmark")
                } else {
                    Text("자동 플레이")
                }
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])

            Divider()

            Button("선택 해제") { viewModel.clearSelection() }
                .keyboardShortcut(.cancelAction)
                .disabled(viewModel.selection == nil)
            Button("선택 카드 홈으로") { _ = viewModel.moveSelectionToHome() }
                .keyboardShortcut(" ", modifiers: [])
                .disabled(viewModel.selection == nil)

            Divider()

            Button("통계") { viewModel.showingStats = true }
                .keyboardShortcut("t", modifiers: .command)
            Button("설정...") { viewModel.showingSettings = true }
                .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("보드 확대") { zoomIn() }
                .keyboardShortcut("=", modifiers: .command)
            Button("보드 축소") { zoomOut() }
                .keyboardShortcut("-", modifiers: .command)
        }
    }
}
