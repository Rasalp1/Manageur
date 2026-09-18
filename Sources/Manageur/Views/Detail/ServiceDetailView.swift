import SwiftUI
import AppKit

public enum DetailTab: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case auth = "Auth & Access"
    case billing = "Billing"
    case context = "Projects"
    case privacy = "Privacy & Audit"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .overview: return "info.circle"
        case .auth: return "key.fill"
        case .billing: return "creditcard.fill"
        case .context: return "cube.box.fill"
        case .privacy: return "hand.raised.fill"
        }
    }

    /// Whether a given tab is applicable for a service with the specified category.
    public func isVisible(for category: ServiceCategory) -> Bool {
        if self == .billing { return category.isBillingRelevant }
        return true
    }
}

public struct ServiceDetailView: View {
    @ObservedObject var viewModel: InventoryViewModel
    let serviceId: UUID

    @State private var draftService: ServiceItem? = nil
    @State private var selectedTab: DetailTab = .overview
    @State private var isShowingDeleteConfirmation: Bool = false
    @State private var originalWorkspace: String = ""
    @State private var originalSlug: String = ""

    public init(viewModel: InventoryViewModel, serviceId: UUID) {
        self.viewModel = viewModel
        self.serviceId = serviceId
    }

    public var body: some View {
        Group {
            if let service = draftService {
                VStack(spacing: 0) {
                    // Header Bar
                    headerBar(service: service)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            ForEach(DetailTab.allCases.filter { $0.isVisible(for: service.category) }) { tab in
                                Button { selectedTab = tab } label: {
                                    VStack(spacing: 12) {
                                        Text(tab.rawValue)
                                            .font(.system(size: 12, weight: selectedTab == tab ? .semibold : .regular))
                                            .foregroundStyle(selectedTab == tab ? Theme.accent : .secondary)
                                        Rectangle().fill(selectedTab == tab ? Theme.accent : .clear).frame(height: 2)
                                    }
                                    .fixedSize(horizontal: true, vertical: false)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
                            }
                        }
                        .padding(.horizontal, Theme.pageInset).padding(.top, 16)
                    }
                    .frame(height: 46)
                    .onChange(of: service.category) { _, newCategory in
                        // If the current tab is no longer visible, fall back to overview
                        if !selectedTab.isVisible(for: newCategory) {
                            selectedTab = .overview
                        }
                    }

                    Divider()

                    // Tab Content
                    tabContent(service: service)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Divider()

                    // Bottom Bar
                    footerBar(service: service)
                }
            } else {
                VStack {
                    ProgressView()
                }
            }
        }
        .background(Theme.canvas)
        .onAppear {
            loadDraft()
        }
        .onChange(of: serviceId) { _, _ in
            loadDraft()
        }
        .confirmationDialog("Delete Service?", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete '\(draftService?.name ?? "Service")'", role: .destructive) {
                if let s = draftService {
                    viewModel.deleteService(s)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will delete the JSON file from disk. This action cannot be undone.")
        }
    }

    private func loadDraft() {
        if let original = viewModel.services.first(where: { $0.id == serviceId }) {
            self.draftService = original
            self.originalWorkspace = original.workspace
            self.originalSlug = original.slug
        }
    }

    private func saveDraft() {
        guard let draft = draftService else { return }
        viewModel.updateService(draft, oldWorkspace: originalWorkspace, oldSlug: originalSlug)
        self.originalWorkspace = draft.workspace
        self.originalSlug = draft.slug
    }

    // MARK: - Header Bar

    @ViewBuilder
    private func headerBar(service: ServiceItem) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Label(service.workspace, systemImage: "folder")
                Image(systemName: "chevron.right").font(.system(size: 8, weight: .semibold))
                Text(service.category.rawValue).lineLimit(1)
                Spacer(minLength: 0)
                Menu {
                    Button("Reveal in Finder", action: revealInFinder)
                    Divider()
                    Button("Delete service…", role: .destructive) { isShowingDeleteConfirmation = true }
                } label: {
                    Image(systemName: "ellipsis.circle").font(.system(size: 16))
                }
                .menuStyle(.borderlessButton).fixedSize().help("Service actions")
                .accessibilityLabel("Service actions")
            }
            .font(.system(size: 11)).foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 14) {
                ServiceLogoView(domain: service.cleanedDomain, category: service.category, size: 48)
                VStack(alignment: .leading, spacing: 7) {
                    Text(service.name).font(.system(size: 25, weight: .bold))
                        .lineLimit(2).textSelection(.enabled).help(service.name)
                    HStack(spacing: 6) {
                        Circle().fill(service.status.color).frame(width: 6, height: 6)
                        Text(service.status.rawValue)
                        if !service.cleanedDomain.isEmpty {
                            Text("·")
                            Text(service.cleanedDomain).lineLimit(1)
                        }
                    }
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                if let url = websiteURL(service) {
                    Link(destination: url) {
                        Label("Open website", systemImage: "arrow.up.right")
                    }
                    .buttonStyle(.borderedProminent)
                }
                // Only show billing pill for billing-relevant categories
                if service.category.isBillingRelevant {
                    Text(service.billingInfo.isPaid ? service.billingInfo.formattedCost : "Free plan")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                // Show usage frequency pill for all entries
                Label(service.usageFrequency.rawValue, systemImage: service.usageFrequency.sfSymbol)
                    .font(.system(size: 11))
                    .foregroundStyle(service.usageFrequency.color.opacity(0.9))
                Spacer(minLength: 0)
            }
            .controlSize(.regular)
        }
        .padding(Theme.pageInset).padding(.bottom, 2)
    }

    private func websiteURL(_ service: ServiceItem) -> URL? {
        let address = service.websiteURL.flatMap { $0.isEmpty ? nil : $0 }
            ?? (service.cleanedDomain.isEmpty ? nil : "https://\(service.cleanedDomain)")
        guard let address, let url = URL(string: address),
              let scheme = url.scheme?.lowercased(), ["https", "http"].contains(scheme),
              url.host != nil else { return nil }
        return url
    }

    // MARK: - Tab Content

    @ViewBuilder
    private func tabContent(service: ServiceItem) -> some View {
        if let binding = Binding($draftService) {
            switch selectedTab {
            case .overview:
                OverviewTab(
                    service: binding,
                    workspaces: viewModel.availableWorkspaces,
                    onSave: { saveDraft() }
                )
            case .auth:
                AuthTab(
                    authInfo: binding.authInfo,
                    onSave: { saveDraft() }
                )
            case .billing:
                BillingTab(
                    billingInfo: binding.billingInfo,
                    onSave: { saveDraft() }
                )
            case .context:
                ContextTab(
                    contextInfo: binding.contextInfo,
                    onSave: { saveDraft() }
                )
            case .privacy:
                PrivacyTab(
                    privacyInfo: binding.privacyInfo,
                    serviceStatus: service.status,
                    onSave: { saveDraft() }
                )
            }
        }
    }

    // MARK: - Footer Bar

    @ViewBuilder
    private func footerBar(service: ServiceItem) -> some View {
        HStack {
            Label("\(service.slug).json", systemImage: "doc.text")
                .font(.system(size: 10))
                .lineLimit(1)
                .help("\(service.workspace)/\(service.slug).json")
                .foregroundColor(.secondary)

            Spacer()

            Button(action: revealInFinder) {
                Label("Reveal in Finder", systemImage: "folder")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
        }
        .padding(.horizontal, Theme.pageInset)
        .padding(.vertical, 12)
        .background(Theme.canvas)
    }

    private func revealInFinder() {
        guard let s = draftService else { return }
        guard let url = ServiceStorageManager.shared.fileURL(for: s) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
