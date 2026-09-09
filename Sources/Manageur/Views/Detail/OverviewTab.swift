import SwiftUI

public struct OverviewTab: View {
    @Binding var service: ServiceItem
    let workspaces: [String]
    let onSave: () -> Void

    @State private var newTag: String = ""

    public init(service: Binding<ServiceItem>, workspaces: [String], onSave: @escaping () -> Void) {
        self._service = service
        self.workspaces = workspaces
        self.onSave = onSave
    }

    public var body: some View {
        Form {

            // MARK: Basic Information
            Section("Basic Information") {
                TextField("Service Name", text: $service.name)
                    .onChange(of: service.name) { _, _ in onSave() }

                HStack {
                    TextField("Domain (e.g. stripe.com)", text: $service.domain)
                        .onChange(of: service.domain) { _, _ in onSave() }
                    if !service.cleanedDomain.isEmpty {
                        Link(destination: URL(string: "https://\(service.cleanedDomain)") ?? URL(string: "https://google.com")!) {
                            Image(systemName: "arrow.up.right.square")
                        }
                    }
                }

                TextField("Website / App URL", text: Binding(
                    get: { service.websiteURL ?? "" },
                    set: { service.websiteURL = $0.isEmpty ? nil : $0; onSave() }
                ))

                Picker("Workspace", selection: $service.workspace) {
                    ForEach(workspaces, id: \.self) { ws in
                        Text(ws).tag(ws)
                    }
                }
                .onChange(of: service.workspace) { _, _ in onSave() }

                Picker("Category", selection: $service.category) {
                    ForEach(ServiceCategory.allCases) { cat in
                        Label(cat.rawValue, systemImage: cat.sfSymbol).tag(cat)
                    }
                }
                .onChange(of: service.category) { _, _ in onSave() }

                Picker("Status", selection: $service.status) {
                    ForEach(ServiceStatus.allCases) { stat in
                        HStack {
                            Circle().fill(stat.color).frame(width: 8, height: 8)
                            Text(stat.rawValue)
                        }.tag(stat)
                    }
                }
                .onChange(of: service.status) { _, _ in onSave() }
            }

            // MARK: Usage & Discovery
            Section("Usage & Discovery") {
                Picker("Usage Frequency", selection: $service.usageFrequency) {
                    ForEach(UsageFrequency.allCases) { freq in
                        Label(freq.rawValue, systemImage: freq.sfSymbol).tag(freq)
                    }
                }
                .onChange(of: service.usageFrequency) { _, _ in onSave() }

                Picker("Signup Source", selection: $service.signupSource) {
                    ForEach(SignupSource.allCases) { source in
                        Label(source.rawValue, systemImage: source.sfSymbol).tag(source)
                    }
                }
                .onChange(of: service.signupSource) { _, _ in onSave() }

                // Signup date
                Toggle("Record Signup Date", isOn: Binding(
                    get: { service.signupDate != nil },
                    set: { enabled in
                        service.signupDate = enabled ? Date() : nil
                        onSave()
                    }
                ))

                if let signupDate = service.signupDate {
                    DatePicker("Signup Date", selection: Binding(
                        get: { signupDate },
                        set: { service.signupDate = $0; onSave() }
                    ), displayedComponents: [.date])
                }
            }

            // MARK: Platforms
            Section("Platforms") {
                if service.appPlatforms.isEmpty {
                    Text("No platforms selected — tap to add")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                }

                FlowLayout(spacing: 6) {
                    ForEach(AppPlatform.allCases) { platform in
                        let isSelected = service.appPlatforms.contains(platform)
                        Button {
                            if isSelected {
                                service.appPlatforms.removeAll { $0 == platform }
                            } else {
                                service.appPlatforms.append(platform)
                            }
                            onSave()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: platform.sfSymbol)
                                    .font(.system(size: 10))
                                Text(platform.rawValue)
                                    .font(.system(size: 11))
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(
                                isSelected ? Theme.accent.opacity(0.18) : Color.secondary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Theme.accent.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                            .foregroundStyle(isSelected ? Theme.accent : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: Licence Key Hint (only for one-time purchases)
            if service.billingInfo.billingCycle == .oneTime || !service.category.isBillingRelevant {
                Section("Licence Reference") {
                    TextField("Licence key hint (e.g. 'See 1Password › Setapp')", text: Binding(
                        get: { service.licenceKeyHint ?? "" },
                        set: { service.licenceKeyHint = $0.isEmpty ? nil : $0; onSave() }
                    ))

                    if service.licenceKeyHint != nil {
                        Label("Store the actual key in a password manager, not here.", systemImage: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // MARK: Tags
            Section("Tags") {
                HStack {
                    TextField("Add tag...", text: $newTag)
                        .onSubmit { addTag() }
                    Button("Add") { addTag() }
                        .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if !service.tags.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(service.tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.caption)
                                Button(action: { removeTag(tag) }) {
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // MARK: Notes
            Section("Notes & Description") {
                TextEditor(text: Binding(
                    get: { service.notes ?? "" },
                    set: { service.notes = $0.isEmpty ? nil : $0; onSave() }
                ))
                .font(.body)
                .frame(minHeight: 80)
            }

            // MARK: Metadata
            Section("Record Auditing & Metadata") {
                LabeledContent("Date Added to Manageur") {
                    Text(service.dateCreated.formatted(date: .abbreviated, time: .shortened))
                        .foregroundColor(.secondary)
                }

                LabeledContent("Last Audited") {
                    HStack {
                        if let audited = service.lastAudited {
                            Text(audited.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.secondary)
                        } else {
                            Text("Never")
                                .foregroundColor(.orange)
                        }

                        Button("Audit Now") {
                            service.lastAudited = Date()
                            onSave()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                LabeledContent("Filename on disk") {
                    Text("\(service.slug).json")
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                }
            }
        }
        .inventoryForm()
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !service.tags.contains(trimmed) {
            service.tags.append(trimmed)
            onSave()
        }
        newTag = ""
    }

    private func removeTag(_ tag: String) {
        service.tags.removeAll { $0 == tag }
        onSave()
    }
}

// Simple Flow layout for tags and platform chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeightInRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            maxHeightInRow = max(maxHeightInRow, size.height)
            x += size.width + spacing
        }
        height = y + maxHeightInRow
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeightInRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            maxHeightInRow = max(maxHeightInRow, size.height)
            x += size.width + spacing
        }
    }
}
