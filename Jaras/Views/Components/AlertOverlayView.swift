import SwiftUI

/// Full-screen Bell Alert Pop-up matching the Android `AlertPanel`:
/// - Dark emerald blurred backdrop
/// - Animated 3D Green Bell with Ministry of Education medallion (drops from top with overshoot)
/// - Glossy Capsule Banner (springs up from bottom)
/// - Golden Arc (expands from center)
/// - "حاضر، أنا جاهز!" acknowledgment button -> closes pop-up and starts the 3-minute delivery timer
struct AlertOverlayView: View {
    let lecture: Lecture
    let onDismiss: () -> Void

    @State private var scrimOpacity: Double = 0
    @State private var bellScale: CGFloat = 0.45
    @State private var bellOffsetY: CGFloat = -60
    @State private var bellOpacity: Double = 0

    @State private var cardScale: CGFloat = 0.72
    @State private var cardOffsetY: CGFloat = 70
    @State private var cardOpacity: Double = 0

    @State private var arcScale: CGFloat = 0.0
    @State private var buttonOffsetY: CGFloat = 30
    @State private var buttonOpacity: Double = 0

    var body: some View {
        ZStack {
            // Backdrop Scrim
            LinearGradient(
                colors: [Color(hex: 0x051209, alpha: 0.85), Color(hex: 0x020604, alpha: 0.94)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .opacity(scrimOpacity)
            .onTapGesture {
                animateOutAndClose()
            }

            // Center Holder
            VStack(spacing: 0) {
                // 1. 3D Green Bell with MoE Emblem (No clock!)
                GreenBellView(isRinging: true)
                    .frame(width: 195, height: 195)
                    .scaleEffect(bellScale)
                    .offset(y: bellOffsetY)
                    .opacity(bellOpacity)
                    .zIndex(2)

                // 2. Capsule Banner sitting right beneath the bell clapper
                CapsuleBannerView(
                    ordinal: lecture.ordinal,
                    title: lecture.title,
                    begin: lecture.begin,
                    location: lecture.location,
                    arcScale: arcScale
                )
                .padding(.top, -14)
                .scaleEffect(cardScale)
                .offset(y: cardOffsetY)
                .opacity(cardOpacity)
                .zIndex(1)

                // 3. Acknowledgment Button
                Button(action: animateOutAndClose) {
                    Text("حاضر، أنا جاهز!")
                        .font(.system(size: 16.5, weight: .bold))
                        .foregroundColor(Color(hex: 0x065F46))
                        .frame(width: 220, height: 52)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.white)
                        )
                        .shadow(color: Color(hex: 0x047857, alpha: 0.55), radius: 14, x: 0, y: 6)
                }
                .padding(.top, 20)
                .offset(y: buttonOffsetY)
                .opacity(buttonOpacity)
            }
            .frame(maxWidth: 350)
            .padding(.horizontal, 16)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear(perform: playEntranceAnimation)
    }

    private func playEntranceAnimation() {
        withAnimation(.easeOut(duration: 0.30)) {
            scrimOpacity = 1.0
        }
        withAnimation(.interpolatingSpring(stiffness: 180, damping: 11)) {
            bellOpacity = 1.0
            bellScale = 1.0
            bellOffsetY = 0
        }
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 12).delay(0.10)) {
            cardOpacity = 1.0
            cardScale = 1.0
            cardOffsetY = 0
        }
        withAnimation(.interpolatingSpring(stiffness: 200, damping: 12).delay(0.32)) {
            arcScale = 1.0
        }
        withAnimation(.easeOut(duration: 0.42).delay(0.24)) {
            buttonOpacity = 1.0
            buttonOffsetY = 0
        }
    }

    private func animateOutAndClose() {
        withAnimation(.easeOut(duration: 0.22)) {
            scrimOpacity = 0
            bellOpacity = 0
            bellScale = 0.85
            cardOpacity = 0
            cardScale = 0.86
            cardOffsetY = 30
            buttonOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            onDismiss()
        }
    }
}
