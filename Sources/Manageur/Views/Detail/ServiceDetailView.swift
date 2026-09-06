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

                    Divider()

                    // Tab Selector
                    Picker("", selection: $selectedTab) {
                        ForEach(DetailTab.allCases) { tab in
                            Label(tab.rawValue, systemImage: tab.iconName).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    Divider()

                    // Tab Content
                    tabContent(service: service)

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
        HStack(spacing: 16) {
            ServiceLogoView(
                domain: service.cleanedDomain,
                category: service.category,
                size: 46
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(service.name)
                        .font(.title2.bold())
                        .lineLimit(1)

                    Text(service.workspace)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .cornerRadius(6)
                }

                HStack(spacing: 8) {
                    if !service.cleanedDomain.isEmpty {
                        Text(service.cleanedDomain)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Circle().fill(service.status.color).frame(width: 7, height: 7)
                    Text(service.status.rawValue)
                        .font(.caption)
                        .foregroundColor(service.status.color)
                }
            }

            Spacer()

            Button(role: .destructive, action: { isShowingDeleteConfirmation = true }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help("Delete service record")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(nsColor: .windowBackgroundColor))
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
            Text("File: \(service.workspace)/\(service.slug).json")
                .font(.caption.monospaced())
                .foregroundColor(.secondary)

            Spacer()

            Button(action: revealInFinder) {
                Label("Reveal in Finder", systemImage: "folder")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func revealInFinder() {
        guard let s = draftService else { return }
        let url = ServiceStorageManager.shared.rootDirectory
            .appendingPathComponent(s.workspace)
            .appendingPathComponent("\(s.slug).json")
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
