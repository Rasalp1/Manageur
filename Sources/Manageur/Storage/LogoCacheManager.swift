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

    private static func normalizedDomain(_ value: String) -> String? {
        let candidate = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !candidate.isEmpty, candidate.count <= 253 else { return nil }
        let label = #"[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?"#
        guard candidate.range(of: "^(?:\(label)\\.)*\(label)$", options: .regularExpression) != nil else {
            return nil
        }
        return candidate
    }

    public func getLogo(for domain: String) async -> NSImage? {
        guard let clean = Self.normalizedDomain(domain) else { return nil }

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
        var googleComponents = URLComponents(string: "https://www.google.com/s2/favicons")
        googleComponents?.queryItems = [
            URLQueryItem(name: "domain", value: clean),
            URLQueryItem(name: "sz", value: "128")
        ]
        let candidateURLs = [
            googleComponents?.url,
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
