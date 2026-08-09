import SwiftUI
import GameCore

/// 게임 번호 선택 시트 — 변형 선택은 "게임 시작" 누를 때 반영 (즉시 시작 금지)
/// 변형별 옵션(난이도 등)은 `GameVariant.optionDefinitions`를 순회해 자동 렌더링.
struct GameNumberSheet: View {
    @EnvironmentObject private var vm: FreeCellViewModel
    @EnvironmentObject private var settings: UserSettings
    @Environment(\.dismiss) private var dismiss
    @State private var selectedVariant: GameVariant = .freecell
    @State private var optionSelections: [String: String] = [:]

    private var boardColor: Color {
        settings.backgroundColor(for: settings.background)
    }

    var body: some View {
        VStack(spacing: 18) {
            Text("게임 번호 선택")
                .font(.title2.bold())
            Text("1 ~ 1,000,000 사이의 게임 번호를 입력하면\n선택한 게임으로 해당 번호의 배치가 시작됩니다.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            GameSelectorView(selection: $selectedVariant, boardColor: boardColor)
                .frame(width: 440, height: 420)

            ForEach(selectedVariant.optionDefinitions) { option in
                Picker(option.title, selection: optionBinding(for: option.id, fallback: option.choices.first?.id ?? "")) {
                    ForEach(option.choices) { choice in
                        Text(choice.title).tag(choice.id)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
                .accessibilityLabel(option.title)
            }

            TextField("게임 번호", text: $vm.gameNumberText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
                .multilineTextAlignment(.center)
                .onSubmit { startGame() }

            HStack(spacing: 12) {
                Button("취소") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("게임 시작") { startGame() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .onAppear {
            selectedVariant = vm.variant
            optionSelections = selections(for: selectedVariant)
        }
        .onChange(of: selectedVariant) { newVariant in
            optionSelections = selections(for: newVariant)
        }
    }

    private func selections(for variant: GameVariant) -> [String: String] {
        variant.optionDefinitions.reduce(into: [:]) { result, option in
            result[option.id] = vm.gameOptions.selectedID(for: variant, option: option)
        }
    }

    private func optionBinding(for id: String, fallback: String) -> Binding<String> {
        Binding(
            get: { optionSelections[id] ?? fallback },
            set: { optionSelections[id] = $0 }
        )
    }

    /// 선택한 변형의 옵션을 저장하고 게임 시작
    private func startGame() {
        for option in selectedVariant.optionDefinitions {
            if let id = optionSelections[option.id] {
                vm.gameOptions.setSelectedID(id, for: selectedVariant, optionID: option.id)
            }
        }
        vm.applyGameNumber(variant: selectedVariant)
    }
}
