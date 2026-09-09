import Foundation

/// The platform(s) on which a service / tool is used.
public enum AppPlatform: String, Codable, CaseIterable, Identifiable, Sendable {
    case web       = "Web"
    case macOS     = "macOS"
    case iOS       = "iOS"
    case android   = "Android"
    case windows   = "Windows"
    case cli       = "CLI / Terminal"
    case api       = "API"
    case other     = "Other"

    public var id: String { rawValue }

    public var sfSymbol: String {
        switch self {
        case .web:     return "globe"
        case .macOS:   return "desktopcomputer"
        case .iOS:     return "iphone"
        case .android: return "smartphone"
        case .windows: return "pc"
        case .cli:     return "terminal"
        case .api:     return "arrow.left.arrow.right"
        case .other:   return "questionmark.square"
        }
    }
}
