import Foundation
import SwiftUI
import Combine

public enum SortOption: String, CaseIterable, Identifiable {
    case nameAsc        = "Name (A-Z)"
    case nameDesc       = "Name (Z-A)"
    case costDesc       = "Cost (High to Low)"
    case renewalSoonest = "Renewal Date"
    case recentlyCreated = "Recently Added"
    case mostUsed       = "Most Used"

    public var id: String { rawValue }
}

@MainActor
public final class InventoryViewModel: ObservableObject {
    private let storage: ServiceStorageManager

    @Published public var services: [ServiceItem] = []
    @Published public var selectedServiceId: UUID?
    @Published public var selectedWorkspace: String? = nil        // nil = All
    @Published public var selectedCategory: ServiceCategory? = nil
    @Published public var selectedStatus: ServiceStatus? = nil
    @Published public var selectedAuditFilter: String? = nil
    @Published public var selectedUsageFrequency: UsageFrequency? = nil
    @Published public var selectedPlatform: AppPlatform? = nil
    @Published public var searchQuery: String = ""
    @Published public var sortOption: SortOption = .nameAsc
    @Published public var availableWorkspaces: [String] = []
    @Published public var auditWarnings: [AuditWarning] = []

    @Published public var isShowingNewServiceSheet: Bool = false
    @Published public var isShowingSettingsSheet: Bool = false

    public init(storage: ServiceStorageManager = .shared) {
        self.storage = storage
        self.storage.onExternalChange = { [weak self] in
            Task { @MainActor in
                self?.loadData()
            }
        }
        loadData()
    }

    public func loadData() {
        self.services = storage.loadAllServices()
        self.availableWorkspaces = storage.listWorkspaces()
        runAuditEngine()

        if let currentId = selectedServiceId, !services.contains(where: { $0.id == currentId }) {
            selectedServiceId = filteredServices.first?.id
        } else if selectedServiceId == nil {
            selectedServiceId = filteredServices.first?.id
        }
    }

    public var selectedService: ServiceItem? {
        services.first(where: { $0.id == selectedServiceId })
    }

    // MARK: - Filtered List

    public var filteredServices: [ServiceItem] {
        var list = services

        // Workspace filter
        if let ws = selectedWorkspace, !ws.isEmpty {
            list = list.filter { $0.workspace.caseInsensitiveCompare(ws) == .orderedSame }
        }

        // Category filter
        if let cat = selectedCategory {
            list = list.filter { $0.category == cat }
        }

        // Status filter
        if let stat = selectedStatus {
            list = list.filter { $0.status == stat }
        }

        // Usage frequency filter
        if let freq = selectedUsageFrequency {
            list = list.filter { $0.usageFrequency == freq }
        }

        // Platform filter
        if let platform = selectedPlatform {
            list = list.filter { $0.appPlatforms.contains(platform) }
        }

        // Audit Filter
        if let audit = selectedAuditFilter {
            let matchingServiceIds: Set<UUID>
            switch audit {
            case "expiring-trials":
                matchingServiceIds = Set(auditWarnings.filter { $0.category == "Trial" }.map(\.serviceId))
            case "missing-2fa":
                matchingServiceIds = Set(auditWarnings.filter { $0.category == "Security" }.map(\.serviceId))
            case "missing-gdpr":
                matchingServiceIds = Set(auditWarnings.filter { $0.category == "Privacy" }.map(\.serviceId))
            case "duplicates":
                matchingServiceIds = Set(auditWarnings.filter { $0.category == "Duplicate" }.map(\.serviceId))
            case "dormant":
                matchingServiceIds = Set(auditWarnings.filter { $0.category == "Dormant" }.map(\.serviceId))
            case "unreviewed-signups":
                matchingServiceIds = Set(auditWarnings.filter { $0.category == "Unreviewed" }.map(\.serviceId))
            case "all-audits":
                matchingServiceIds = Set(auditWarnings.map(\.serviceId))
            default:
                matchingServiceIds = []
            }
            list = list.filter { matchingServiceIds.contains($0.id) }
        }

        // Search query
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            list = list.filter { item in
                item.name.lowercased().contains(query) ||
                item.domain.lowercased().contains(query) ||
                item.tags.contains { $0.lowercased().contains(query) } ||
                item.category.rawValue.lowercased().contains(query) ||
                (item.authInfo.loginEmailOrUsername?.lowercased().contains(query) ?? false) ||
                (item.notes?.lowercased().contains(query) ?? false) ||
                (item.licenceKeyHint?.lowercased().contains(query) ?? false) ||
                item.signupSource.rawValue.lowercased().contains(query) ||
                item.appPlatforms.contains { $0.rawValue.lowercased().contains(query) }
            }
        }

        // Sorting
        switch sortOption {
        case .nameAsc:
            list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDesc:
            list.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .costDesc:
            list.sort { ($0.billingInfo.amount ?? 0) > ($1.billingInfo.amount ?? 0) }
        case .renewalSoonest:
            list.sort { (a, b) -> Bool in
                guard let aDate = a.billingInfo.nextRenewalDate else { return false }
                guard let bDate = b.billingInfo.nextRenewalDate else { return true }
                return aDate < bDate
            }
        case .recentlyCreated:
            list.sort { $0.dateCreated > $1.dateCreated }
        case .mostUsed:
            list.sort { $0.usageFrequency.sortWeight > $1.usageFrequency.sortWeight }
        }

        return list
    }

    // MARK: - CRUD

    public func createService(_ service: ServiceItem) {
        do {
            try storage.save(service: service)
            loadData()
            selectedServiceId = service.id
        } catch {
            print("Failed to create service: \(error)")
        }
    }

    public func updateService(_ service: ServiceItem, oldWorkspace: String? = nil, oldSlug: String? = nil) {
        do {
            try storage.save(service: service, oldWorkspace: oldWorkspace, oldSlug: oldSlug)
            loadData()
            selectedServiceId = service.id
        } catch {
            print("Failed to update service: \(error)")
        }
    }

    public func deleteService(_ service: ServiceItem) {
        do {
            try storage.delete(service: service)
            loadData()
            selectedServiceId = filteredServices.first?.id
        } catch {
            print("Failed to delete service: \(error)")
        }
    }

    public func addWorkspace(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard ServiceStorageManager.isSafePathComponent(trimmed) else { return }
        let wsDir = storage.rootDirectory.appendingPathComponent(trimmed, isDirectory: true)
        try? FileManager.default.createDirectory(at: wsDir, withIntermediateDirectories: true)
        self.availableWorkspaces = storage.listWorkspaces()
        self.selectedWorkspace = trimmed
    }

    // MARK: - Audit Engine

    public func runAuditEngine() {
        var warnings: [AuditWarning] = []
        let now = Date()
        let calendar = Calendar.current

        for service in services {

            // 1. Expiring / expired trials
            if service.status == .trial {
                if let renewal = service.billingInfo.nextRenewalDate {
                    let daysLeft = calendar.dateComponents([.day], from: now, to: renewal).day ?? 0
                    if daysLeft <= 0 {
                        warnings.append(AuditWarning(
                            serviceId: service.id,
                            serviceName: service.name,
                            workspace: service.workspace,
                            severity: .critical,
                            title: "Trial Expired or Expiring Today",
                            description: "Trial for '\(service.name)' expired or is ending today.",
                            category: "Trial"
                        ))
                    } else if daysLeft <= 7 {
                        warnings.append(AuditWarning(
                            serviceId: service.id,
                            serviceName: service.name,
                            workspace: service.workspace,
                            severity: .warning,
                            title: "Trial Expiring Soon (\(daysLeft) days)",
                            description: "Review '\(service.name)' to decide whether to cancel or subscribe.",
                            category: "Trial"
                        ))
                    }
                } else {
                    warnings.append(AuditWarning(
                        serviceId: service.id,
                        serviceName: service.name,
                        workspace: service.workspace,
                        severity: .info,
                        title: "Trial Without Renewal Date",
                        description: "No end date set for trial of '\(service.name)'.",
                        category: "Trial"
                    ))
                }
            }

            // 2. Missing 2FA on active paid / critical-category accounts
            if service.status == .active {
                let isPaid = service.billingInfo.isPaid
                let isCritical = service.category.isCriticalSecurity
                if (isPaid || isCritical) && service.authInfo.twoFactorMethod == .none {
                    warnings.append(AuditWarning(
                        serviceId: service.id,
                        serviceName: service.name,
                        workspace: service.workspace,
                        severity: isPaid ? .warning : .info,
                        title: "Missing 2FA Protection",
                        description: "'\(service.name)' has no two-factor authentication configured.",
                        category: "Security"
                    ))
                }
            }

            // 3. Deprecated or needs-cancellation without GDPR / deletion link
            if service.status == .deprecated || service.status == .needsCancellation {
                if (service.privacyInfo.gdprDeletionUrl ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    warnings.append(AuditWarning(
                        serviceId: service.id,
                        serviceName: service.name,
                        workspace: service.workspace,
                        severity: .info,
                        title: "No Deletion / GDPR Link",
                        description: "'\(service.name)' is marked \(service.status.rawValue) but has no recorded account deletion link.",
                        category: "Privacy"
                    ))
                }
            }

            // 4. Dormant accounts — active but never used for 90+ days
            if service.status == .active && service.usageFrequency == .never {
                let daysSinceCreated = calendar.dateComponents([.day], from: service.dateCreated, to: now).day ?? 0
                if daysSinceCreated >= 90 {
                    warnings.append(AuditWarning(
                        serviceId: service.id,
                        serviceName: service.name,
                        workspace: service.workspace,
                        severity: .info,
                        title: "Dormant Account",
                        description: "'\(service.name)' has been active for \(daysSinceCreated) days but is marked as never used. Consider deprecating or cancelling.",
                        category: "Dormant"
                    ))
                }
            }

            // 5. Unreviewed signups — signed-up status older than 30 days
            if service.status == .signedUp {
                let referenceDate = service.signupDate ?? service.dateCreated
                let daysOld = calendar.dateComponents([.day], from: referenceDate, to: now).day ?? 0
                if daysOld >= 30 {
                    warnings.append(AuditWarning(
                        serviceId: service.id,
                        serviceName: service.name,
                        workspace: service.workspace,
                        severity: .info,
                        title: "Unreviewed Signup (\(daysOld) days)",
                        description: "'\(service.name)' has been in 'Signed Up' state for \(daysOld) days. Decide: activate, trial, or delete this account.",
                        category: "Unreviewed"
                    ))
                }
            }
        }

        // 6. Duplicate / overlapping services in same workspace & category
        let groupedByWsAndCategory = Dictionary(grouping: services.filter { $0.status == .active }) { item in
            "\(item.workspace)::\(item.category.rawValue)"
        }

        for (key, group) in groupedByWsAndCategory where group.count >= 2 {
            let parts = key.components(separatedBy: "::")
            let ws = parts[0]
            let cat = parts[1]
            let names = group.map(\.name).joined(separator: ", ")

            for item in group {
                warnings.append(AuditWarning(
                    serviceId: item.id,
                    serviceName: item.name,
                    workspace: ws,
                    severity: .info,
                    title: "Potential Category Overlap (\(cat))",
                    description: "Workspace '\(ws)' has \(group.count) active services in \(cat): \(names).",
                    category: "Duplicate"
                ))
            }
        }

        self.auditWarnings = warnings
    }

    // MARK: - Computed summary

    /// Total count of all tracked entries regardless of status.
    public var totalTrackedCount: Int { services.count }
}
