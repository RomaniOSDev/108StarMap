import Foundation

func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd MMMM yyyy, HH:mm"
    formatter.locale = Locale(identifier: "en_US")
    return formatter.string(from: date)
}

func formattedShortDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yyyy"
    formatter.locale = Locale(identifier: "en_US")
    return formatter.string(from: date)
}
