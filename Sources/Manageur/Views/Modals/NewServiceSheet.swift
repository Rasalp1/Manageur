import SwiftUI

public struct NewServiceSheet: View {
    @ObservedObject var viewModel: InventoryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var domain: String = ""
    @State private var websiteURL: String = ""
    @State private var workspace: String = "Personal"
    @State private var category: ServiceCategory = .devTools
    @State private var status: ServiceStatus = .active

    // Usage & Discovery
    @State private var usageFrequency: UsageFrequency = .occasional
    @State private var signupSource: SignupSource = .other
    @State private var signupDate: Date = Date()
    @State private var hasSignupDate: Bool = false
    @State private var selectedPlatforms: [AppPlatform] = []

    // Auth
    @State private var authProvider: AuthProvider = .emailPassword
    @State private var loginEmail: String = ""
    @State private var twoFactor: TwoFactorMethod = .none

    // Billing
    @State private var isPaid: Bool = false
    @State private var tierName: String = "Pro"
    @State private var amount: Double = 0.0
    @State private var currency: String = "USD"
    @State private var billingCycle: BillingCycle = .monthly

    public init(viewModel: InventoryViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            Form {
                // MARK: General
                Section("General") {
                    TextField("Name (e.g. Figma, Homebrew, Netflix)", text: $name)

                    TextField("Domain (e.g. figma.com)", text: $domain)

                    TextField("Website or App URL (optional)", text: $websiteURL)

                    Picker("Workspace", selection: $workspace) {
                        ForEach(viewModel.availableWorkspaces, id: \.self) { ws in
                            Text(ws).tag(ws)
                        }
                    }

                    Picker("Category", selection: $category) {
                        ForEach(ServiceCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.sfSymbol).tag(cat)
                        }
                    }

                    Picker("Status", selection: $status) {
                        ForEach(ServiceStatus.allCases) { stat in
                            HStack {
                                Circle().fill(stat.color).frame(width: 8, height: 8)
                                Text(stat.rawValue)
                            }.tag(stat)
                        }
                    }
                }

                // MARK: Usage & Discovery
                Section("Usage & Discovery") {
                    Picker("Usage Frequency", selection: $usageFrequency) {
                        ForEach(UsageFrequency.allCases) { freq in
                            Label(freq.rawValue, systemImage: freq.sfSymbol).tag(freq)
                        }
                    }

                    Picker("How I Found It", selection: $signupSource) {
                        ForEach(SignupSource.allCases) { source in
                            Label(source.rawValue, systemImage: source.sfSymbol).tag(source)
                        }
                    }

                    Toggle("Record Signup Date", isOn: $hasSignupDate)

                    if hasSignupDate {
                        DatePicker("Signup Date", selection: $signupDate, displayedComponents: [.date])
                    }
                }

                // MARK: Platforms
                Section("Platforms") {
                    FlowLayout(spacing: 6) {
                        ForEach(AppPlatform.allCases) { platform in
                            let isSelected = selectedPlatforms.contains(platform)
                            Button {
                                if isSelected {
                                    selectedPlatforms.removeAll { $0 == platform }
                                } else {
                                    selectedPlatforms.append(platform)
                                }
                            } label: {
                                PlatformChipLabel(platform: platform, isSelected: isSelected)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // MARK: Authentication
                Section("Authentication") {
                    Picker("Auth Provider", selection: $authProvider) {
                        ForEach(AuthProvider.allCases) { prov in
                            Label(prov.rawValue, systemImage: prov.iconName).tag(prov)
                        }
                    }

                    TextField("Login Email or Username", text: $loginEmail)

                    Picker("2FA Method", selection: $twoFactor) {
                        ForEach(TwoFactorMethod.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                }

                // MARK: Billing (only for billing-relevant categories)
                if category.isBillingRelevant {
                    Section("Billing") {
                        Toggle("Paid Subscription", isOn: $isPaid)

                        if isPaid {
                            TextField("Tier (e.g. Pro, Team)", text: $tierName)

                            HStack {
                                TextField("Amount", value: $amount, format: .number)
                                    .frame(maxWidth: 100)

                                Picker("Currency", selection: $currency) {
                                    ForEach(["USD", "EUR", "GBP", "SEK", "CAD", "AUD"], id: \.self) { curr in
                                        Text(curr).tag(curr)
                                    }
                                }
                                .frame(width: 85)

                                Picker("Cycle", selection: $billingCycle) {
                                    ForEach(BillingCycle.allCases) { c in
                                        Text(c.rawValue).tag(c)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .inventoryForm()
            .navigationTitle("Add Service")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveNewService()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let selectedWs = viewModel.selectedWorkspace {
                    self.workspace = selectedWs
                } else if let firstWs = viewModel.availableWorkspaces.first {
                    self.workspace = firstWs
                }
                if let selectedCat = viewModel.selectedCategory {
                    self.category = selectedCat
                }
            }
        }
        .frame(minWidth: 520, minHeight: 580)
    }

    private func saveNewService() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return }

        let cleanDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanWebsite = websiteURL.trimmingCharacters(in: .whitespacesAndNewlines)

        let auth = AuthenticationInfo(
            provider: authProvider,
            loginEmailOrUsername: loginEmail.isEmpty ? nil : loginEmail,
            twoFactorMethod: twoFactor
        )

        let billing = BillingInfo(
            isPaid: isPaid && category.isBillingRelevant,
            tierName: isPaid ? tierName : nil,
            amount: isPaid && amount > 0 ? amount : nil,
            currency: currency,
            billingCycle: isPaid && category.isBillingRelevant ? billingCycle : .free
        )

        let service = ServiceItem(
            name: cleanName,
            domain: cleanDomain,
            websiteURL: cleanWebsite.isEmpty ? nil : cleanWebsite,
            category: category,
            workspace: workspace,
            status: status,
            signupDate: hasSignupDate ? signupDate : nil,
            signupSource: signupSource,
            usageFrequency: usageFrequency,
            appPlatforms: selectedPlatforms,
            authInfo: auth,
            billingInfo: billing
        )

        viewModel.createService(service)
    }
}

// MARK: - Platform Chip Label (extracted for type-checker performance)

private struct PlatformChipLabel: View {
    let platform: AppPlatform
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: platform.sfSymbol).font(.system(size: 10))
            Text(platform.rawValue).font(.system(size: 11))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            isSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
    }
}

