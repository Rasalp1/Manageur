import Foundation
import SwiftUI

/// How frequently the user actually uses this service.
public enum UsageFrequency: String, Codable, CaseIterable, Identifiable, Sendable {
    case daily      = "Daily"
    case weekly     = "Weekly"
    case occasional = "Occasionally"
    case rarely     = "Rarely"
    case never      = "Never / Dormant"

    public var id: String { rawValue }

    public var sfSymbol: String {
        switch self {
        case .daily:      return "bolt.fill"
        case .weekly:     return "calendar"
        case .occasional: return "clock.arrow.2.circlepath"
        case .rarely:     return "moon.zzz.fill"
        case .never:      return "archivebox"
        }
    }

    public var color: Color {
        switch self {
        case .daily:      return .green
        case .weekly:     return Color(hue: 0.38, saturation: 0.7, brightness: 0.7)
        case .occasional: return .orange
        case .rarely:     return .yellow
        case .never:      return .secondary
        }
    }

    /// Numeric weight for sorting (most-used first).
    public var sortWeight: Int {
        switch self {
        case .daily:      return 5
        case .weekly:     return 4
        case .occasional: return 3
        case .rarely:     return 2
        case .never:      return 1
        }
    }
}
