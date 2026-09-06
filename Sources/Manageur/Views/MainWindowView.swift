import SwiftUI

public struct MainWindowView: View {
    @StateObject private var viewModel = InventoryViewModel()
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    public init() {}

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 205, ideal: 225, max: 280)
        } content: {
            ServiceListView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 290, ideal: 340, max: 440)
        } detail: {
            if let selectedId = viewModel.selectedServiceId {
                ServiceDetailView(viewModel: viewModel, serviceId: selectedId)
            } else {
                VStack(spacing: 0) {
                    InventoryEmptyView(icon: "square.stack.3d.up", title: "A place for every service",
                        message: "Select a service to explore its account, subscription, projects, and privacy details.")
                    Button("Add Service") {
                        viewModel.isShowingNewServiceSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.canvas)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .navigationTitle("Manageur")
        .tint(Theme.accent)
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
