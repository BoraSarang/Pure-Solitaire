import AppKit

// Pure FreeCell 앱 아이콘 생성 스크립트
// 사용: swift scripts/make_icon.swift → images/AppIcon-1024.png 생성
// 그린 그라데이션 배경 + 기울어진 카드 스택 + 정면 하트 카드 (macOS Big Sur+ 스타일)

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

// ============ 배경: 그린 세로 그라데이션 ============
let bg = NSGradient(colors: [
    NSColor(red: 0.05, green: 0.55, blue: 0.28, alpha: 1),   // 위 연한 그린
    NSColor(red: 0.01, green: 0.30, blue: 0.16, alpha: 1)    // 아래 짙은 그린
])!
bg.draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: -90)

// 부드러운 광원 (상단 중앙)
NSColor(white: 1.0, alpha: 0.12).setFill()
NSBezierPath(ovalIn: NSRect(x: 140, y: 620, width: 744, height: 620)).fill()

// ============ 뒤 카드 스택 (기울여 겹치기) ============
func drawCard(at center: NSPoint, rotation: CGFloat, fill: NSColor, stroke: NSColor) {
    NSGraphicsContext.saveGraphicsState()
    let transform = NSAffineTransform()
    transform.translateX(by: center.x, yBy: center.y)
    transform.rotate(byDegrees: rotation)
    transform.concat()
    let rect = NSRect(x: -300, y: -410, width: 600, height: 820)
    let path = NSBezierPath(roundedRect: rect, xRadius: 46, yRadius: 46)
    fill.setFill()
    path.fill()
    stroke.setStroke()
    path.lineWidth = 6
    path.stroke()
    NSGraphicsContext.restoreGraphicsState()
}

// 그림자
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
shadow.shadowBlurRadius = 40
shadow.shadowOffset = NSSize(width: 0, height: -18)
NSGraphicsContext.saveGraphicsState()
shadow.set()

// 뒤 카드 3장 (기울어짐)
drawCard(at: NSPoint(x: 470, y: 560), rotation: -16, fill: NSColor(red: 0.05, green: 0.20, blue: 0.12, alpha: 1), stroke: NSColor(white: 1, alpha: 0.10))
drawCard(at: NSPoint(x: 545, y: 555), rotation: 16, fill: NSColor(red: 0.08, green: 0.26, blue: 0.16, alpha: 1), stroke: NSColor(white: 1, alpha: 0.10))
drawCard(at: NSPoint(x: 512, y: 580), rotation: 0, fill: NSColor(red: 0.10, green: 0.32, blue: 0.20, alpha: 1), stroke: NSColor(white: 1, alpha: 0.14))

// ============ 정면 카드 (흰색) ============
let cardRect = NSRect(x: 182, y: 212, width: 660, height: 600)
let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 52, yRadius: 52)
NSColor.white.setFill()
cardPath.fill()
NSGraphicsContext.saveGraphicsState()
NSColor.black.withAlphaComponent(0.18).setStroke()
cardPath.lineWidth = 8
cardPath.stroke()
NSGraphicsContext.restoreGraphicsState()

// ============ 카드 상단: 하트 무늬 + A ============
// 좌상단 랭크 "A"
func drawCornerLabel(_ text: String, color: NSColor, at point: NSPoint, size scale: CGFloat) {
    let font = NSFont(name: "SF Pro Display Heavy", size: 132 * scale)
        ?? NSFont.boldSystemFont(ofSize: 132 * scale)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color
    ]
    let str = NSAttributedString(string: text, attributes: attrs)
    str.draw(at: point)
}
drawCornerLabel("A", color: NSColor(red: 0.82, green: 0.08, blue: 0.08, alpha: 1), at: NSPoint(x: 216, y: 640), size: 0.62)

// 좌상단 하트 무늬 (작게)
func drawHeart(at center: NSPoint, width w: CGFloat, color: NSColor) {
    let h = w * 0.9
    let x = center.x, y = center.y
    let p = NSBezierPath()
    p.move(to: NSPoint(x: x, y: y - h * 0.5))
    p.curve(to: NSPoint(x: x - w * 0.5, y: y + h * 0.12),
            controlPoint1: NSPoint(x: x, y: y - h * 0.14),
            controlPoint2: NSPoint(x: x - w * 0.5, y: y - h * 0.02))
    p.curve(to: NSPoint(x: x, y: y + h * 0.5),
            controlPoint1: NSPoint(x: x - w * 0.5, y: y + h * 0.30),
            controlPoint2: NSPoint(x: x - w * 0.20, y: y + h * 0.52))
    p.curve(to: NSPoint(x: x + w * 0.5, y: y + h * 0.12),
            controlPoint1: NSPoint(x: x + w * 0.20, y: y + h * 0.52),
            controlPoint2: NSPoint(x: x + w * 0.5, y: y + h * 0.30))
    p.curve(to: NSPoint(x: x, y: y - h * 0.5),
            controlPoint1: NSPoint(x: x + w * 0.5, y: y - h * 0.02),
            controlPoint2: NSPoint(x: x, y: y - h * 0.14))
    p.close()
    color.setFill()
    p.fill()
}
drawHeart(at: NSPoint(x: 300, y: 622), width: 132, color: NSColor(red: 0.82, green: 0.08, blue: 0.08, alpha: 1))

// ============ 중앙 큰 하트 ============
drawHeart(at: NSPoint(x: 512, y: 470), width: 330, color: NSColor(red: 0.88, green: 0.10, blue: 0.10, alpha: 1))

// 중앙 하트 하이라이트 (빛 반사)
NSColor.white.withAlphaComponent(0.35).setFill()
let gloss = NSBezierPath()
gloss.move(to: NSPoint(x: 512, y: 620))
gloss.curve(to: NSPoint(x: 470, y: 560),
            controlPoint1: NSPoint(x: 490, y: 600),
            controlPoint2: NSPoint(x: 475, y: 578))
gloss.curve(to: NSPoint(x: 500, y: 610),
            controlPoint1: NSPoint(x: 485, y: 580),
            controlPoint2: NSPoint(x: 495, y: 600))
gloss.close()
gloss.fill()

// ============ 하단 배너 (FREE CELL) ============
let banner = NSBezierPath(roundedRect: NSRect(x: 232, y: 196, width: 560, height: 92), xRadius: 30, yRadius: 30)
NSColor(red: 0.02, green: 0.36, blue: 0.19, alpha: 0.92).setFill()
banner.fill()

let bannerText = NSAttributedString(string: "FREE CELL", attributes: [
    .font: NSFont.boldSystemFont(ofSize: 44),
    .foregroundColor: NSColor.white,
    .kern: 2.5
])
let bs = bannerText.size()
bannerText.draw(at: NSPoint(x: 512 - bs.width / 2, y: 196 + (92 - bs.height) / 2))

image.unlockFocus()

// ============ PNG 저장 (images/AppIcon-1024.png) ============
guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fputs("아이콘 PNG 생성 실패\n", stderr)
    exit(1)
}

let dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("images", isDirectory: true)
try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
let url = dir.appendingPathComponent("AppIcon-1024.png")
do {
    try png.write(to: url)
    print("images/AppIcon-1024.png 생성됨")
} catch {
    fputs("PNG 저장 실패: \(error)\n", stderr)
    exit(1)
}
