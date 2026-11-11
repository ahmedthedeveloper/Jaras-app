import ActivityKit
import SwiftUI
import WidgetKit

/// Food-Delivery-Style 3-Minute Countdown Live Activity & Dynamic Island for «جرس الحصص».
struct JarasLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: JarasActivityAttributes.self) { context in
            // LOCK SCREEN & NOTIFICATION SHADE LIVE ACTIVITY BANNER
            lockScreenDeliveryBanner(context: context)
                .activityBackgroundTint(Color(hex: 0x0D1512))
                .activitySystemActionForegroundColor(Color(hex: 0x10B981))
        } dynamicIsland: { context in
            DynamicIsland {
                // EXPANDED DYNAMIC ISLAND
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: 0x10B981).opacity(0.2))
                                .frame(width: 34, height: 34)
                            Image(systemName: "bell.and.waves.left.and.right.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: 0x10B981))
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(
                        timerInterval: context.attributes.countdownStart...context.attributes.classBegin,
                        countsDown: true
                    )
                    .monospacedDigit()
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: 0x34D399))
                    .frame(width: 68, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text("اقتراب موعد \(Ar.lecture(context.attributes.ordinal))")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Text(context.attributes.title)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(Color(hex: 0xBBF7D0))
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        // Delivery-app style live progress bar
                        ProgressView(
                            timerInterval: context.attributes.countdownStart...context.attributes.classBegin,
                            countsDown: false
                        ) {
                            EmptyView()
                        } currentValueLabel: {
                            EmptyView()
                        }
                        .tint(Color(hex: 0x10B981))

                        HStack {
                            Text("🔔 تنبيه الجرس")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            Text("📖 بداية الحصة \(Ar.time(context.attributes.classBegin))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: 0xFDE68A))
                        }
                    }
                    .padding(.top, 4)
                    .environment(\.layoutDirection, .rightToLeft)
                }
            } compactLeading: {
                // COMPACT LEADING (Left pill of Dynamic Island)
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: 0x10B981))
                    Text(Ar.lecture(context.attributes.ordinal))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            } compactTrailing: {
                // COMPACT TRAILING (Right pill of Dynamic Island: live 3m countdown)
                Text(
                    timerInterval: context.attributes.countdownStart...context.attributes.classBegin,
                    countsDown: true
                )
                .monospacedDigit()
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(hex: 0x34D399))
                .frame(width: 48)
            } minimal: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: 0x10B981))
            }
        }
    }

    @ViewBuilder
    private func lockScreenDeliveryBanner(context: ActivityViewContext<JarasActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Row: Bell Badge + Heading + Live Countdown Chronometer
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0x10B981), Color(hex: 0x059669)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 42, height: 42)
                    Image(systemName: "bell.and.waves.left.and.right.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("اقتراب موعد \(Ar.lecture(context.attributes.ordinal))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    HStack(spacing: 4) {
                        Text(context.attributes.title)
                            .font(.system(size: 13.5, weight: .semibold))
                            .foregroundColor(Color(hex: 0xBBF7D0))
                        if !context.attributes.location.isEmpty {
                            Text("· \(context.attributes.location)")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }
                    .lineLimit(1)
                }

                Spacer()

                // Live Second-by-Second Countdown Pill (just like Delivery ETA)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(
                        timerInterval: context.attributes.countdownStart...context.attributes.classBegin,
                        countsDown: true
                    )
                    .monospacedDigit()
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(Color(hex: 0x34D399))
                    .multilineTextAlignment(.trailing)

                    Text("متبقي للبدء")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))
                }
            }

            // Food-Delivery-App Style Progress Bar (0% -> 100%)
            VStack(spacing: 6) {
                ProgressView(
                    timerInterval: context.attributes.countdownStart...context.attributes.classBegin,
                    countsDown: false
                ) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                .tint(Color(hex: 0x10B981))

                HStack {
                    Label("رنّ الجرس (قبل ٣ د)", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color(hex: 0x34D399))

                    Spacer()

                    Label("تبدأ \(Ar.time(context.attributes.classBegin))", systemImage: "book.fill")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(Color(hex: 0xFDE68A))
                }
            }
        }
        .padding(16)
        .environment(\.layoutDirection, .rightToLeft)
    }
}
