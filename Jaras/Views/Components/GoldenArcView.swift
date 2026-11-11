import SwiftUI

/// Renders the upward-curving golden arc underline beneath "الحصة الثانية" from the reference image.
struct GoldenArcView: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            guard w > 0, h > 0 else { return }

            var path = Path()
            path.move(to: CGPoint(x: w * 0.08, y: h * 0.78))
            path.addQuadCurve(
                to: CGPoint(x: w * 0.92, y: h * 0.78),
                control: CGPoint(x: w * 0.50, y: h * 0.18)
            )

            let goldGradient = Gradient(colors: [
                Color(hex: 0xF59E0B),
                Color(hex: 0xFDE047),
                Color(hex: 0xF59E0B)
            ])
            context.stroke(
                path,
                with: .linearGradient(
                    goldGradient,
                    startPoint: CGPoint(x: w * 0.1, y: 0),
                    endPoint: CGPoint(x: w * 0.9, y: 0)
                ),
                style: StrokeStyle(lineWidth: 3.8, lineCap: .round)
            )
        }
    }
}
