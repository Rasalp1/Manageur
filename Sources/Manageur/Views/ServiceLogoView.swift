import SwiftUI
import AppKit

public struct ServiceLogoView: View {
    public let domain: String
    public let category: ServiceCategory
    public var size: CGFloat = 28

    @State private var loadedImage: NSImage? = nil
    @State private var isLoading: Bool = false

    public init(domain: String, category: ServiceCategory, size: CGFloat = 28) {
        self.domain = domain
        self.category = category
        self.size = size
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .fill(Theme.accent.opacity(0.085))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                        .stroke(Theme.subtleBorder, lineWidth: 1)
                )

            if let image = loadedImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 0.75, height: size * 0.75)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.15, style: .continuous))
            } else {
                Image(systemName: category.sfSymbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.5, height: size * 0.5)
                    .foregroundColor(Theme.accent)
            }
        }
        .frame(width: size, height: size)
        .task(id: domain) {
            await fetchLogo()
        }
    }

    private func fetchLogo() async {
        let clean = domain.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            loadedImage = nil
            return
        }
        let image = await LogoCacheManager.shared.getLogo(for: clean)
        await MainActor.run {
            self.loadedImage = image
        }
    }
}
