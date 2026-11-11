import SwiftUI

/// Renders the 3D Glossy Green Bell from the reference image:
/// - Radiant emerald aura halo
/// - Vibrating sound wave arcs on both sides
/// - Top crown loop & spherical clapper with specular highlight
/// - Central white medallion with Saudi Ministry of Education dot emblem & typography
/// - Animated damped ringing swing
struct GreenBellView: View {
    var isRinging: Bool = true

    @State private var startTime = Date()

    private static let moeDots: [(CGFloat, CGFloat)] = [
        (-7.0, -7.5), (-3.5, -9.0), (0.0, -9.5), (3.5, -9.0), (7.0, -7.5),
        (-8.5, -5.0), (-5.0, -6.2), (-1.8, -7.0), (1.8, -7.0), (5.0, -6.2), (8.5, -5.0),
        (-7.5, -2.5), (-4.0, -3.5), (-1.5, -4.2), (1.5, -4.2), (4.0, -3.5), (7.5, -2.5),
        (-5.0, 0.0), (-2.2, -0.8), (2.2, -0.8), (5.0, 0.0)
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startTime)
            let cycle = elapsed.truncatingRemainder(dividingBy: 2.6)
            let energy: CGFloat = isRinging ? CGFloat(exp(-1.8 * cycle)) : 0.0
            let phase = 2.0 * .pi * 3.1 * cycle
            let swingDeg = isRinging ? Double(20.0 * energy * CGFloat(sin(phase))) : Double(4.0 * sin(elapsed * 2.0))
            let clapperOffset = isRinging ? (12.0 * energy * CGFloat(sin(phase - 1.0))) : (2.5 * CGFloat(sin(elapsed * 2.0 - 0.8)))

            Canvas { context, size in
                let s = min(size.width, size.height) / 112.0
                context.translateBy(x: (size.width - 100 * s) / 2.0, y: (size.height - 100 * s) / 2.0)
                context.scaleBy(x: s, y: s)

                // 1. Radiant background halo
                let haloCenter = CGPoint(x: 50, y: 44)
                let haloGradient = Gradient(colors: [
                    Color(hex: 0x4ADE80, alpha: 0.24),
                    Color(hex: 0x10B981, alpha: 0.08),
                    Color.clear
                ])
                context.fill(
                    Path(ellipseIn: CGRect(x: 6, y: 0, width: 88, height: 88)),
                    with: .radialGradient(haloGradient, center: haloCenter, startRadius: 2, endRadius: 44)
                )

                // 2. Pulsing Sound Wave Arcs on both sides
                let pulseScale: CGFloat = 1.0 + (1.0 - max(0.2, energy)) * 0.08
                let baseAlpha = Double(0.62 + 0.38 * min(1.0, energy * 1.5))
                for i in 0..<3 {
                    let r = (44.0 + 7.5 * CGFloat(i)) * pulseScale
                    let alpha = max(0.15, baseAlpha * (1.0 - Double(i) * 0.26))
                    let strokeStyle = StrokeStyle(lineWidth: 4.5, lineCap: .round)

                    var leftArc = Path()
                    leftArc.addArc(
                        center: CGPoint(x: 50, y: 46),
                        radius: r,
                        startAngle: .degrees(Double(155 - i * 4)),
                        endAngle: .degrees(Double(155 - i * 4 + 26 + i * 4)),
                        clockwise: false
                    )
                    context.stroke(leftArc, with: .color(Color(hex: 0x22C55E, alpha: alpha)), style: strokeStyle)

                    var rightArc = Path()
                    rightArc.addArc(
                        center: CGPoint(x: 50, y: 46),
                        radius: r,
                        startAngle: .degrees(Double(-1 - i * 4)),
                        endAngle: .degrees(Double(-1 - i * 4 + 26 + i * 4)),
                        clockwise: false
                    )
                    context.stroke(rightArc, with: .color(Color(hex: 0x22C55E, alpha: alpha)), style: strokeStyle)
                }

                // 3. Rotate Bell around top pivot (50, 10)
                context.translateBy(x: 50, y: 10)
                context.rotate(by: .degrees(swingDeg))
                context.translateBy(x: -50, y: -10)

                // 4. Crown Loop
                var crownPath = Path()
                crownPath.move(to: CGPoint(x: 42, y: 17))
                crownPath.addCurve(
                    to: CGPoint(x: 58, y: 17),
                    control1: CGPoint(x: 42, y: 6),
                    control2: CGPoint(x: 58, y: 6)
                )
                context.stroke(
                    crownPath,
                    with: .color(Color(hex: 0x22C55E)),
                    style: StrokeStyle(lineWidth: 5.5, lineCap: .round)
                )

                // 5. Spherical Clapper with Specular Highlight
                let clapperCenter = CGPoint(x: 50 + clapperOffset, y: 85)
                let clapperRect = CGRect(x: clapperCenter.x - 8.5, y: clapperCenter.y - 8.5, width: 17, height: 17)
                let clapperGrad = Gradient(colors: [
                    Color(hex: 0x86EFAC),
                    Color(hex: 0x22C55E),
                    Color(hex: 0x166534)
                ])
                context.fill(
                    Path(ellipseIn: clapperRect),
                    with: .radialGradient(
                        clapperGrad,
                        center: CGPoint(x: clapperCenter.x - 2, y: clapperCenter.y - 2),
                        startRadius: 1,
                        endRadius: 9
                    )
                )
                let clapperShineRect = CGRect(x: clapperCenter.x - 3.7, y: clapperCenter.y - 4.2, width: 4.4, height: 4.4)
                context.fill(Path(ellipseIn: clapperShineRect), with: .color(.white.opacity(0.86)))

                // 6. Bell Body
                var bellPath = Path()
                bellPath.move(to: CGPoint(x: 50, y: 15))
                bellPath.addCurve(to: CGPoint(x: 27, y: 44), control1: CGPoint(x: 34, y: 15), control2: CGPoint(x: 27, y: 28))
                bellPath.addCurve(to: CGPoint(x: 16, y: 73), control1: CGPoint(x: 27, y: 58), control2: CGPoint(x: 24, y: 66))
                bellPath.addCurve(to: CGPoint(x: 19.5, y: 80), control1: CGPoint(x: 13.5, y: 75.5), control2: CGPoint(x: 15, y: 80))
                bellPath.addLine(to: CGPoint(x: 80.5, y: 80))
                bellPath.addCurve(to: CGPoint(x: 84, y: 73), control1: CGPoint(x: 85, y: 80), control2: CGPoint(x: 86.5, y: 75.5))
                bellPath.addCurve(to: CGPoint(x: 73, y: 44), control1: CGPoint(x: 76, y: 66), control2: CGPoint(x: 73, y: 58))
                bellPath.addCurve(to: CGPoint(x: 50, y: 15), control1: CGPoint(x: 73, y: 28), control2: CGPoint(x: 66, y: 15))
                bellPath.closeSubpath()

                let bodyGrad = Gradient(stops: [
                    .init(color: Color(hex: 0x4ADE80), location: 0.0),
                    .init(color: Color(hex: 0x22C55E), location: 0.28),
                    .init(color: Color(hex: 0x15803D), location: 0.72),
                    .init(color: Color(hex: 0x0D5325), location: 1.0)
                ])
                context.fill(
                    bellPath,
                    with: .linearGradient(bodyGrad, startPoint: CGPoint(x: 25, y: 15), endPoint: CGPoint(x: 75, y: 80))
                )

                // 7. Dark Inner Rim
                context.drawLayer { rimLayer in
                    rimLayer.clip(to: bellPath)
                    rimLayer.fill(
                        Path(CGRect(x: 0, y: 72, width: 100, height: 9)),
                        with: .color(Color(hex: 0x0F5E2B))
                    )
                }

                // 8. Left Specular Highlight Curve
                var shinePath = Path()
                shinePath.move(to: CGPoint(x: 38, y: 24))
                shinePath.addCurve(to: CGPoint(x: 31, y: 56), control1: CGPoint(x: 33, y: 33), control2: CGPoint(x: 31, y: 43))
                context.stroke(
                    shinePath,
                    with: .color(.white.opacity(0.6)),
                    style: StrokeStyle(lineWidth: 3.8, lineCap: .round)
                )

                // 9. Central White Medallion with Ministry of Education Emblem
                let medalRect = CGRect(x: 50 - 18.5, y: 44 - 18.5, width: 37, height: 37)
                let medalPath = Path(ellipseIn: medalRect)
                context.fill(medalPath, with: .color(.white))
                context.stroke(medalPath, with: .color(Color(hex: 0xE2E8F0)), lineWidth: 1.2)

                for (dx, dy) in Self.moeDots {
                    let dotRect = CGRect(x: 50 + dx - 0.75, y: 44 + dy - 0.75, width: 1.5, height: 1.5)
                    context.fill(Path(ellipseIn: dotRect), with: .color(Color(hex: 0x047857)))
                }

                let arText = Text("وزارة التعليم")
                    .font(.system(size: 4.5, weight: .bold))
                    .foregroundColor(Color(hex: 0x047857))
                context.draw(arText, at: CGPoint(x: 50, y: 47.4), anchor: .center)

                let enText = Text("Ministry of Education")
                    .font(.system(size: 2.2, weight: .regular))
                    .foregroundColor(Color(hex: 0x64748B))
                context.draw(enText, at: CGPoint(x: 50, y: 51.6), anchor: .center)
            }
        }
    }
}
