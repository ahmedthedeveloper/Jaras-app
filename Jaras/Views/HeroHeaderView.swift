import SwiftUI

/// The Emerald Green Header (`Views.Hero`) with slow-drifting background shapes,
/// greeting, "جدول حصصي", date chip, and the "الحصة التالية" glass card with countdown ring.
struct HeroHeaderView: View {
    let nextLecture: Lecture?
    let onOpenSettings: () -> Void

    @State private var startTime = Date()

    var body: some View {
        ZStack(alignment: .bottom) {
            // Animated Emerald Green Sheet Background
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSince(startTime)
                let drift = t * (2.0 * .pi / 14.0)
                Canvas { context, size in
                    let w = size.width
                    let h = size.height

                    // Emerald Gradient (#047857 -> #059669 -> #10B981)
                    let bgGrad = Gradient(stops: [
                        .init(color: Color(hex: 0x047857), location: 0.0),
                        .init(color: Color(hex: 0x059669), location: 0.5),
                        .init(color: Color(hex: 0x10B981), location: 1.0)
                    ])
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .linearGradient(bgGrad, startPoint: CGPoint(x: w, y: 0), endPoint: CGPoint(x: 0, y: h))
                    )

                    // Soft Mint Radial Glow
                    let glowGrad = Gradient(colors: [
                        Color(hex: 0x34D399, alpha: 0.28),
                        Color.clear
                    ])
                    context.fill(
                        Path(CGRect(origin: .zero, size: size)),
                        with: .radialGradient(
                            glowGrad,
                            center: CGPoint(x: w * 0.08, y: h * 0.02),
                            startRadius: 4,
                            endRadius: max(1, w * 0.75)
                        )
                    )

                    // Slow-drifting translucent shapes
                    let s = CGFloat(sin(drift))
                    let c = CGFloat(cos(drift))
                    let r1 = w * 0.4
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: w * 0.1 + s * 10 - r1,
                            y: h * 0.18 + c * 8 - r1,
                            width: r1 * 2,
                            height: r1 * 2
                        )),
                        with: .color(.white.opacity(0.07))
                    )

                    let r2 = w * 0.3
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: w * 0.98 - c * 12 - r2,
                            y: h * 0.86 + s * 10 - r2,
                            width: r2 * 2,
                            height: r2 * 2
                        )),
                        with: .color(.white.opacity(0.055))
                    )

                    let ringRect = CGRect(
                        x: w * 0.42 + c * 6 - 22,
                        y: h * 0.1 + s * 6 - 22,
                        width: 44,
                        height: 44
                    )
                    context.stroke(
                        Path(ellipseIn: ringRect),
                        with: .color(.white.opacity(0.13)),
                        lineWidth: 2.5
                    )
                }
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 38,
                    bottomTrailingRadius: 38,
                    topTrailingRadius: 0,
                    style: .continuous
                )
            )

            // Foreground Header Content
            VStack(alignment: .leading, spacing: 14) {
                // Top Row: Greeting & Title on Right, Settings Icon on Left
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Ar.greeting())
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                        Text("جدول حصصي")
                            .font(.system(size: 29, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button(action: onOpenSettings) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(Color.white.opacity(0.16)))
                    }
                }

                // Date Chip
                HStack(spacing: 7) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(Color(hex: 0xFFE08A))
                    Text(Ar.fullDate(Date()))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.95))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.14)))

                // "What is Next" Glass Card
                nextLectureGlassCard
            }
            .padding(.horizontal, 22)
            .padding(.top, 58)
            .padding(.bottom, 26)
        }
    }

    @ViewBuilder
    private var nextLectureGlassCard: some View {
        TimelineView(.periodic(from: .now, by: 15.0)) { timeline in
            let now = timeline.date
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    if let next = nextLecture {
                        let mins = Ar.minutesUntil(next.begin, from: now)
                        Text("\(Ar.lecture(next.ordinal)) · \(Ar.relativeDay(next.begin, now: now))")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(JarasPalette.sunLight)

                        Text(next.title)
                            .font(.system(size: 23, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Text(metaLine(for: next, minsUntil: mins))
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.85))
                    } else {
                        Text("لا حصص قادمة")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(JarasPalette.sunLight)
                        Text("وقتك لك!")
                            .font(.system(size: 23, weight: .bold))
                            .foregroundColor(.white)
                        Text("ستظهر حصصك هنا فور إضافتها إلى تقويم Google")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                Spacer(minLength: 0)

                if let next = nextLecture {
                    let mins = Ar.minutesUntil(next.begin, from: now)
                    countdownRing(minutesUntil: mins)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
        }
    }

    private func metaLine(for lecture: Lecture, minsUntil: Int) -> String {
        var s = "\(Ar.time(lecture.begin)) · \(Ar.inTime(minutes: minsUntil))"
        if !lecture.location.isEmpty {
            s += " · \(lecture.location)"
        }
        return s
    }

    private func countdownRing(minutesUntil mins: Int) -> some View {
        let progress = min(1.0, max(0.05, 1.0 - Double(min(mins, 60)) / 60.0))
        let displayNum = mins < 60 ? Ar.num(max(1, mins)) : Ar.num(mins / 60)
        let displayUnit = mins < 60 ? "دقيقة" : "ساعة"

        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.20), lineWidth: 6)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(JarasPalette.sun, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(displayNum)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text(displayUnit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .frame(width: 78, height: 78)
    }
}
