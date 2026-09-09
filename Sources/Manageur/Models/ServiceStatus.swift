import Foundation
import SwiftUI

public enum ServiceStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case active              = "Active"
    case trial               = "In Trial"
    case signedUp            = "Signed Up"   // Account exists, not yet actively used
    case paused              = "Paused"
    case needsCancellation   = "Needs Cancellation"
    case deprecated          = "Deprecated"

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .active:            return .green
        case .trial:             return .orange
        case .signedUp:          return Color(hue: 0.58, saturation: 0.6, brightness: 0.85) // muted blue
        case .paused:            return .yellow
        case .needsCancellation: return .red
        case .deprecated:        return .secondary
        }
    }

    public var iconName: String {
        switch self {
        case .active:            return "checkmark.circle.fill"
        case .trial:             return "clock.badge.exclamationmark"
        case .signedUp:          return "person.badge.plus"
        case .paused:            return "pause.circle.fill"
        case .needsCancellation: return "exclamationmark.octagon.fill"
        case .deprecated:        return "archivebox.fill"
        }
    }
}
