import Foundation

public enum ServiceCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    // --- Original 11 ---
    case aiAndModels            = "AI & Models"
    case cloudAndInfra          = "Cloud & Infrastructure"
    case devTools               = "Developer Tools"
    case databaseAndStorage     = "Database & Storage"
    case communication          = "Communication & Email"
    case financeAndPayments     = "Finance & Payments"
    case analyticsAndMonitoring = "Analytics & Monitoring"
    case productivity           = "Productivity & Docs"
    case identityAndSecurity    = "Identity & Security"
    case marketingAndSales      = "Marketing & Sales"
    case designAndMedia         = "Design & Media"

    // --- New categories ---
    case entertainmentAndStreaming = "Entertainment & Streaming"
    case healthAndFitness          = "Health & Fitness"
    case educationAndLearning      = "Education & Learning"
    case gaming                    = "Gaming"
    case hardwareAndIoT            = "Hardware & IoT"
    case mobileApps                = "Mobile Apps"
    case browserExtensions         = "Browser Extensions & Plugins"
    case newsAndPublications       = "News & Publications"
    case loyaltyAndRewards         = "Loyalty & Rewards"
    case governmentAndPublic       = "Government & Public Services"

    case other = "Other"

    public var id: String { rawValue }

    public var sfSymbol: String {
        switch self {
        case .aiAndModels:              return "sparkles"
        case .cloudAndInfra:            return "cloud.fill"
        case .devTools:                 return "hammer.fill"
        case .databaseAndStorage:       return "cylinder.split.1x2.fill"
        case .communication:            return "envelope.fill"
        case .financeAndPayments:       return "creditcard.fill"
        case .analyticsAndMonitoring:   return "chart.xyaxis.line"
        case .productivity:             return "doc.text.fill"
        case .identityAndSecurity:      return "key.fill"
        case .marketingAndSales:        return "megaphone.fill"
        case .designAndMedia:           return "paintpalette.fill"
        case .entertainmentAndStreaming: return "play.tv.fill"
        case .healthAndFitness:         return "heart.fill"
        case .educationAndLearning:     return "book.closed.fill"
        case .gaming:                   return "gamecontroller.fill"
        case .hardwareAndIoT:           return "sensor.tag.radiowaves.forward.fill"
        case .mobileApps:               return "iphone"
        case .browserExtensions:        return "puzzlepiece.extension.fill"
        case .newsAndPublications:      return "newspaper.fill"
        case .loyaltyAndRewards:        return "star.fill"
        case .governmentAndPublic:      return "building.columns.fill"
        case .other:                    return "square.grid.2x2.fill"
        }
    }

    /// Categories where billing/subscription tracking makes sense.
    /// Non-SaaS categories (hardware portals, browser extensions, loyalty, etc.)
    /// will have the Billing tab hidden by default in the detail view.
    public var isBillingRelevant: Bool {
        switch self {
        case .aiAndModels, .cloudAndInfra, .devTools, .databaseAndStorage,
             .communication, .financeAndPayments, .analyticsAndMonitoring,
             .productivity, .identityAndSecurity, .marketingAndSales,
             .designAndMedia, .entertainmentAndStreaming, .healthAndFitness,
             .educationAndLearning, .gaming, .newsAndPublications:
            return true
        case .hardwareAndIoT, .mobileApps, .browserExtensions,
             .loyaltyAndRewards, .governmentAndPublic, .other:
            return false
        }
    }

    /// Critical infrastructure categories that warrant 2FA audit even on free tier.
    public var isCriticalSecurity: Bool {
        switch self {
        case .cloudAndInfra, .devTools, .financeAndPayments, .identityAndSecurity:
            return true
        default:
            return false
        }
    }
}
