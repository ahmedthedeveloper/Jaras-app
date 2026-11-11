import SwiftUI

/// The glossy emerald capsule banner from the reference image:
/// - Row 1: Open Book Icon | "بـدء"
/// - Row 2: "الحصة الثانية" (or dynamic ordinal)
/// - Row 3: Golden upward arc underline
/// - Row 4: Lecture title & start time / room (without any countdown timer inside the pop-up)
struct CapsuleBannerView: View {
    let ordinal: Int
    let title: String
    let begin: Date
    let location: String
    var arcScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 4) {
            // Row 1: [Book Icon] [|] [بـدء]
            HStack(spacing: 12) {
                Image(systemName: "book")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Rectangle()
                    .fill(Color.white.opacity(0.82))
                    .frame(width: 2, height: 20)

                Text("بـدء")
                    .font(.system(size: 23, weight: .bold))
                    .foregroundColor(.white)
            }
            .environment(\.layoutDirection, .leftToRight)

            // Row 2: "الحصة الثانية"
            Text(Ar.lecture(max(1, ordinal)))
                .font(.system(size: 33, weight: .heavy))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 2)

            // Row 3: Golden Arc
            GoldenArcView()
                .frame(width: 190, height: 14)
                .scaleEffect(x: arcScale, y: 1.0, anchor: .center)
                .padding(.bottom, 4)

            // Row 4: Lecture Title & Time/Room
            Text(title.isEmpty ? "حصة" : title)
                .font(.system(size: 17.5, weight: .bold))
                .foregroundColor(Color(hex: 0xF0FDF4))
                .lineLimit(1)

            Text(metaString)
                .font(.system(size: 13.5, weight: .regular))
                .foregroundColor(Color(hex: 0xBBF7D0))
                .lineLimit(1)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(JarasPalette.capsuleGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white, lineWidth: 3)
        )
        .shadow(color: Color(hex: 0x047857, alpha: 0.65), radius: 22, x: 0, y: 10)
    }

    private var metaString: String {
        var meta = "تبدأ \(Ar.time(begin))"
        if !location.isEmpty {
            meta += "  ·  \(location)"
        }
        return meta
    }
}
