import Foundation
import AppKit

public final class LogoCacheManager: @unchecked Sendable {
    public static let shared = LogoCacheManager()

    private let memoryCache = NSCache<NSString, NSImage>()
    private let cacheDirectory: URL
    private let fileManager = FileManager.default

    private init() {
        if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            self.cacheDirectory = cachesURL.appendingPathComponent("com.manageur.app/logos", isDirectory: true)
        } else {
            self.cacheDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ManageurLogos", isDirectory: true)
        }
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    public func getLogo(for domain: String) async -> NSImage? {
        let clean = domain.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }

        // 1. Check memory cache
        if let cached = memoryCache.object(forKey: clean as NSString) {
            return cached
        }

        // 2. Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent("\(clean).png")
        if let data = try? Data(contentsOf: fileURL), let image = NSImage(data: data) {
            memoryCache.setObject(image, forKey: clean as NSString)
            return image
        }

        // 3. Fetch from remote endpoints
        let candidateURLs = [
            URL(string: "https://www.google.com/s2/favicons?domain=\(clean)&sz=128"),
            URL(string: "https://icons.duckduckgo.com/ip3/\(clean).ico")
        ].compactMap { $0 }

        for url in candidateURLs {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                   let image = NSImage(data: data), image.isValid {
                    // Cache to disk
                    try? data.write(to: fileURL)
                    memoryCache.setObject(image, forKey: clean as NSString)
                    return image
                }
            } catch {
                continue
            }
        }

        return nil
    }
}
