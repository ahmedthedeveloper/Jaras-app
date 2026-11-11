import SwiftUI

/// Main schedule screen:
/// - Emerald Green `HeroHeaderView`
/// - 14-day horizontal date selector strip
/// - Daily timeline of classes ("حصص اليوم") with time, duration, room, and live progress
/// - Full-screen 3D Green Bell Pop-up overlay when an alert triggers
struct MainView: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var repo: CalendarRepo
    @EnvironmentObject var notifier: NotificationManager

    @State private var selectedDay: Date = Ar.dayStart(Date())
    @State private var showSettings = false

    private var daysStrip: [Date] {
        let today = Ar.dayStart(Date())
        return (0..<14).map { Ar.addDays(today, $0) }
    }

    private var selectedLectures: [Lecture] {
        repo.lecturesByDay[selectedDay] ?? []
    }

    var body: some View {
        ZStack {
            theme.bg.ignoresSafeArea()

            if !repo.hasPermission {
                onboardingView
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        HeroHeaderView(
                            nextLecture: repo.nextLecture,
                            onOpenSettings: { showSettings = true }
                        )

                        // 14-Day Strip
                        dayStripView
                            .padding(.top, 18)

                        // Day Header ("حصص اليوم" + count badge)
                        HStack {
                            Text(selectedDay == Ar.dayStart(Date()) ? "حصص اليوم" : "حصص \(Ar.dayName(selectedDay))")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(theme.ink)
                            Spacer()
                            Text(Ar.lectureCount(selectedLectures.count))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(JarasPalette.primary)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule().fill(theme.primaryTint)
                                )
                        }
                        .padding(.horizontal, 22)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                        if selectedLectures.isEmpty {
                            emptyDayView
                        } else {
                            VStack(spacing: 14) {
                                ForEach(Array(selectedLectures.enumerated()), id: \.element.id) { idx, lecture in
                                    lectureTimelineRow(
                                        lecture: lecture,
                                        isFirst: idx == 0,
                                        isLast: idx == selectedLectures.count - 1
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                }
                .ignoresSafeArea(edges: .top)
            }

            // Full-Screen 3D Green Bell Pop-up Overlay
            if let alertLecture = notifier.activePopupLecture {
                AlertOverlayView(
                    lecture: alertLecture,
                    onDismiss: {
                        notifier.closePopupAndStartDeliveryTimer()
                    }
                )
                .zIndex(100)
                .transition(.opacity)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(theme)
                .environmentObject(repo)
                .environmentObject(notifier)
        }
        .onAppear {
            repo.checkAuthorization()
        }
    }

    // MARK: - 14-Day Strip

    private var dayStripView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(daysStrip, id: \.self) { day in
                    let isSelected = (day == selectedDay)
                    let isToday = (day == Ar.dayStart(Date()))
                    let hasLectures = !(repo.lecturesByDay[day]?.isEmpty ?? true)

                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            selectedDay = day
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(isToday ? "اليوم" : Ar.dayShort(day))
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(isSelected ? .white.opacity(0.9) : theme.inkSoft)

                            Text(Ar.dayOfMonth(day))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(isSelected ? .white : theme.ink)

                            Circle()
                                .fill(isSelected ? Color.white : (hasLectures ? JarasPalette.primary : Color.clear))
                                .frame(width: 5, height: 5)
                        }
                        .frame(width: 62, height: 84)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(isSelected ? JarasPalette.primary : theme.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(isSelected ? Color.clear : theme.line, lineWidth: 1)
                        )
                        .shadow(
                            color: isSelected ? JarasPalette.primary.opacity(0.38) : .clear,
                            radius: 10, x: 0, y: 4
                        )
                    }
                }
            }
            .padding(.horizontal, 22)
        }
    }

    // MARK: - Empty Day State

    private var emptyDayView: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(theme.primaryTint)
                    .frame(width: 118, height: 118)
                Text("🔔")
                    .font(.system(size: 52))
            }
            .padding(.top, 26)

            Text("لا حصص في هذا اليوم")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.ink)

            Text("الجرس يستريح… استمتع بوقتك!")
                .font(.system(size: 14.5, weight: .regular))
                .foregroundColor(theme.inkSoft)
        }
        .padding(.vertical, 36)
    }

    // MARK: - Timeline Lecture Row

    private func lectureTimelineRow(lecture: Lecture, isFirst: Bool, isLast: Bool) -> some View {
        let now = Date()
        let ongoing = lecture.isOngoing(at: now)
        let past = lecture.isPast(at: now)

        return HStack(alignment: .top, spacing: 12) {
            // Rail Bead & Thread
            VStack(spacing: 0) {
                Rectangle()
                    .fill(isFirst ? Color.clear : theme.line)
                    .frame(width: 2, height: 32)
                Circle()
                    .fill(ongoing ? JarasPalette.primary : (past ? theme.inkFaint : theme.bg))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(past ? theme.inkFaint : JarasPalette.primary, lineWidth: 2.5)
                    )
                Rectangle()
                    .fill(isLast ? Color.clear : theme.line)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 18)

            // Lecture Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(Ar.lecture(lecture.ordinal))
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(ongoing ? .white : JarasPalette.primary)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(ongoing ? JarasPalette.primary : theme.primaryTint)
                        )

                    Spacer()

                    if ongoing {
                        HStack(spacing: 5) {
                            Circle().fill(Color.white).frame(width: 6, height: 6)
                            Text("الآن")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(JarasPalette.primaryDeep))
                    } else if past {
                        Text("انتهت")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.inkFaint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(theme.line.opacity(0.6)))
                    }
                }

                Text(lecture.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(past ? theme.inkSoft : theme.ink)

                HStack(spacing: 14) {
                    Label(Ar.range(from: lecture.begin, to: lecture.end), systemImage: "clock")
                    Label(Ar.span(minutes: lecture.durationMinutes), systemImage: "hourglass")
                    if !lecture.location.isEmpty {
                        Label(lecture.location, systemImage: "mappin.and.ellipse")
                    }
                }
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(theme.inkSoft)

                if ongoing {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(theme.line)
                            Capsule()
                                .fill(JarasPalette.primary)
                                .frame(width: max(8, geo.size.width * lecture.progressFraction(at: now)))
                        }
                    }
                    .frame(height: 6)
                    .padding(.top, 4)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(ongoing ? JarasPalette.primary : theme.line, lineWidth: ongoing ? 1.8 : 1)
            )
            .onTapGesture {
                // Allow tapping any lecture to preview its 3D Green Bell Pop-up
                notifier.triggerPopup(for: lecture, playChime: true)
            }
        }
    }

    // MARK: - Onboarding Sheet

    private var onboardingView: some View {
        ZStack {
            JarasPalette.heroGradient.ignoresSafeArea()

            VStack(spacing: 20) {
                GreenBellView(isRinging: true)
                    .frame(width: 175, height: 175)

                Text("جرس الحصص")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)

                Text("يقرأ جدول حصصك من تقويم Google المتزامن على الآيفون، وينبّهك قبل كل حصة بثلاث دقائق مع مؤقت حي في الجزيرة التفاعلية وشاشة القفل.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Button {
                    Task {
                        _ = await repo.requestAccess()
                        _ = await notifier.requestPermission()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 20, weight: .bold))
                        Text("ربط التقويم وتفعيل الجرس")
                            .font(.system(size: 17.5, weight: .bold))
                    }
                    .foregroundColor(JarasPalette.forest)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Capsule().fill(Color.white))
                    .shadow(color: Color(hex: 0x054E38, alpha: 0.45), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 30)
                .padding(.top, 12)
            }
        }
    }
}
