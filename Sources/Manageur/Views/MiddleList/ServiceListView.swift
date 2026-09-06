import SwiftUI

public struct ServiceListView: View {
    @ObservedObject var viewModel: InventoryViewModel
    @FocusState private var searchFocused: Bool

    public init(viewModel: InventoryViewModel) { self.viewModel = viewModel }

    public var body: some View {
        let services = viewModel.filteredServices
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    Text(navigationTitle).font(.system(size: 21, weight: .bold)).lineLimit(2)
                    Spacer()
                    Text(services.count, format: .number)
                        .font(.system(size: 13)).monospacedDigit().foregroundStyle(.secondary)
                }
                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search services", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain).focused($searchFocused)
                        .accessibilityLabel("Search services, tags, and emails")
                    if !viewModel.searchQuery.isEmpty {
                        Button { viewModel.searchQuery = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain).help("Clear search").accessibilityLabel("Clear search")
                    } else {
                        Text("⌘F").font(.system(size: 11)).foregroundStyle(.tertiary)
                    }
                }
                .font(.system(size: 13)).padding(9)
                .background(Theme.secondarySurface, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.subtleBorder))
                HStack {
                    Menu {
                        Picker("Sort by", selection: $viewModel.sortOption) {
                            ForEach(SortOption.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        Label(viewModel.sortOption.rawValue, systemImage: "arrow.up.arrow.down")
                            .font(.system(size: 11))
                    }
                    .menuStyle(.borderlessButton).fixedSize().help("Sort services")
                    Spacer()
                    if hasFilters {
                        Button("Reset filters", action: resetFilters)
                            .buttonStyle(.plain).font(.system(size: 11)).foregroundStyle(Theme.accent)
                    }
                }
                .foregroundStyle(.secondary)
            }
            .padding(20)
            Divider()
            if services.isEmpty {
                VStack(spacing: 0) {
                    Spacer()
                    InventoryEmptyView(icon: hasFilters ? "magnifyingglass" : "square.stack.3d.up",
                        title: hasFilters ? "No services found" : "Your services, together",
                        message: hasFilters ? "Try another search or reset your filters to see more of your library." : "Keep track of accounts, subscriptions, and access in one place.")
                    if hasFilters {
                        Button("Reset search and filters", action: resetFilters).buttonStyle(.bordered)
                    } else {
                        Button("Add your first service") { viewModel.isShowingNewServiceSheet = true }
                            .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                }
                .padding(.bottom, 24).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $viewModel.selectedServiceId) {
                    ForEach(services) { service in
                        ServiceRowView(service: service)
                            .tag(service.id).listRowSeparator(.hidden)
                    }
                }
                .listStyle(.inset).scrollContentBackground(.hidden)
            }
            Divider()
            HStack {
                Text(viewModel.selectedWorkspace ?? "All workspaces").lineLimit(1)
                Spacer()
                Text("\(services.count) of \(viewModel.services.count) services").monospacedDigit()
            }
            .font(.system(size: 10)).foregroundStyle(.secondary)
            .padding(.horizontal, 20).padding(.vertical, 12)
        }
        .background(Theme.canvas)
        .background {
            Button("Search services") { searchFocused = true }
                .keyboardShortcut("f", modifiers: .command).hidden()
        }
        .onChange(of: services.map(\.id)) { _, ids in
            if let selected = viewModel.selectedServiceId, ids.contains(selected) { return }
            viewModel.selectedServiceId = ids.first
        }
    }

    private var hasFilters: Bool {
        !viewModel.searchQuery.isEmpty || viewModel.selectedWorkspace != nil ||
        viewModel.selectedCategory != nil || viewModel.selectedStatus != nil || viewModel.selectedAuditFilter != nil
    }

    private func resetFilters() {
        viewModel.searchQuery = ""
        viewModel.selectedWorkspace = nil
        viewModel.selectedCategory = nil
        viewModel.selectedStatus = nil
        viewModel.selectedAuditFilter = nil
    }

    private var navigationTitle: String {
        if let audit = viewModel.selectedAuditFilter {
            switch audit {
            case "expiring-trials": return "Expiring trials"
            case "missing-2fa": return "Missing 2FA"
            case "missing-gdpr": return "Account deletion"
            case "duplicates": return "Category overlaps"
            default: return "Audit & health"
            }
        }
        return viewModel.selectedWorkspace ?? viewModel.selectedCategory?.rawValue ?? viewModel.selectedStatus?.rawValue ?? "All services"
    }
}
