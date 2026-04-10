import SwiftUI
import StoreKit
import UIKit

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                settingsRow(
                    title: "Rate Us",
                    systemImage: "star.bubble.fill",
                    action: rateApp
                )

                settingsRow(
                    title: ExternalLink.privacyPolicy.title,
                    systemImage: "lock.doc.fill",
                    action: { open(link: .privacyPolicy) }
                )

                settingsRow(
                    title: ExternalLink.termsOfUse.title,
                    systemImage: "doc.text.fill",
                    action: { open(link: .termsOfUse) }
                )

                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .starScreenBackground()
        }
    }

    private func settingsRow(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundColor(.starAccent)
                    .frame(width: 26)

                Text(title)
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding()
            .starCardStyle(cornerRadius: 12)
        }
    }

    private func open(link: ExternalLink) {
        if let url = URL(string: link.rawValue) {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

#Preview {
    SettingsView()
}
