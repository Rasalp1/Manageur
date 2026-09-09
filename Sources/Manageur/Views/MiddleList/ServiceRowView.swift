import SwiftUI

public struct ServiceRowView: View {
    public let service: ServiceItem

    public init(service: ServiceItem) {
        self.service = service
    }

    public var body: some View {
        HStack(spacing: 12) {
            ServiceLogoView(
                domain: service.cleanedDomain,
                category: service.category,
                size: 34
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(service.name)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)

                    Circle()
                        .fill(service.status.color)
                        .frame(width: 7, height: 7)
                        .help("Status: \(service.status.rawValue)")
                }

                HStack(spacing: 6) {
                    if !service.cleanedDomain.isEmpty {
                        Text(service.cleanedDomain)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 5) {
                    Text(service.category.rawValue)
                        .font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)

                    // Platform icons (up to 3 shown inline)
                    if !service.appPlatforms.isEmpty {
                        Text("·").font(.system(size: 10)).foregroundStyle(.secondary)
                        ForEach(service.appPlatforms.prefix(3)) { platform in
                            Image(systemName: platform.sfSymbol)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .help(platform.rawValue)
                        }
                        if service.appPlatforms.count > 3 {
                            Text("+\(service.appPlatforms.count - 3)")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 3) {
                // Cost or usage frequency indicator
                if service.category.isBillingRelevant && service.billingInfo.isPaid {
                    Text(service.billingInfo.formattedCost)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                } else {
                    // Usage frequency badge instead of cost
                    Image(systemName: service.usageFrequency.sfSymbol)
                        .font(.system(size: 10))
                        .foregroundStyle(service.usageFrequency.color)
                        .help("Usage: \(service.usageFrequency.rawValue)")
                }

                HStack(spacing: 4) {
                    Image(systemName: service.authInfo.provider.iconName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .help("Auth: \(service.authInfo.provider.rawValue)")

                    if service.authInfo.twoFactorMethod != .none {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .help("2FA Enabled: \(service.authInfo.twoFactorMethod.rawValue)")
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityValue("\(service.status.rawValue), \(service.usageFrequency.rawValue)")
    }
}
