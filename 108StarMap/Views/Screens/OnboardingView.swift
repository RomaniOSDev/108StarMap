import SwiftUI

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
}

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        .init(
            title: "Explore the Night Sky",
            subtitle: "Build your own constellation catalog and keep every detail in one place.",
            icon: "sparkles"
        ),
        .init(
            title: "Track Stars",
            subtitle: "Add stars manually, organize by brightness, and mark your favorites.",
            icon: "star.fill"
        ),
        .init(
            title: "Save Observations",
            subtitle: "Log sessions, notes, and events to plan your next perfect stargazing night.",
            icon: "binoculars.fill"
        )
    ]

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.starAccent.opacity(0.45), Color.starCard],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 180, height: 180)
                                .shadow(color: .starAccent.opacity(0.35), radius: 20, x: 0, y: 12)

                            Image(systemName: page.icon)
                                .font(.system(size: 62, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        Text(page.title)
                            .font(.title.bold())
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)

                        Text(page.subtitle)
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 50)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.starAccent : Color.starCard)
                        .frame(width: index == currentPage ? 26 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation(.easeInOut) {
                        currentPage += 1
                    }
                } else {
                    isCompleted = true
                }
            } label: {
                Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .starPrimaryButtonStyle(cornerRadius: 14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .starScreenBackground()
    }
}

#Preview {
    OnboardingView(isCompleted: .constant(false))
}
