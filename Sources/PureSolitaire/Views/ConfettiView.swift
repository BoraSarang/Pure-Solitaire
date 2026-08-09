import SwiftUI

/// 승리 축하 파티클 — 색종이/별 낙하 (TimelineView 기반, 승리 시에만 표시)
struct ConfettiView: View {
    private static let colors: [Color] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink
    ]

    struct Particle {
        var x: Double
        var y: Double
        var speed: Double
        var size: Double
        var rotation: Double
        var rotationSpeed: Double
        var color: Color
        var shape: Int  // 0: 직사각형, 1: 원, 2: 별
    }

    @State private var particles: [Particle] = []

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for i in particles.indices {
                    let p = particles[i]
                    // y 하강 + 좌우 사인 흔들림
                    let progress = (t * p.speed).truncatingRemainder(dividingBy: 1.0)
                    let y = progress * (size.height + 40) - 20
                    let sway = sin(t * 2 + p.x * 10) * 12
                    let x = p.x * size.width + sway
                    let rot = p.rotation + progress * p.rotationSpeed * 360

                    let rect = CGRect(x: x, y: y, width: p.size, height: p.size * 0.6)
                    let transform = CGAffineTransform(translationX: rect.midX, y: rect.midY)
                        .rotated(by: rot * .pi / 180)
                        .translatedBy(x: -rect.midX, y: -rect.midY)

                    switch p.shape {
                    case 1:
                        let circle = Path(ellipseIn: rect)
                        context.fill(circle.path(in: rect), with: .color(p.color))
                    case 2:
                        var path = Path()
                        let c = CGPoint(x: rect.midX, y: rect.midY)
                        let r = p.size * 0.5
                        for k in 0..<5 {
                            let angle = Double(k) * 144 * .pi / 180 - .pi / 2
                            let px = c.x + r * cos(angle)
                            let py = c.y + r * sin(angle)
                            if k == 0 { path.move(to: CGPoint(x: px, y: py)) }
                            else { path.addLine(to: CGPoint(x: px, y: py)) }
                        }
                        path.closeSubpath()
                        context.fill(path.applying(transform), with: .color(p.color))
                    default:
                        let path = Path(rect)
                        context.fill(path.applying(transform), with: .color(p.color))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            if particles.isEmpty {
                particles = (0..<60).map { _ in
                    Particle(
                        x: Double.random(in: 0...1),
                        y: Double.random(in: 0...1),
                        speed: Double.random(in: 0.3...0.8),
                        size: Double.random(in: 6...13),
                        rotation: Double.random(in: 0...360),
                        rotationSpeed: Double.random(in: -1.5...1.5),
                        color: Self.colors.randomElement() ?? .red,
                        shape: Int.random(in: 0...2)
                    )
                }
            }
        }
    }
}
