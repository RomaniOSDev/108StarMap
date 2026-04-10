//
//  ContentView.swift
//  108StarMap
//
//  Created by Роман Главацкий on 31.03.2026.
//

import SwiftUI
import UserNotifications

struct ContentView: View {
    @StateObject private var viewModel = StarMapViewModel()
    @AppStorage("starmap_onboarding_completed") private var isOnboardingCompleted = false

    var body: some View {
        Group {
            if isOnboardingCompleted {
                TabView {
                    HomeView(viewModel: viewModel)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }

                    ConstellationsView(viewModel: viewModel)
                        .tabItem {
                            Label("Constellations", systemImage: "star.circle.fill")
                        }

                    StarsView(viewModel: viewModel)
                        .tabItem {
                            Label("Stars", systemImage: "star.fill")
                        }

                    ObservationsView(viewModel: viewModel)
                        .tabItem {
                            Label("Observations", systemImage: "binoculars.fill")
                        }

                    EventsView(viewModel: viewModel)
                        .tabItem {
                            Label("Events", systemImage: "calendar")
                        }

                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }
            } else {
                OnboardingView(isCompleted: $isOnboardingCompleted)
            }
        }
        .tint(.starAccent)
        .onAppear {
            viewModel.loadFromUserDefaults()
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
