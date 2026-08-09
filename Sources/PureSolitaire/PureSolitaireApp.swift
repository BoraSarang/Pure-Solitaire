import SwiftUI

@main
struct PureSolitaireApp: App {
    @StateObject private var viewModel = FreeCellViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(viewModel.settings)
                .frame(minWidth: 780, minHeight: 720)
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .background || newPhase == .inactive {
                        viewModel.persist()
                    }
                }
                .onAppear {
                    if viewModel.settings.bgmEnabled {
                        BGMPLayer.shared.start(volume: viewModel.settings.bgmVolume)
                    }
                }
        }
        .defaultSize(width: 786, height: 780)
        .commands {
            GameCommands(viewModel: viewModel, settings: viewModel.settings)
        }
    }
}
