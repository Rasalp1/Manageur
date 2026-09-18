import XCTest
@testable import Manageur

final class ManageurTests: XCTestCase {
    func testServiceItemJSONSerialization() throws {
        let original = ServiceItem(
            name: "Cloudflare",
            slug: "cloudflare",
            domain: "cloudflare.com",
            websiteURL: "https://dash.cloudflare.com",
            category: .cloudAndInfra,
            workspace: "Personal",
            tags: ["dns", "cdn", "security"],
            notes: "Primary DNS and edge routing.",
            status: .active,
            authInfo: AuthenticationInfo(
                provider: .emailPassword,
                loginEmailOrUsername: "admin@example.com",
                twoFactorMethod: .securityKey,
                recoveryEmail: "recovery@example.com"
            ),
            billingInfo: BillingInfo(
                isPaid: false,
                billingCycle: .free
            ),
            contextInfo: ContextInfo(
                linkedProjects: ["Personal-Site"],
                dependencies: ["Cloudflare Workers"]
            ),
            privacyInfo: PrivacyInfo(
                dataStoredSummary: "DNS records and edge cache logs.",
                gdprDeletionUrl: "https://support.cloudflare.com",
                dataExportUrl: nil
            )
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(original)
        XCTAssertFalse(data.isEmpty)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let decoded = try decoder.decode(ServiceItem.self, from: data)
        XCTAssertEqual(decoded.name, "Cloudflare")
        XCTAssertEqual(decoded.domain, "cloudflare.com")
        XCTAssertEqual(decoded.cleanedDomain, "cloudflare.com")
        XCTAssertEqual(decoded.authInfo.provider, .emailPassword)
        XCTAssertEqual(decoded.authInfo.twoFactorMethod, .securityKey)
        XCTAssertEqual(decoded.billingInfo.isPaid, false)
        XCTAssertEqual(decoded.billingInfo.formattedCost, "Free")
        XCTAssertEqual(decoded.contextInfo.linkedProjects, ["Personal-Site"])
    }

    func testSlugGeneration() {
        XCTAssertEqual(ServiceItem.generateSlug(from: "Google Cloud Platform"), "google-cloud-platform")
        XCTAssertEqual(ServiceItem.generateSlug(from: "Stripe API & Billing"), "stripe-api-billing")
        XCTAssertEqual(ServiceItem.generateSlug(from: "  Vercel.com  "), "vercel-com")
    }

    func testStoragePathComponentsRejectTraversal() {
        XCTAssertTrue(ServiceStorageManager.isSafePathComponent("Side Projects"))
        XCTAssertFalse(ServiceStorageManager.isSafePathComponent("../outside"))
        XCTAssertFalse(ServiceStorageManager.isSafePathComponent("nested/name"))
        XCTAssertFalse(ServiceStorageManager.isSafePathComponent(".."))
    }

    @MainActor
    func testAuditWarningsEngine() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storage = ServiceStorageManager.shared
        storage.setRootDirectory(tempDir)

        let viewModel = InventoryViewModel(storage: storage)

        // 1. Service with missing 2FA in critical category
        let aws = ServiceItem(
            name: "AWS",
            category: .cloudAndInfra,
            workspace: "Work",
            status: .active,
            authInfo: AuthenticationInfo(provider: .emailPassword, twoFactorMethod: .none),
            billingInfo: BillingInfo(isPaid: true, amount: 50, billingCycle: .monthly)
        )

        // 2. Service in trial expiring in 3 days
        let calendar = Calendar.current
        let expiringTrial = ServiceItem(
            name: "Figma",
            category: .designAndMedia,
            workspace: "Work",
            status: .trial,
            billingInfo: BillingInfo(
                isPaid: true,
                amount: 15,
                billingCycle: .monthly,
                nextRenewalDate: calendar.date(byAdding: .day, value: 3, to: Date())
            )
        )

        // 3. Deprecated service without GDPR deletion link
        let deprecatedService = ServiceItem(
            name: "OldService",
            category: .communication,
            workspace: "Personal",
            status: .deprecated,
            privacyInfo: PrivacyInfo(gdprDeletionUrl: nil)
        )

        // 4. Duplicate services in the same workspace & category
        let gcp = ServiceItem(
            name: "Google Cloud",
            category: .cloudAndInfra,
            workspace: "Work",
            status: .active
        )

        viewModel.createService(aws)
        viewModel.createService(expiringTrial)
        viewModel.createService(deprecatedService)
        viewModel.createService(gcp)

        viewModel.runAuditEngine()

        let warnings = viewModel.auditWarnings

        // Verify missing 2FA warning
        XCTAssertTrue(warnings.contains { $0.category == "Security" && $0.serviceName == "AWS" })

        // Verify expiring trial warning
        XCTAssertTrue(warnings.contains { $0.category == "Trial" && $0.serviceName == "Figma" })

        // Verify missing GDPR link warning
        XCTAssertTrue(warnings.contains { $0.category == "Privacy" && $0.serviceName == "OldService" })

        // Verify duplicate category warning for Cloud & Infra in Work
        XCTAssertTrue(warnings.contains { $0.category == "Duplicate" && $0.workspace == "Work" })
    }
}
