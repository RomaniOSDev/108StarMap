import Foundation

enum ExternalLink: String, CaseIterable {
    case privacyPolicy = "https://www.termsfeed.com/live/4f12f9a2-ce4a-4974-aa7b-555ad239bd0d"
    case termsOfUse = "https://www.termsfeed.com/live/0317923c-9b83-46e8-9215-554e6846df8c"

    var title: String {
        switch self {
        case .privacyPolicy: return "Privacy Policy"
        case .termsOfUse: return "Terms of Use"
        }
    }
}
