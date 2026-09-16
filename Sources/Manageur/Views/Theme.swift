import SwiftUI

// Semantic surfaces and proportions follow the shared design system.
enum Theme {
    static let accent = Color(red: 0.22, green: 0.43, blue: 0.86)
    static let canvas = Color(nsColor: .textBackgroundColor)
    static let secondarySurface = Color.primary.opacity(0.035)
    static let subtleBorder = Color.primary.opacity(0.08)
    static let selection = accent.opacity(0.11)
    static let pageInset: CGFloat = 28
}

struct InventoryEmptyView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .light)).foregroundStyle(Theme.accent)
                .frame(width: 68, height: 68)
                .background(Theme.selection, in: RoundedRectangle(cornerRadius: 18))
                .padding(.bottom, 4).accessibilityHidden(true)
            Text(title).font(.system(size: 18, weight: .semibold))
            Text(message).font(.system(size: 13)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).lineSpacing(3).frame(maxWidth: 290)
        }
        .padding(24)
    }
}

extension View {
    func inventoryForm() -> some View {
        self.formStyle(.grouped).scrollContentBackground(.hidden)
            .font(.system(size: 13)).background(Theme.canvas).tint(Theme.accent)
    }
}
