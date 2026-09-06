import Foundation

public enum AuthProvider: String, Codable, CaseIterable, Identifiable, Sendable {
    case google = "Google"
    case github = "GitHub"
    case apple = "Apple ID"
    case emailPassword = "Email & Password"
    case microsoft = "Microsoft"
    case gitlab = "GitLab"
    case discord = "Discord"
    case sso = "SSO / SAML"
    case passkey = "Passkey"
    case other = "Other"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .google: return "g.circle.fill"
        case .github: return "chevron.left.forwardslash.chevron.right"
        case .apple: return "apple.logo"
        case .emailPassword: return "envelope.badge.shield.half.filled"
        case .microsoft: return "window.vertical.closed"
        case .gitlab: return "shippingbox.fill"
        case .discord: return "bubble.left.and.bubble.right.fill"
        case .sso: return "lock.shield.fill"
        case .passkey: return "person.badge.key.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

public enum TwoFactorMethod: String, Codable, CaseIterable, Identifiable, Sendable {
    case none = "None"
    case authenticatorApp = "Authenticator App (TOTP)"
    case securityKey = "Hardware Key (YubiKey / FIDO2)"
    case passkey = "Passkey"
    case sms = "SMS Verification"
    case email = "Email Code"

    public var id: String { rawValue }
}

public enum BillingCycle: String, Codable, CaseIterable, Identifiable, Sendable {
    case free = "Free"
    case monthly = "Monthly"
    case annual = "Annual"
    case payAsYouGo = "Pay-As-You-Go / Usage"
    case oneTime = "One-Time Purchase"

    public var id: String { rawValue }
}

public struct AuthenticationInfo: Codable, Hashable, Sendable {
    public var provider: AuthProvider
    public var customProviderName: String?
    public var loginEmailOrUsername: String?
    public var twoFactorMethod: TwoFactorMethod
    public var recoveryEmail: String?
    public var ssoDomain: String?

    public init(
        provider: AuthProvider = .emailPassword,
        customProviderName: String? = nil,
        loginEmailOrUsername: String? = nil,
        twoFactorMethod: TwoFactorMethod = .none,
        recoveryEmail: String? = nil,
        ssoDomain: String? = nil
    ) {
        self.provider = provider
        self.customProviderName = customProviderName
        self.loginEmailOrUsername = loginEmailOrUsername
        self.twoFactorMethod = twoFactorMethod
        self.recoveryEmail = recoveryEmail
        self.ssoDomain = ssoDomain
    }
}

public struct BillingInfo: Codable, Hashable, Sendable {
    public var isPaid: Bool
    public var tierName: String?
    public var amount: Double?
    public var currency: String
    public var billingCycle: BillingCycle
    public var nextRenewalDate: Date?
    public var paymentMethodDescription: String?
    public var cancellationUrl: String?

    public init(
        isPaid: Bool = false,
        tierName: String? = nil,
        amount: Double? = nil,
        currency: String = "USD",
        billingCycle: BillingCycle = .free,
        nextRenewalDate: Date? = nil,
        paymentMethodDescription: String? = nil,
        cancellationUrl: String? = nil
    ) {
        self.isPaid = isPaid
        self.tierName = tierName
        self.amount = amount
        self.currency = currency
        self.billingCycle = billingCycle
        self.nextRenewalDate = nextRenewalDate
        self.paymentMethodDescription = paymentMethodDescription
        self.cancellationUrl = cancellationUrl
    }

    public var formattedCost: String {
        guard isPaid, let amount = amount, amount > 0 else {
            return billingCycle == .free ? "Free" : "Unspecified"
        }
        let formattedNumber = String(format: "%.2f", amount)
        switch billingCycle {
        case .monthly:
            return "\(currency) \(formattedNumber)/mo"
        case .annual:
            return "\(currency) \(formattedNumber)/yr"
        case .payAsYouGo:
            return "\(currency) \(formattedNumber) (usage)"
        case .oneTime:
            return "\(currency) \(formattedNumber) (once)"
        case .free:
            return "Free"
        }
    }
}

public struct ContextInfo: Codable, Hashable, Sendable {
    public var linkedProjects: [String]
    public var dependencies: [String]
    public var primaryOwner: String?

    public init(
        linkedProjects: [String] = [],
        dependencies: [String] = [],
        primaryOwner: String? = nil
    ) {
        self.linkedProjects = linkedProjects
        self.dependencies = dependencies
        self.primaryOwner = primaryOwner
    }
}

public struct PrivacyInfo: Codable, Hashable, Sendable {
    public var dataStoredSummary: String?
    public var gdprDeletionUrl: String?
    public var dataExportUrl: String?
    public var privacyPolicyUrl: String?

    public init(
        dataStoredSummary: String? = nil,
        gdprDeletionUrl: String? = nil,
        dataExportUrl: String? = nil,
        privacyPolicyUrl: String? = nil
    ) {
        self.dataStoredSummary = dataStoredSummary
        self.gdprDeletionUrl = gdprDeletionUrl
        self.dataExportUrl = dataExportUrl
        self.privacyPolicyUrl = privacyPolicyUrl
    }
}

public struct ServiceItem: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var slug: String
    public var domain: String
    public var websiteURL: String?
    public var category: ServiceCategory
    public var workspace: String
    public var tags: [String]
    public var notes: String?
    public var status: ServiceStatus
    public var dateCreated: Date
    public var lastAudited: Date?

    public var authInfo: AuthenticationInfo
    public var billingInfo: BillingInfo
    public var contextInfo: ContextInfo
    public var privacyInfo: PrivacyInfo

    public init(
        id: UUID = UUID(),
        name: String,
        slug: String? = nil,
        domain: String = "",
        websiteURL: String? = nil,
        category: ServiceCategory = .other,
        workspace: String = "Personal",
        tags: [String] = [],
        notes: String? = nil,
        status: ServiceStatus = .active,
        dateCreated: Date = Date(),
        lastAudited: Date? = nil,
        authInfo: AuthenticationInfo = AuthenticationInfo(),
        billingInfo: BillingInfo = BillingInfo(),
        contextInfo: ContextInfo = ContextInfo(),
        privacyInfo: PrivacyInfo = PrivacyInfo()
    ) {
        self.id = id
        self.name = name
        self.slug = slug ?? ServiceItem.generateSlug(from: name)
        self.domain = domain
        self.websiteURL = websiteURL
        self.category = category
        self.workspace = workspace
        self.tags = tags
        self.notes = notes
        self.status = status
        self.dateCreated = dateCreated
        self.lastAudited = lastAudited
        self.authInfo = authInfo
        self.billingInfo = billingInfo
        self.contextInfo = contextInfo
        self.privacyInfo = privacyInfo
    }

    public static func generateSlug(from name: String) -> String {
        let cleaned = name.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        return cleaned.isEmpty ? "service-\(UUID().uuidString.prefix(8).lowercased())" : cleaned
    }

    public var cleanedDomain: String {
        if !domain.isEmpty {
            return domain.lowercased()
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        if let website = websiteURL, let url = URL(string: website), let host = url.host {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        return ""
    }
}
