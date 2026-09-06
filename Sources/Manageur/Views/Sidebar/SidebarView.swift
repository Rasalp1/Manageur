import SwiftUI

public struct SidebarView: View {
    @ObservedObject var viewModel: InventoryViewModel
    @State private var isShowingNewWorkspaceAlert = false
    @State private var newWorkspaceName = ""

    public init(viewModel: InventoryViewModel) { self.viewModel = viewModel }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 11) {
                ManageurAppIconView(size: 22)
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Manageur").font(.system(size: 16, weight: .semibold))
                    Text("Your service library").font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 26)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 3) {
                        sectionTitle("Library")
                        row("All services", icon: "square.grid.2x2", count: viewModel.services.count,
                            selected: viewModel.selectedWorkspace == nil && viewModel.selectedAuditFilter == nil && viewModel.selectedCategory == nil && viewModel.selectedStatus == nil) {
                            viewModel.selectedWorkspace = nil
                            viewModel.selectedAuditFilter = nil
                            viewModel.selectedCategory = nil
                            viewModel.selectedStatus = nil
                            viewModel.searchQuery = ""
                        }
                    }
                    VStack(spacing: 3) {
                        sectionTitle("Workspaces")
                        ForEach(viewModel.availableWorkspaces, id: \.self) { workspace in
                            row(workspace, icon: "folder", count: viewModel.services.filter { $0.workspace.caseInsensitiveCompare(workspace) == .orderedSame }.count,
                                selected: viewModel.selectedWorkspace == workspace) {
                                viewModel.selectedWorkspace = viewModel.selectedWorkspace == workspace ? nil : workspace
                                viewModel.selectedAuditFilter = nil
                            }
                        }
                        Button {
                            newWorkspaceName = ""
                            isShowingNewWorkspaceAlert = true
                        } label: {
                            Label("Add workspace…", systemImage: "plus")
                                .font(.system(size: 12)).frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10).padding(.vertical, 9)
                        }
                        .buttonStyle(.plain).foregroundStyle(.secondary)
                    }
                    VStack(spacing: 3) {
                        sectionTitle("Audit & health")
                        auditRow("Expiring trials", icon: "clock", filter: "expiring-trials", category: "Trial")
                        auditRow("Missing 2FA", icon: "shield.slash", filter: "missing-2fa", category: "Security")
                        auditRow("Account deletion", icon: "hand.raised", filter: "missing-gdpr", category: "Privacy")
                        auditRow("Category overlaps", icon: "square.on.square", filter: "duplicates", category: "Duplicate")
                    }
                    VStack(spacing: 3) {
                        sectionTitle("Categories")
                        ForEach(ServiceCategory.allCases) { category in
                            let count = viewModel.services.filter { $0.category == category }.count
                            if count > 0 || viewModel.selectedCategory == category {
                                row(category.rawValue, icon: category.sfSymbol, count: count, selected: viewModel.selectedCategory == category) {
                                    viewModel.selectedCategory = viewModel.selectedCategory == category ? nil : category
                                    viewModel.selectedAuditFilter = nil
                                }
                            }
                        }
                    }
                    VStack(spacing: 3) {
                        sectionTitle("Status")
                        ForEach(ServiceStatus.allCases) { status in
                            let count = viewModel.services.filter { $0.status == status }.count
                            if count > 0 || viewModel.selectedStatus == status {
                                row(status.rawValue, icon: "circle", count: count, selected: viewModel.selectedStatus == status) {
                                    viewModel.selectedStatus = viewModel.selectedStatus == status ? nil : status
                                    viewModel.selectedAuditFilter = nil
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.bottom, 20)
            }
            Divider().padding(.horizontal, 20)
            HStack(spacing: 8) {
                Image(systemName: "internaldrive").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 3) {
                    Text("On this Mac").font(.system(size: 11, weight: .medium))
                    Text("\(viewModel.services.filter { $0.status == .active }.count) active services")
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                }
                Spacer()
                Button { viewModel.isShowingSettingsSheet = true } label: { Image(systemName: "gearshape") }
                    .buttonStyle(.plain).foregroundStyle(.secondary).help("Settings")
                    .accessibilityLabel("Settings")
            }
            .padding(20)
        }
        .background(.regularMaterial)
        .alert("New workspace", isPresented: $isShowingNewWorkspaceAlert) {
            TextField("Workspace name", text: $newWorkspaceName)
            Button("Cancel", role: .cancel) { }
            Button("Create") { viewModel.addWorkspace(newWorkspaceName) }
                .disabled(newWorkspaceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: { Text("Give this collection of services a name.") }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10).padding(.bottom, 7)
    }

    private func row(_ title: String, icon: String, count: Int, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 13)).frame(width: 17)
                    .foregroundStyle(selected ? Theme.accent : .secondary)
                Text(title).font(.system(size: 12, weight: selected ? .semibold : .regular)).lineLimit(1)
                Spacer(minLength: 4)
                Text(count, format: .number).font(.system(size: 11)).monospacedDigit()
                    .foregroundStyle(selected ? Theme.accent : .secondary)
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(selected ? Theme.selection : .clear, in: RoundedRectangle(cornerRadius: 7))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain).help(title).accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func auditRow(_ title: String, icon: String, filter: String, category: String) -> some View {
        row(title, icon: icon, count: viewModel.auditWarnings.filter { $0.category == category }.count,
            selected: viewModel.selectedAuditFilter == filter) {
            viewModel.selectedAuditFilter = filter
            viewModel.selectedWorkspace = nil
            viewModel.selectedCategory = nil
            viewModel.selectedStatus = nil
        }
    }
}
