import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let cardColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .foregroundStyle(.gray)
                    .font(.caption)
            }
            Text(value)
                .foregroundStyle(.white)
                .font(.title2.bold())
        }
        .padding()
        .frame(width: 150, alignment: .leading)
        .starCardStyle(cornerRadius: 12)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color

    var body: some View {
        Text(title)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    colors: isSelected ? [color, color.opacity(0.7)] : [Color.starCard, Color.starCard.opacity(0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(isSelected ? Color.starBackground : color)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color, lineWidth: 1))
            .shadow(color: color.opacity(isSelected ? 0.35 : 0.12), radius: isSelected ? 8 : 4, x: 0, y: 3)
    }
}

struct ConstellationCard: View {
    let constellation: Constellation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(constellation.name)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(constellation.latinName)
                .font(.caption)
                .foregroundColor(.starAccent)
            Text(constellation.visibility.rawValue)
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(constellation.visibility == .allYear ? Color.starAccent.opacity(0.2) : Color.starCard)
                .foregroundStyle(constellation.visibility == .allYear ? Color.starAccent : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            HStack {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.starAccent)
                Text("\(constellation.stars.count) stars")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .padding()
        .frame(width: 170, alignment: .leading)
        .starCardStyle(cornerRadius: 12)
    }
}

struct ObservationRow: View {
    let observation: Observation

    var body: some View {
        HStack {
            Image(systemName: "binoculars.fill")
                .foregroundColor(.starAccent)
                .font(.title3)
            VStack(alignment: .leading) {
                Text(observation.starName)
                    .foregroundStyle(.white)
                    .font(.headline)
                Text(observation.constellationName)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(formattedDate(observation.date))
                    .font(.caption)
                    .foregroundStyle(.gray)
                if let rating = observation.rating {
                    HStack(spacing: 2) {
                        ForEach(1...rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.starAccent)
                        }
                    }
                }
            }
        }
        .padding()
        .starCardStyle(cornerRadius: 8)
    }
}

struct StarRow: View {
    let star: Star

    var body: some View {
        HStack {
            Image(systemName: star.brightness.icon)
                .foregroundColor(.starAccent)
            VStack(alignment: .leading) {
                Text(star.name)
                    .foregroundStyle(.white)
                if !star.designation.isEmpty {
                    Text(star.designation)
                        .font(.caption)
                        .foregroundColor(.starAccent)
                }
            }
            Spacer()
            Text(star.brightness.description)
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .padding()
        .starCardStyle(cornerRadius: 8)
    }
}
