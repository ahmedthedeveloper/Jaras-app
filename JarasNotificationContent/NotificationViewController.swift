import SwiftUI
import UIKit
import UserNotifications
import UserNotificationsUI

/// Renders the exact 3D Green Bell + MoE Medallion + Capsule Banner inside the iOS system
/// notification banner when expanded over any app (YouTube, Safari, etc.) or on the Lock Screen.
final class NotificationViewController: UIViewController, UNNotificationContentExtension {
    private var hostingController: UIHostingController<NotificationPopUpCard>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.03, green: 0.07, blue: 0.05, alpha: 1.0)
    }

    func didReceive(_ notification: UNNotification) {
        let info = notification.request.content.userInfo
        let ordinal = (info["ordinal"] as? Int) ?? 2
        let title = (info["title"] as? String) ?? notification.request.content.subtitle
        let location = (info["location"] as? String) ?? ""
        let beginTs = (info["begin"] as? TimeInterval) ?? Date().addingTimeInterval(180).timeIntervalSince1970
        let beginDate = Date(timeIntervalSince1970: beginTs)

        let cardView = NotificationPopUpCard(
            ordinal: ordinal,
            title: title,
            begin: beginDate,
            location: location
        )

        if let host = hostingController {
            host.rootView = cardView
        } else {
            let host = UIHostingController(rootView: cardView)
            host.view.backgroundColor = .clear
            addChild(host)
            view.addSubview(host.view)
            host.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                host.view.topAnchor.constraint(equalTo: view.topAnchor),
                host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
            host.didMove(toParent: self)
            hostingController = host
        }

        preferredContentSize = CGSize(width: view.bounds.width, height: 390)
    }
}

struct NotificationPopUpCard: View {
    let ordinal: Int
    let title: String
    let begin: Date
    let location: String

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x051209), Color(hex: 0x020604)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                GreenBellView(isRinging: true)
                    .frame(width: 175, height: 175)
                    .zIndex(2)

                CapsuleBannerView(
                    ordinal: ordinal,
                    title: title,
                    begin: begin,
                    location: location,
                    arcScale: 1.0
                )
                .padding(.top, -14)
                .zIndex(1)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}
