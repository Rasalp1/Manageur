import SwiftUI

public struct ServiceListView: View {
    @ObservedObject var viewModel: InventoryViewModel

    public init(viewModel: InventoryViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search and sorting bar
            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search services, tags, emails...", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)

                    if !viewModel.searchQuery.isEmpty {
                        Button(action: { viewModel.searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(6)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)

                Menu {
                    Picker("Sort by", selection: $viewModel.sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .menuStyle(.borderlessButton)
                .frame(width: 28)
                .help("Sort items")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // List or empty state
            if viewModel.filteredServices.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("No Services Found")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    if !viewModel.searchQuery.isEmpty || viewModel.selectedWorkspace != nil || viewModel.selectedCategory != nil || viewModel.selectedStatus != nil || viewModel.selectedAuditFilter != nil {
                        Button("Reset Filters") {
                            viewModel.searchQuery = ""
                            viewModel.selectedWorkspace = nil
                            viewModel.selectedCategory = nil
                            viewModel.selectedStatus = nil
                            viewModel.selectedAuditFilter = nil
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    } else {
                        Button("Add First Service") {
                            viewModel.isShowingNewServiceSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $viewModel.selectedServiceId) {
                    ForEach(viewModel.filteredServices) { service in
                        NavigationLink(value: service.id) {
                            ServiceRowView(service: service)
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            // Bottom summary status bar
            Divider()
            HStack {
                Text("\(viewModel.filteredServices.count) of \(viewModel.services.count) services")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()

                if let currentWs = viewModel.selectedWorkspace {
                    Text("Workspace: \(currentWs)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .navigationTitle(navigationTitle)
    }

    private var navigationTitle: String {
        if let ws = viewModel.selectedWorkspace {
            return ws
        } else if let cat = viewModel.selectedCategory {
            return cat.rawValue
        } else if let stat = viewModel.selectedStatus {
            return stat.rawValue
        } else if viewModel.selectedAuditFilter != nil {
            return "Audit Flags"
        } else {
            return "All Services"
        }
    }
}
