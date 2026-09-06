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
                Section("General") {
                    TextField("Service Name (e.g. Stripe, AWS, Figma)", text: $name)

                    TextField("Domain (e.g. stripe.com, figma.com)", text: $domain)

                    TextField("Website URL (optional)", text: $websiteURL)

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
            .inventoryForm()
            .navigationTitle("New Service")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Service") {
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
        .frame(minWidth: 480, minHeight: 520)
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
            isPaid: isPaid,
            tierName: isPaid ? tierName : nil,
            amount: isPaid && amount > 0 ? amount : nil,
            currency: currency,
            billingCycle: isPaid ? billingCycle : .free
        )

        let service = ServiceItem(
            name: cleanName,
            domain: cleanDomain,
            websiteURL: cleanWebsite.isEmpty ? nil : cleanWebsite,
            category: category,
            workspace: workspace,
            status: status,
            authInfo: auth,
            billingInfo: billing
        )

        viewModel.createService(service)
    }
}
