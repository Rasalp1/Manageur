import SwiftUI
import AppKit

@main
struct ManageurApp: App {
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Restore transparent silhouette for Dock tile
        let iconUrl = Bundle.main.url(forResource: "AppIcon", withExtension: "png")
            ?? Bundle.main.resourceURL?.appendingPathComponent("AppIcon.png")
            ?? Bundle.module.url(forResource: "AppIcon", withExtension: "png")
        if let iconUrl = iconUrl, let iconImg = NSImage(contentsOf: iconUrl) {
            NSApplication.shared.applicationIconImage = iconImg
        }
        
        seedSampleDataIfEmpty()
    }

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .frame(minWidth: 850, minHeight: 520)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()
        }
    }

    private func seedSampleDataIfEmpty() {
        let storage = ServiceStorageManager.shared
        let existing = storage.loadAllServices()
        guard existing.isEmpty else { return }

        // Seed a sample Developer service
        let github = ServiceItem(
            name: "GitHub",
            slug: "github",
            domain: "github.com",
            websiteURL: "https://github.com",
            category: .devTools,
            workspace: "Work",
            tags: ["code", "git", "ci-cd"],
            notes: "Primary version control and CI/CD hosting.",
            status: .active,
            authInfo: AuthenticationInfo(
                provider: .github,
                loginEmailOrUsername: "user@example.com",
                twoFactorMethod: .securityKey,
                recoveryEmail: "backup@example.com"
            ),
            billingInfo: BillingInfo(
                isPaid: true,
                tierName: "GitHub Team",
                amount: 4.00,
                currency: "USD",
                billingCycle: .monthly,
                nextRenewalDate: Calendar.current.date(byAdding: .day, value: 24, to: Date()),
                paymentMethodDescription: "Company Mastercard *8812"
            ),
            contextInfo: ContextInfo(
                linkedProjects: ["Manageur", "Infrastructure", "Personal-Blog"],
                dependencies: ["GitHub Actions", "OAuth App for Auth"],
                primaryOwner: "Lead Dev"
            ),
            privacyInfo: PrivacyInfo(
                dataStoredSummary: "Source code repositories, pull requests, deploy keys.",
                gdprDeletionUrl: "https://github.com/settings/admin",
                dataExportUrl: "https://github.com/settings/security",
                privacyPolicyUrl: "https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement"
            )
        )

        // Seed a sample AI service in Trial
        let openAI = ServiceItem(
            name: "OpenAI",
            slug: "openai",
            domain: "openai.com",
            websiteURL: "https://platform.openai.com",
            category: .aiAndModels,
            workspace: "Personal",
            tags: ["ai", "llm", "api"],
            notes: "Developer API keys for GPT-4 and reasoning models.",
            status: .trial,
            authInfo: AuthenticationInfo(
                provider: .google,
                loginEmailOrUsername: "user@gmail.com",
                twoFactorMethod: .authenticatorApp,
                recoveryEmail: "recovery@gmail.com"
            ),
            billingInfo: BillingInfo(
                isPaid: true,
                tierName: "Usage Tier 2",
                amount: 20.00,
                currency: "USD",
                billingCycle: .payAsYouGo,
                nextRenewalDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
                paymentMethodDescription: "Personal Visa *4242"
            ),
            contextInfo: ContextInfo(
                linkedProjects: ["Manageur", "Agent-Experiments"],
                dependencies: ["OpenAI API key in .env"]
            ),
            privacyInfo: PrivacyInfo(
                dataStoredSummary: "API prompt logs, user prompts, fine-tuning datasets.",
                gdprDeletionUrl: "https://privacy.openai.com",
                dataExportUrl: "https://privacy.openai.com",
                privacyPolicyUrl: "https://openai.com/policies/privacy-policy"
            )
        )

        try? storage.save(service: github)
        try? storage.save(service: openAI)
    }
}
