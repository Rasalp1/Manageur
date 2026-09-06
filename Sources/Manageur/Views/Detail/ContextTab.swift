import SwiftUI

public struct ContextTab: View {
    @Binding var contextInfo: ContextInfo
    let onSave: () -> Void

    @State private var newProject: String = ""
    @State private var newDependency: String = ""

    public init(contextInfo: Binding<ContextInfo>, onSave: @escaping () -> Void) {
        self._contextInfo = contextInfo
        self.onSave = onSave
    }

    public var body: some View {
        Form {
            Section("Linked Projects & Repositories") {
                HStack {
                    TextField("Project / Repo name (e.g. Manageur, iOS-App)", text: $newProject)
                        .onSubmit { addProject() }
                    Button("Add") { addProject() }
                        .disabled(newProject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if contextInfo.linkedProjects.isEmpty {
                    Text("No projects linked yet. Add projects or repos that rely on this service.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(contextInfo.linkedProjects, id: \.self) { proj in
                        HStack {
                            Image(systemName: "cube.box.fill")
                                .foregroundColor(.accentColor)
                            Text(proj)
                            Spacer()
                            Button(action: { removeProject(proj) }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Section("Connectors & Integrations") {
                HStack {
                    TextField("Integration (e.g. Stripe Webhook, Slack bot)", text: $newDependency)
                        .onSubmit { addDependency() }
                    Button("Add") { addDependency() }
                        .disabled(newDependency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if contextInfo.dependencies.isEmpty {
                    Text("No external connectors or integrations recorded.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(contextInfo.dependencies, id: \.self) { dep in
                        HStack {
                            Image(systemName: "arrow.triangle.branch")
                                .foregroundColor(.purple)
                            Text(dep)
                            Spacer()
                            Button(action: { removeDependency(dep) }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Section("Ownership") {
                TextField("Primary Owner / Responsible Person", text: Binding(
                    get: { contextInfo.primaryOwner ?? "" },
                    set: { contextInfo.primaryOwner = $0.isEmpty ? nil : $0; onSave() }
                ))
            }
        }
        .formStyle(.grouped)
    }

    private func addProject() {
        let trimmed = newProject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !contextInfo.linkedProjects.contains(trimmed) {
            contextInfo.linkedProjects.append(trimmed)
            onSave()
        }
        newProject = ""
    }

    private func removeProject(_ project: String) {
        contextInfo.linkedProjects.removeAll { $0 == project }
        onSave()
    }

    private func addDependency() {
        let trimmed = newDependency.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !contextInfo.dependencies.contains(trimmed) {
            contextInfo.dependencies.append(trimmed)
            onSave()
        }
        newDependency = ""
    }

    private func removeDependency(_ dep: String) {
        contextInfo.dependencies.removeAll { $0 == dep }
        onSave()
    }
}
