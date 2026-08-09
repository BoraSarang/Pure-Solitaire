import SwiftUI

/// NSWindow 접근 헬퍼 — 창 프레임 자동 저장/복원
struct WindowAccessor: NSViewRepresentable {
    var onReady: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onReady(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
