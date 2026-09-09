import Foundation

/// How / where the user originally discovered and signed up for the service.
public enum SignupSource: String, Codable, CaseIterable, Identifiable, Sendable {
    case organic        = "Organic / Search"
    case referral       = "Referral"
    case productHunt    = "Product Hunt"
    case appStore       = "App Store"
    case directPurchase = "Direct Purchase"
    case trial          = "Free Trial"
    case bundled        = "Bundled / Included"
    case other          = "Other"

    public var id: String { rawValue }

    public var sfSymbol: String {
        switch self {
        case .organic:        return "magnifyingglass"
        case .referral:       return "person.2.fill"
        case .productHunt:    return "flame.fill"
        case .appStore:       return "bag.fill"
        case .directPurchase: return "creditcard"
        case .trial:          return "clock.badge.questionmark"
        case .bundled:        return "shippingbox.fill"
        case .other:          return "ellipsis.circle"
        }
    }
}
