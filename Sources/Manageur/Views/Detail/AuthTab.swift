import SwiftUI

public struct AuthTab: View {
    @Binding var authInfo: AuthenticationInfo
    let onSave: () -> Void

    public init(authInfo: Binding<AuthenticationInfo>, onSave: @escaping () -> Void) {
        self._authInfo = authInfo
        self.onSave = onSave
    }

    public var body: some View {
        Form {
            Section("Sign-In Method") {
                Picker("Auth Provider", selection: $authInfo.provider) {
                    ForEach(AuthProvider.allCases) { provider in
                        Label(provider.rawValue, systemImage: provider.iconName).tag(provider)
                    }
                }
                .onChange(of: authInfo.provider) { _, _ in onSave() }

                if authInfo.provider == .other || authInfo.provider == .sso {
                    TextField("Custom Provider / Identity Provider Name", text: Binding(
                        get: { authInfo.customProviderName ?? "" },
                        set: { authInfo.customProviderName = $0.isEmpty ? nil : $0; onSave() }
                    ))
                }

                TextField("Login Email or Username", text: Binding(
                    get: { authInfo.loginEmailOrUsername ?? "" },
                    set: { authInfo.loginEmailOrUsername = $0.isEmpty ? nil : $0; onSave() }
                ))

                if authInfo.provider == .sso {
                    TextField("SSO Domain or Tenant ID", text: Binding(
                        get: { authInfo.ssoDomain ?? "" },
                        set: { authInfo.ssoDomain = $0.isEmpty ? nil : $0; onSave() }
                    ))
                }
            }

            Section("Two-Factor Authentication (2FA) & Security") {
                Picker("2FA Method", selection: $authInfo.twoFactorMethod) {
                    ForEach(TwoFactorMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .onChange(of: authInfo.twoFactorMethod) { _, _ in onSave() }

                if authInfo.twoFactorMethod == .none {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("No 2FA protection configured. Highly recommended to enable 2FA on primary digital accounts.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Text("Protected with \(authInfo.twoFactorMethod.rawValue).")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }

                TextField("Recovery Email / Backup Contact", text: Binding(
                    get: { authInfo.recoveryEmail ?? "" },
                    set: { authInfo.recoveryEmail = $0.isEmpty ? nil : $0; onSave() }
                ))
            }
        }
        .formStyle(.grouped)
    }
}
