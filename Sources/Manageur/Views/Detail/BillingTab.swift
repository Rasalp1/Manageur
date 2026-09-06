import SwiftUI

public struct BillingTab: View {
    @Binding var billingInfo: BillingInfo
    let onSave: () -> Void

    @State private var hasRenewalDate: Bool = false

    public init(billingInfo: Binding<BillingInfo>, onSave: @escaping () -> Void) {
        self._billingInfo = billingInfo
        self.onSave = onSave
    }

    public var body: some View {
        Form {
            Section("Subscription & Cost") {
                Toggle("Paid Service", isOn: $billingInfo.isPaid)
                    .onChange(of: billingInfo.isPaid) { _, newValue in
                        if !newValue {
                            billingInfo.billingCycle = .free
                        } else if billingInfo.billingCycle == .free {
                            billingInfo.billingCycle = .monthly
                        }
                        onSave()
                    }

                if billingInfo.isPaid {
                    TextField("Plan Tier (e.g. Pro, Team, Business)", text: Binding(
                        get: { billingInfo.tierName ?? "" },
                        set: { billingInfo.tierName = $0.isEmpty ? nil : $0; onSave() }
                    ))

                    HStack {
                        TextField("Amount", value: Binding(
                            get: { billingInfo.amount ?? 0.0 },
                            set: { billingInfo.amount = $0 > 0 ? $0 : nil; onSave() }
                        ), format: .number)
                        .frame(maxWidth: 120)

                        Picker("Currency", selection: $billingInfo.currency) {
                            ForEach(["USD", "EUR", "GBP", "SEK", "CAD", "AUD", "CHF"], id: \.self) { curr in
                                Text(curr).tag(curr)
                            }
                        }
                        .frame(width: 90)
                    }

                    Picker("Billing Cycle", selection: $billingInfo.billingCycle) {
                        ForEach(BillingCycle.allCases) { cycle in
                            Text(cycle.rawValue).tag(cycle)
                        }
                    }
                    .onChange(of: billingInfo.billingCycle) { _, _ in onSave() }
                }
            }

            if billingInfo.isPaid {
                Section("Renewal & Payment Details") {
                    Toggle("Has Fixed Renewal Date", isOn: Binding(
                        get: { billingInfo.nextRenewalDate != nil },
                        set: { enabled in
                            if enabled {
                                billingInfo.nextRenewalDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
                            } else {
                                billingInfo.nextRenewalDate = nil
                            }
                            onSave()
                        }
                    ))

                    if let renewalDate = billingInfo.nextRenewalDate {
                        DatePicker("Next Renewal Date", selection: Binding(
                            get: { renewalDate },
                            set: { billingInfo.nextRenewalDate = $0; onSave() }
                        ), displayedComponents: [.date])
                    }

                    TextField("Payment Method (e.g. Apple Pay, Visa *1234)", text: Binding(
                        get: { billingInfo.paymentMethodDescription ?? "" },
                        set: { billingInfo.paymentMethodDescription = $0.isEmpty ? nil : $0; onSave() }
                    ))

                    HStack {
                        TextField("Cancellation / Billing URL", text: Binding(
                            get: { billingInfo.cancellationUrl ?? "" },
                            set: { billingInfo.cancellationUrl = $0.isEmpty ? nil : $0; onSave() }
                        ))

                        if let urlStr = billingInfo.cancellationUrl, let url = URL(string: urlStr) {
                            Link(destination: url) {
                                Image(systemName: "arrow.up.right.square")
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
