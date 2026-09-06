import Foundation
import SwiftUI

public enum ServiceStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case active = "Active"
    case trial = "In Trial"
    case paused = "Paused"
    case needsCancellation = "Needs Cancellation"
    case deprecated = "Deprecated"

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .active: return .green
        case .trial: return .orange
        case .paused: return .yellow
        case .needsCancellation: return .red
        case .deprecated: return .secondary
        }
    }

    public var iconName: String {
        switch self {
        case .active: return "checkmark.circle.fill"
        case .trial: return "clock.badge.exclamationmark"
        case .paused: return "pause.circle.fill"
        case .needsCancellation: return "exclamationmark.octagon.fill"
        case .deprecated: return "archivebox.fill"
        }
    }
}
