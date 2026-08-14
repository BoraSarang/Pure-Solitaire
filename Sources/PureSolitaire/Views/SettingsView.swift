import SwiftUI
import AppKit
import GameCore

/// 설정 시트 — 섹션(카드/보드/게임플레이/게임별 옵션/데이터)별로 정리
struct SettingsView: View {
    @EnvironmentObject private var settings: UserSettings
    @EnvironmentObject private var vm: FreeCellViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingResetConfirmation = false

    /// 옵션을 가진 변형 목록 (GameVariant.allCases 자동 — 새 게임에 옵션만 추가하면 자동 반영)
    private var variantOptions: [(variant: GameVariant, options: [GameOption])] {
        GameVariant.allCases
            .map { ($0, $0.optionDefinitions) }
            .filter { !$0.options.isEmpty }
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("카드 스타일")
                        .font(.callout.weight(.medium))
                    CardStylePicker(selection: $settings.cardStyle)
                }
            } header: {
                Label("카드", systemImage: "rectangle.portrait.on.rectangle.portrait.angled")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("배경")
                        .font(.callout.weight(.medium))
                    BackgroundStylePicker(selection: $settings.background, settings: settings)
                }
                HStack {
                    Text("커스텀 배경")
                    Button("이미지 선택…") { chooseCustomBackground() }
                    Button("제거", role: .destructive) {
                        settings.removeCustomBackground()
                    }
                    .disabled(settings.customBackgroundPath.isEmpty)
                    .disabled(settings.background != .custom)
                }
                HStack {
                    Text("보드 줌")
                    Slider(value: $settings.boardScale, in: 0.7...1.4)
                        .frame(width: 160)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("카드 뒷면")
                        .font(.callout.weight(.medium))
                    CardBackPicker(selection: $settings.cardBack)
                }
            } header: {
                Label("보드", systemImage: "paintpalette")
            }

            Section {
                Toggle("자동 이동", isOn: $settings.autoPlayEnabled)
                    .toggleStyle(.switch)
                Toggle("승리 자동 완성", isOn: $settings.autoFinishEnabled)
                    .toggleStyle(.switch)
                Toggle("효과음", isOn: $settings.soundEnabled)
                    .toggleStyle(.switch)
                HStack {
                    Text("효과음 볼륨")
                    Image(systemName: "speaker.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Slider(value: $settings.soundVolume, in: 0...1)
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .disabled(!settings.soundEnabled)
                Toggle("배경음악", isOn: Binding(
                    get: { settings.bgmEnabled },
                    set: { newValue in
                        settings.bgmEnabled = newValue
                        vm.toggleBGM(newValue)
                    }
                ))
                .toggleStyle(.switch)
                HStack {
                    Text("배경음악 볼륨")
                    Image(systemName: "speaker.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Slider(value: Binding(
                        get: { settings.bgmVolume },
                        set: { newValue in
                            settings.bgmVolume = newValue
                            vm.setBGMVolume(newValue)
                        }
                    ), in: 0...1)
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .disabled(!settings.bgmEnabled)
                HStack {
                    Text("애니메이션 속도")
                    Spacer()
                    Text(settings.animationSpeed == 0 ? "끔" : String(format: "%.1fs", settings.animationSpeed))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $settings.animationSpeed, in: 0...1)
            } header: {
                Label("게임플레이", systemImage: "gamecontroller")
            } footer: {
                Text("자동 이동은 에이스 등 안전한 카드를 게임 중 홈셀로 옮깁니다.")
            }

            if !variantOptions.isEmpty {
                Section {
                    ForEach(variantOptions, id: \.variant) { item in
                        ForEach(item.options) { option in
                            Picker(
                                "\(item.variant.displayName) \(option.title)",
                                selection: optionSettingBinding(for: item.variant, option: option)
                            ) {
                                ForEach(option.choices) { choice in
                                    Text(choice.title).tag(choice.id)
                                }
                            }
                        }
                    }
                } header: {
                    Label("게임별 옵션", systemImage: "slider.horizontal.3")
                } footer: {
                    Text("다음 게임부터 적용됩니다.")
                }
            }

            Section {
                Button("통계 초기화", role: .destructive) { showingResetConfirmation = true }
                    .disabled(vm.allTotalGames == 0 && vm.winRecords.isEmpty)
            } header: {
                Label("데이터", systemImage: "trash")
            } footer: {
                Text("승리/패배 횟수, 연승, 최단 승리 시간, 최근 승리 기록이 모두 삭제됩니다.")
            }

            Section {
                Button {
                    openGitHub()
                } label: {
                    HStack {
                        Label("GitHub 저장소", systemImage: "curlybraces")
                        Spacer()
                        Text("github.com/BoraSarang/Pure-Solitaire")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                HStack {
                    Text("버전")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("정보", systemImage: "info.circle")
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 620)
        .padding(.horizontal, 16)
        .confirmationDialog(
            "정말 통계를 초기화할까요?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("초기화", role: .destructive) { vm.resetStats() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("이 작업은 되돌릴 수 없습니다.")
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button("닫기") { dismiss() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.bar)
        }
    }

    /// 게임별 옵션 선택지 ↔ GameOptionsStore 바인딩
    private func optionSettingBinding(for variant: GameVariant, option: GameOption) -> Binding<String> {
        Binding(
            get: { vm.gameOptions.selectedID(for: variant, option: option) },
            set: { vm.gameOptions.setSelectedID($0, for: variant, optionID: option.id) }
        )
    }

    /// 앱 버전 (Info.plist의 CFBundleShortVersionString)
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.20.0"
    }

    /// GitHub 저장소 페이지를 기본 브라우저로 열기
    private func openGitHub() {
        if let url = URL(string: "https://github.com/BoraSarang/Pure-Solitaire") {
            NSWorkspace.shared.open(url)
        }
    }

    /// 커스텀 배경 이미지 선택 → Application Support 저장 + 적용
    private func chooseCustomBackground() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "커스텀 배경 이미지 선택"
        if panel.runModal() == .OK, let url = panel.url {
            _ = settings.setCustomBackground(from: url)
        }
    }
}
