import ActivityKit
import SwiftUI

/// Settings screen («الإعدادات»):
/// - Appearance («المظهر»): Dark Mode by default with instant toggle to Light Mode
/// - Alerts («التنبيهات»): Notification permission & Live Activity / Dynamic Island status
/// - Test Bell («جرّب الجرس الآن»): Immediately opens the 3D Green Bell Pop-up and triggers the 3-min delivery timer
/// - Calendars («تقويمات الحصص»): Choose which Google / iCloud calendars count as classes
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var repo: CalendarRepo
    @EnvironmentObject var notifier: NotificationManager

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Header Bar
                    HStack {
                        Text("الإعدادات")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(theme.ink)
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(theme.ink)
                                .frame(width: 38, height: 38)
                                .background(Circle().fill(theme.card))
                                .overlay(Circle().stroke(theme.line, lineWidth: 1))
                        }
                    }
                    .padding(.top, 8)

                    // Section 1: Appearance ("المظهر")
                    sectionLabel("المظهر")
                    VStack(spacing: 0) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(theme.primaryTint)
                                    .frame(width: 42, height: 42)
                                Image(systemName: theme.isDarkMode ? "moon.stars.fill" : "sun.max.fill")
                                    .foregroundColor(JarasPalette.primary)
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("الوضع الداكن")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(theme.ink)
                                Text(theme.isDarkMode ? "مفعّل افتراضياً لراحة العين" : "الوضع الفاتح مفعّل حالياً")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(theme.inkSoft)
                            }
                            Spacer()
                            Toggle("", isOn: $theme.isDarkMode)
                                .labelsHidden()
                                .tint(JarasPalette.primary)
                        }
                        .padding(16)
                    }
                    .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(theme.card))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(theme.line, lineWidth: 1))

                    // Section 2: Alerts ("التنبيهات")
                    sectionLabel("التنبيهات والأنشطة الحية")
                    VStack(spacing: 0) {
                        settingStatusRow(
                            icon: "bell.badge.fill",
                            title: "الإشعارات العاجلة",
                            subtitle: "تنبيه بصوت الجرس قبل الحصة بثلاث دقائق",
                            isOk: notifier.isAuthorized
                        ) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }

                        Divider().background(theme.line).padding(.horizontal, 16)

                        settingStatusRow(
                            icon: "platter.filled.top.iphone",
                            title: "الأنشطة الحية والجزيرة التفاعلية",
                            subtitle: "مؤقت ٣ دقائق مع شريط تقدم على شاشة القفل",
                            isOk: ActivityAuthorizationInfo().areActivitiesEnabled
                        ) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(theme.card))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(theme.line, lineWidth: 1))

                    // Test Bell Button ("جرّب الجرس الآن")
                    Button {
                        let sample = Lecture(
                            id: "test_\(Int(Date().timeIntervalSince1970))",
                            title: "حصة تجريبية",
                            location: "قاعة ١٠١",
                            begin: Date().addingTimeInterval(3 * 60),
                            end: Date().addingTimeInterval(48 * 60),
                            calendarId: "test",
                            colorHex: 0x10B981,
                            ordinal: 2
                        )
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            notifier.triggerPopup(for: sample, playChime: true)
                        }
                    } label: {
                        Text("جرّب الجرس الآن")
                            .font(.system(size: 16.5, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [JarasPalette.primaryDeep, JarasPalette.primary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            )
                            .shadow(color: JarasPalette.primary.opacity(0.35), radius: 10, x: 0, y: 5)
                    }

                    // Section 3: Calendars ("تقويمات الحصص")
                    sectionLabel("تقويمات الحصص")
                    VStack(spacing: 0) {
                        if repo.calendars.isEmpty {
                            Text("لا توجد تقويمات متزامنة على الجهاز")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(theme.inkSoft)
                                .padding(20)
                                .frame(maxWidth: .infinity)
                        } else {
                            ForEach(Array(repo.calendars.enumerated()), id: \.element.id) { idx, cal in
                                if idx > 0 {
                                    Divider().background(theme.line).padding(.horizontal, 16)
                                }
                                Button {
                                    repo.toggleCalendar(cal.id)
                                } label: {
                                    HStack(spacing: 14) {
                                        Circle()
                                            .fill(Color(hex: cal.colorHex))
                                            .frame(width: 14, height: 14)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(cal.title)
                                                .font(.system(size: 15.5, weight: .bold))
                                                .foregroundColor(theme.ink)
                                            Text(cal.account)
                                                .font(.system(size: 12.5, weight: .regular))
                                                .foregroundColor(theme.inkSoft)
                                        }
                                        Spacer()
                                        Image(systemName: cal.isSelected ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 22))
                                            .foregroundColor(cal.isSelected ? JarasPalette.primary : theme.inkFaint)
                                    }
                                    .padding(16)
                                }
                            }
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(theme.card))
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(theme.line, lineWidth: 1))

                    Text("يدقّ الجرس قبل بداية كل حصة بثلاث دقائق، وعند إغلاق النافذة يستمر المؤقت التنازلي مع شريط التقدم في الجزيرة التفاعلية وشاشة القفل حتى تبدأ الحصة.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(theme.inkFaint)
                        .padding(.horizontal, 6)
                        .padding(.bottom, 24)
                }
                .padding(22)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13.5, weight: .bold))
            .foregroundColor(theme.inkSoft)
            .padding(.horizontal, 6)
    }

    private func settingStatusRow(
        icon: String,
        title: String,
        subtitle: String,
        isOk: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(theme.primaryTint)
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .foregroundColor(JarasPalette.primary)
                        .font(.system(size: 18, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15.5, weight: .bold))
                        .foregroundColor(theme.ink)
                    Text(subtitle)
                        .font(.system(size: 12.5, weight: .regular))
                        .foregroundColor(theme.inkSoft)
                }
                Spacer()
                Text(isOk ? "مفعّل" : "تفعيل")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(isOk ? JarasPalette.primary : theme.sunInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(isOk ? theme.mintTint : theme.sunTint)
                    )
            }
            .padding(16)
        }
    }
}
