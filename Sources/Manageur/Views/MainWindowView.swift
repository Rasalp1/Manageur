import SwiftUI

public struct MainWindowView: View {
    @StateObject private var viewModel = InventoryViewModel()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    public init() {}

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        } content: {
            ServiceListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 400)
        } detail: {
            if let selectedId = viewModel.selectedServiceId {
                ServiceDetailView(viewModel: viewModel, serviceId: selectedId)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No Service Selected")
                        .font(.title3.bold())
                        .foregroundColor(.secondary)
                    Text("Select a service from the list or add a new one.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Add Service") {
                        viewModel.isShowingNewServiceSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { viewModel.isShowingNewServiceSheet = true }) {
                    Label("Add Service", systemImage: "plus")
                }
                .help("Add new service (Cmd+N)")
                .keyboardShortcut("n", modifiers: .command)

                Button(action: { viewModel.isShowingSettingsSheet = true }) {
                    Label("Settings", systemImage: "gearshape")
                }
                .help("Settings & Storage Directory")
            }
        }
        .sheet(isPresented: $viewModel.isShowingNewServiceSheet) {
            NewServiceSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.isShowingSettingsSheet) {
            SettingsView(viewModel: viewModel)
        }
    }
}
