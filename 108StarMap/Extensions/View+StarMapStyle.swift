import SwiftUI

extension View {
    func starScreenBackground() -> some View {
        self.background(
            LinearGradient(
                colors: [Color.starBackground, Color(red: 0.05, green: 0.08, blue: 0.16)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    func starCardStyle(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(
                LinearGradient(
                    colors: [Color.starCard, Color.starCard.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.starAccent.opacity(0.18), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.starAccent.opacity(0.16), radius: 10, x: 0, y: 5)
    }

    func starPrimaryButtonStyle(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(
                LinearGradient(
                    colors: [Color.starAccent.opacity(0.95), Color.starAccent.opacity(0.65)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.starAccent.opacity(0.35), radius: 12, x: 0, y: 6)
    }
}
