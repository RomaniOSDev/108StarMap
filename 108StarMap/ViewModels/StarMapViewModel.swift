import Foundation
import Combine
import UserNotifications

final class StarMapViewModel: ObservableObject {
    @Published var constellations: [Constellation] = []
    @Published var observations: [Observation] = []
    @Published var events: [AstronomicalEvent] = []

    @Published var searchText: String = ""
    @Published var selectedHemisphere: Hemisphere?
    @Published var selectedBrightness: StarBrightness?

    var totalStars: Int {
        constellations.reduce(0) { $0 + $1.stars.count }
    }

    var visibleNowCount: String {
        let season = getCurrentSeason()
        return "\(constellations.filter { $0.visibility.rawValue == season || $0.visibility == .allYear }.count)"
    }

    var seasonalConstellations: [Constellation] {
        let season = getCurrentSeason()
        return Array(constellations.filter { $0.visibility.rawValue == season || $0.visibility == .allYear }.prefix(5))
    }

    var recentObservations: [Observation] {
        Array(observations.sorted { $0.date > $1.date }.prefix(10))
    }

    var filteredConstellations: [Constellation] {
        var result = constellations
        if let selectedHemisphere {
            result = result.filter { $0.hemisphere == selectedHemisphere }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.latinName.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result.sorted { $0.name < $1.name }
    }

    var filteredStars: [Star] {
        var result = constellations.flatMap(\.stars)
        if let selectedBrightness {
            result = result.filter { $0.brightness == selectedBrightness }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.designation.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result.sorted { $0.brightness.rawValue < $1.brightness.rawValue }
    }

    func addConstellation(_ constellation: Constellation) {
        constellations.append(constellation)
        saveToUserDefaults()
    }

    func deleteConstellation(_ constellation: Constellation) {
        constellations.removeAll { $0.id == constellation.id }
        observations.removeAll { $0.constellationId == constellation.id }
        saveToUserDefaults()
    }

    func updateConstellation(_ constellation: Constellation) {
        guard let index = constellations.firstIndex(where: { $0.id == constellation.id }) else { return }
        constellations[index] = constellation
        saveToUserDefaults()
    }

    func toggleFavoriteConstellation(_ constellation: Constellation) {
        guard let index = constellations.firstIndex(where: { $0.id == constellation.id }) else { return }
        constellations[index].isFavorite.toggle()
        saveToUserDefaults()
    }

    func addStar(_ star: Star, to constellationId: UUID) {
        guard let index = constellations.firstIndex(where: { $0.id == constellationId }) else { return }
        constellations[index].stars.append(star)
        saveToUserDefaults()
    }

    func deleteStar(_ star: Star) {
        for index in constellations.indices {
            constellations[index].stars.removeAll { $0.id == star.id }
        }
        saveToUserDefaults()
    }

    func updateStar(_ star: Star) {
        for constellationIndex in constellations.indices {
            if let starIndex = constellations[constellationIndex].stars.firstIndex(where: { $0.id == star.id }) {
                constellations[constellationIndex].stars[starIndex] = star
                saveToUserDefaults()
                return
            }
        }
    }

    func toggleFavoriteStar(_ star: Star) {
        for i in constellations.indices {
            if let j = constellations[i].stars.firstIndex(where: { $0.id == star.id }) {
                constellations[i].stars[j].isFavorite.toggle()
                break
            }
        }
        saveToUserDefaults()
    }

    func addObservation(_ observation: Observation) {
        observations.append(observation)
        scheduleNotification(for: observation)
        saveToUserDefaults()
    }

    func deleteObservation(_ observation: Observation) {
        observations.removeAll { $0.id == observation.id }
        saveToUserDefaults()
    }

    func updateObservation(_ observation: Observation) {
        guard let index = observations.firstIndex(where: { $0.id == observation.id }) else { return }
        observations[index] = observation
        saveToUserDefaults()
    }

    func addEvent(_ event: AstronomicalEvent) {
        events.append(event)
        if event.isNotified {
            scheduleEventNotification(for: event)
        }
        saveToUserDefaults()
    }

    func deleteEvent(_ event: AstronomicalEvent) {
        events.removeAll { $0.id == event.id }
        cancelEventNotification(for: event)
        saveToUserDefaults()
    }

    func updateEvent(_ event: AstronomicalEvent) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[index] = event
        if event.isNotified {
            scheduleEventNotification(for: event)
        } else {
            cancelEventNotification(for: event)
        }
        saveToUserDefaults()
    }

    func toggleNotification(_ event: AstronomicalEvent) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[index].isNotified.toggle()
        if events[index].isNotified {
            scheduleEventNotification(for: events[index])
        } else {
            cancelEventNotification(for: events[index])
        }
        saveToUserDefaults()
    }

    private func getCurrentSeason() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 12, 1, 2: return "Winter"
        case 3, 4, 5: return "Spring"
        case 6, 7, 8: return "Summer"
        default: return "Autumn"
        }
    }

    private func scheduleNotification(for observation: Observation) {
        let content = UNMutableNotificationContent()
        content.title = "Observation reminder"
        content.body = "You observed \(observation.starName) in \(observation.constellationName)"
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: observation.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: observation.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleEventNotification(for event: AstronomicalEvent) {
        let content = UNMutableNotificationContent()
        content.title = "Astronomical event"
        content.body = event.name
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: event.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: event.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelEventNotification(for event: AstronomicalEvent) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [event.id.uuidString])
    }

    private let constellationsKey = "starmap_constellations"
    private let observationsKey = "starmap_observations"
    private let eventsKey = "starmap_events"

    func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(constellations) {
            UserDefaults.standard.set(encoded, forKey: constellationsKey)
        }
        if let encoded = try? JSONEncoder().encode(observations) {
            UserDefaults.standard.set(encoded, forKey: observationsKey)
        }
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: eventsKey)
        }
    }

    func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: constellationsKey),
           let decoded = try? JSONDecoder().decode([Constellation].self, from: data) {
            constellations = decoded
        }
        if let data = UserDefaults.standard.data(forKey: observationsKey),
           let decoded = try? JSONDecoder().decode([Observation].self, from: data) {
            observations = decoded
        }
        if let data = UserDefaults.standard.data(forKey: eventsKey),
           let decoded = try? JSONDecoder().decode([AstronomicalEvent].self, from: data) {
            events = decoded
        }
    }
}
