import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var viewModel: InventoryViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: InventoryViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Data Storage Location") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Manageur stores every service as an individual, formatted JSON file organized by workspace folder. You can place this directory inside a Git repository or local sync folder.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            Text(ServiceStorageManager.shared.rootDirectory.path)
                                .font(.caption.monospaced())
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                                .lineLimit(2)
                            Spacer()
                        }
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(6)

                        HStack {
                            Button("Choose New Folder...") {
                                chooseStorageFolder()
                            }

                            Button("Open in Finder") {
                                NSWorkspace.shared.open(ServiceStorageManager.shared.rootDirectory)
                            }
                        }
                        .padding(.top, 4)
                    }
                }

                Section("Inventory Statistics") {
                    LabeledContent("Total Services Tracked") {
                        Text("\(viewModel.services.count)")
                            .bold()
                    }

                    LabeledContent("Workspaces") {
                        Text("\(viewModel.availableWorkspaces.count)")
                    }

                    LabeledContent("Active Audit Warnings") {
                        Text("\(viewModel.auditWarnings.count)")
                            .foregroundColor(viewModel.auditWarnings.isEmpty ? .green : .orange)
                            .bold()
                    }
                }

                Section("About Manageur") {
                    Text("Manageur is a native macOS service inventory and digital footprint tracker.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Version 1.0.0")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Manageur Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 380)
    }

    private func chooseStorageFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true
        openPanel.prompt = "Select Storage Folder"

        if openPanel.runModal() == .OK, let selectedURL = openPanel.url {
            ServiceStorageManager.shared.setRootDirectory(selectedURL)
            viewModel.loadData()
        }
    }
}
