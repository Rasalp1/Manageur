import Foundation
import SwiftUI

public enum AuditSeverity: String, Codable, CaseIterable, Identifiable, Sendable {
    case info = "Info"
    case warning = "Warning"
    case critical = "Critical"

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }

    public var iconName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

public struct AuditWarning: Identifiable, Hashable, Sendable {
    public var id: String { "\(serviceId.uuidString)-\(title)" }
    public var serviceId: UUID
    public var serviceName: String
    public var workspace: String
    public var severity: AuditSeverity
    public var title: String
    public var description: String
    public var category: String

    public init(
        serviceId: UUID,
        serviceName: String,
        workspace: String,
        severity: AuditSeverity,
        title: String,
        description: String,
        category: String
    ) {
        self.serviceId = serviceId
        self.serviceName = serviceName
        self.workspace = workspace
        self.severity = severity
        self.title = title
        self.description = description
        self.category = category
    }
}
