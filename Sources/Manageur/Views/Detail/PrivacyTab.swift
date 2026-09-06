import SwiftUI

public struct PrivacyTab: View {
    @Binding var privacyInfo: PrivacyInfo
    let serviceStatus: ServiceStatus
    let onSave: () -> Void

    public init(privacyInfo: Binding<PrivacyInfo>, serviceStatus: ServiceStatus, onSave: @escaping () -> Void) {
        self._privacyInfo = privacyInfo
        self.serviceStatus = serviceStatus
        self.onSave = onSave
    }

    public var body: some View {
        Form {
            if (serviceStatus == .deprecated || serviceStatus == .needsCancellation) && (privacyInfo.gdprDeletionUrl ?? "").isEmpty {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Account Deletion Recommended")
                                .font(.subheadline.bold())
                            Text("This service is marked as \(serviceStatus.rawValue). Consider exercising GDPR/account deletion to clean up your digital footprint.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section("Data Held by Service") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Summary of data shared or stored (e.g. source code, user emails, payment records):")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    TextEditor(text: Binding(
                        get: { privacyInfo.dataStoredSummary ?? "" },
                        set: { privacyInfo.dataStoredSummary = $0.isEmpty ? nil : $0; onSave() }
                    ))
                    .frame(minHeight: 70)
                }
            }

            Section("Privacy & Compliance Links") {
                HStack {
                    TextField("GDPR / Account Deletion URL", text: Binding(
                        get: { privacyInfo.gdprDeletionUrl ?? "" },
                        set: { privacyInfo.gdprDeletionUrl = $0.isEmpty ? nil : $0; onSave() }
                    ))

                    if let urlStr = privacyInfo.gdprDeletionUrl, let url = URL(string: urlStr) {
                        Link(destination: url) {
                            Image(systemName: "arrow.up.right.square")
                        }
                    }
                }

                HStack {
                    TextField("Data Export / Takeout URL", text: Binding(
                        get: { privacyInfo.dataExportUrl ?? "" },
                        set: { privacyInfo.dataExportUrl = $0.isEmpty ? nil : $0; onSave() }
                    ))

                    if let urlStr = privacyInfo.dataExportUrl, let url = URL(string: urlStr) {
                        Link(destination: url) {
                            Image(systemName: "arrow.up.right.square")
                        }
                    }
                }

                HStack {
                    TextField("Privacy Policy URL", text: Binding(
                        get: { privacyInfo.privacyPolicyUrl ?? "" },
                        set: { privacyInfo.privacyPolicyUrl = $0.isEmpty ? nil : $0; onSave() }
                    ))

                    if let urlStr = privacyInfo.privacyPolicyUrl, let url = URL(string: urlStr) {
                        Link(destination: url) {
                            Image(systemName: "arrow.up.right.square")
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
