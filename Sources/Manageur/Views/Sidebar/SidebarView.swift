import SwiftUI

public struct SidebarView: View {
    @ObservedObject var viewModel: InventoryViewModel
    @State private var isShowingNewWorkspaceAlert: Bool = false
    @State private var newWorkspaceName: String = ""

    public init(viewModel: InventoryViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        List {
            // MARK: - Workspaces
            Section(header: HStack {
                Text("Workspaces")
                Spacer()
                Button(action: {
                    newWorkspaceName = ""
                    isShowingNewWorkspaceAlert = true
                }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .help("Add new workspace")
            }) {
                Button(action: {
                    viewModel.selectedWorkspace = nil
                    viewModel.selectedAuditFilter = nil
                }) {
                    HStack {
                        Image(systemName: "tray.2.fill")
                            .foregroundColor(.accentColor)
                        Text("All Workspaces")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(viewModel.services.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(viewModel.selectedWorkspace == nil && viewModel.selectedAuditFilter == nil ? Color.accentColor.opacity(0.15) : Color.clear)

                ForEach(viewModel.availableWorkspaces, id: \.self) { ws in
                    let count = viewModel.services.filter { $0.workspace.caseInsensitiveCompare(ws) == .orderedSame }.count
                    Button(action: {
                        viewModel.selectedWorkspace = ws
                        viewModel.selectedAuditFilter = nil
                    }) {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                            Text(ws)
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(viewModel.selectedWorkspace == ws && viewModel.selectedAuditFilter == nil ? Color.accentColor.opacity(0.15) : Color.clear)
                }
            }

            // MARK: - Audit & Health
            Section(header: Text("Audit & Health")) {
                let trialCount = viewModel.auditWarnings.filter { $0.category == "Trial" }.count
                let secCount = viewModel.auditWarnings.filter { $0.category == "Security" }.count
                let privCount = viewModel.auditWarnings.filter { $0.category == "Privacy" }.count
                let dupCount = viewModel.auditWarnings.filter { $0.category == "Duplicate" }.count

                Button(action: {
                    viewModel.selectedAuditFilter = "expiring-trials"
                    viewModel.selectedWorkspace = nil
                    viewModel.selectedCategory = nil
                    viewModel.selectedStatus = nil
                }) {
                    HStack {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundColor(.orange)
                        Text("Expiring Trials")
                            .foregroundColor(.primary)
                        Spacer()
                        if trialCount > 0 {
                            BadgeView(count: trialCount, color: .orange)
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(viewModel.selectedAuditFilter == "expiring-trials" ? Color.accentColor.opacity(0.15) : Color.clear)

                Button(action: {
                    viewModel.selectedAuditFilter = "missing-2fa"
                    viewModel.selectedWorkspace = nil
                    viewModel.selectedCategory = nil
                    viewModel.selectedStatus = nil
                }) {
                    HStack {
                        Image(systemName: "shield.slash.fill")
                            .foregroundColor(.red)
                        Text("Missing 2FA")
                            .foregroundColor(.primary)
                        Spacer()
                        if secCount > 0 {
                            BadgeView(count: secCount, color: .red)
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(viewModel.selectedAuditFilter == "missing-2fa" ? Color.accentColor.opacity(0.15) : Color.clear)

                Button(action: {
                    viewModel.selectedAuditFilter = "missing-gdpr"
                    viewModel.selectedWorkspace = nil
                    viewModel.selectedCategory = nil
                    viewModel.selectedStatus = nil
                }) {
                    HStack {
                        Image(systemName: "trash.slash.fill")
                            .foregroundColor(.secondary)
                        Text("Missing GDPR / Deletion")
                            .foregroundColor(.primary)
                        Spacer()
                        if privCount > 0 {
                            BadgeView(count: privCount, color: .secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(viewModel.selectedAuditFilter == "missing-gdpr" ? Color.accentColor.opacity(0.15) : Color.clear)

                Button(action: {
                    viewModel.selectedAuditFilter = "duplicates"
                    viewModel.selectedWorkspace = nil
                    viewModel.selectedCategory = nil
                    viewModel.selectedStatus = nil
                }) {
                    HStack {
                        Image(systemName: "square.on.square")
                            .foregroundColor(.purple)
                        Text("Category Overlaps")
                            .foregroundColor(.primary)
                        Spacer()
                        if dupCount > 0 {
                            BadgeView(count: dupCount, color: .purple)
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(viewModel.selectedAuditFilter == "duplicates" ? Color.accentColor.opacity(0.15) : Color.clear)
            }

            // MARK: - Categories
            Section(header: HStack {
                Text("Categories")
                Spacer()
                if viewModel.selectedCategory != nil {
                    Button("Clear") { viewModel.selectedCategory = nil }
                        .font(.caption2)
                        .buttonStyle(.plain)
                }
            }) {
                ForEach(ServiceCategory.allCases) { cat in
                    let count = viewModel.services.filter { $0.category == cat }.count
                    if count > 0 || viewModel.selectedCategory == cat {
                        Button(action: {
                            if viewModel.selectedCategory == cat {
                                viewModel.selectedCategory = nil
                            } else {
                                viewModel.selectedCategory = cat
                                viewModel.selectedAuditFilter = nil
                            }
                        }) {
                            HStack {
                                Image(systemName: cat.sfSymbol)
                                    .frame(width: 18)
                                    .foregroundColor(.secondary)
                                Text(cat.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(viewModel.selectedCategory == cat ? Color.accentColor.opacity(0.15) : Color.clear)
                    }
                }
            }

            // MARK: - Statuses
            Section(header: HStack {
                Text("Status")
                Spacer()
                if viewModel.selectedStatus != nil {
                    Button("Clear") { viewModel.selectedStatus = nil }
                        .font(.caption2)
                        .buttonStyle(.plain)
                }
            }) {
                ForEach(ServiceStatus.allCases) { stat in
                    let count = viewModel.services.filter { $0.status == stat }.count
                    if count > 0 || viewModel.selectedStatus == stat {
                        Button(action: {
                            if viewModel.selectedStatus == stat {
                                viewModel.selectedStatus = nil
                            } else {
                                viewModel.selectedStatus = stat
                                viewModel.selectedAuditFilter = nil
                            }
                        }) {
                            HStack {
                                Circle()
                                    .fill(stat.color)
                                    .frame(width: 8, height: 8)
                                Text(stat.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("\(count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(viewModel.selectedStatus == stat ? Color.accentColor.opacity(0.15) : Color.clear)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .alert("New Workspace", isPresented: $isShowingNewWorkspaceAlert) {
            TextField("Workspace name (e.g. Clients)", text: $newWorkspaceName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                viewModel.addWorkspace(newWorkspaceName)
            }
        } message: {
            Text("Enter the name of the new workspace. A folder will be created on disk.")
        }
    }
}

private struct BadgeView: View {
    let count: Int
    let color: Color

    var body: some View {
        Text("\(count)")
            .font(.caption2.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color)
            .clipShape(Capsule())
    }
}
