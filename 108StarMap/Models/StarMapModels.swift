import Foundation

enum Hemisphere: String, CaseIterable, Codable {
    case northern = "Northern Hemisphere"
    case southern = "Southern Hemisphere"
    case equatorial = "Equatorial"

    var icon: String {
        switch self {
        case .northern: return "arrow.up"
        case .southern: return "arrow.down"
        case .equatorial: return "arrow.left.and.right"
        }
    }
}

enum Visibility: String, CaseIterable, Codable {
    case allYear = "All Year"
    case summer = "Summer"
    case winter = "Winter"
    case spring = "Spring"
    case autumn = "Autumn"
    case nightOnly = "Night Only"

    var icon: String {
        switch self {
        case .allYear: return "calendar"
        case .summer: return "sun.max.fill"
        case .winter: return "snowflake"
        case .spring: return "leaf.fill"
        case .autumn: return "wind"
        case .nightOnly: return "moon.stars"
        }
    }
}

enum StarBrightness: Int, CaseIterable, Codable {
    case magnitude1 = 1
    case magnitude2 = 2
    case magnitude3 = 3
    case magnitude4 = 4
    case magnitude5 = 5

    var description: String {
        switch self {
        case .magnitude1: return "1m (very bright)"
        case .magnitude2: return "2m (bright)"
        case .magnitude3: return "3m (medium)"
        case .magnitude4: return "4m (faint)"
        case .magnitude5: return "5m (very faint)"
        }
    }

    var icon: String {
        switch self {
        case .magnitude1: return "star.fill"
        case .magnitude2: return "star.fill"
        case .magnitude3: return "star.leadinghalf.filled"
        case .magnitude4: return "star"
        case .magnitude5: return "star"
        }
    }
}

struct Constellation: Identifiable, Codable {
    let id: UUID
    var name: String
    var latinName: String
    var abbreviation: String
    var hemisphere: Hemisphere
    var visibility: Visibility
    var description: String
    var mythology: String?
    var brightestStar: String?
    var area: Int?
    var stars: [Star]
    var isFavorite: Bool
    let createdAt: Date
}

struct Star: Identifiable, Codable {
    let id: UUID
    var name: String
    var designation: String
    var brightness: StarBrightness
    var constellationId: UUID
    var constellationName: String
    var rightAscension: String?
    var declination: String?
    var distance: Double?
    var temperature: Int?
    var color: String?
    var description: String?
    var isFavorite: Bool
}

struct Observation: Identifiable, Codable {
    let id: UUID
    let date: Date
    var starId: UUID?
    var starName: String
    var constellationId: UUID
    var constellationName: String
    var location: String?
    var equipment: String?
    var conditions: String?
    var notes: String?
    var rating: Int?
    var isFavorite: Bool
}

struct AstronomicalEvent: Identifiable, Codable {
    let id: UUID
    var name: String
    var date: Date
    var description: String
    var visibility: String?
    var isNotified: Bool
}

struct ObservationSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    var location: String
    var conditions: String
    var equipment: [String]
    var observations: [Observation]
    var notes: String?
}
