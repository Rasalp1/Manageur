import Foundation

public enum ServiceCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case aiAndModels = "AI & Models"
    case cloudAndInfra = "Cloud & Infrastructure"
    case devTools = "Developer Tools"
    case databaseAndStorage = "Database & Storage"
    case communication = "Communication & Email"
    case financeAndPayments = "Finance & Payments"
    case analyticsAndMonitoring = "Analytics & Monitoring"
    case productivity = "Productivity & Docs"
    case identityAndSecurity = "Identity & Security"
    case marketingAndSales = "Marketing & Sales"
    case designAndMedia = "Design & Media"
    case other = "Other"

    public var id: String { rawValue }

    public var sfSymbol: String {
        switch self {
        case .aiAndModels: return "sparkles"
        case .cloudAndInfra: return "cloud.fill"
        case .devTools: return "hammer.fill"
        case .databaseAndStorage: return "cylinder.split.1x2.fill"
        case .communication: return "envelope.fill"
        case .financeAndPayments: return "creditcard.fill"
        case .analyticsAndMonitoring: return "chart.xyaxis.line"
        case .productivity: return "doc.text.fill"
        case .identityAndSecurity: return "key.fill"
        case .marketingAndSales: return "megaphone.fill"
        case .designAndMedia: return "paintpalette.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }
}
