import Foundation
import Combine

public final class ServiceStorageManager: ObservableObject, @unchecked Sendable {
    public static let shared = ServiceStorageManager()

    private let fileManager = FileManager.default
    private let userDefaultsKey = "ManageurStorageDirectoryPath"
    private var directoryWatcherSource: DispatchSourceFileSystemObject?
    private var folderFileDescriptor: Int32 = -1

    public var onExternalChange: (@Sendable () -> Void)?

    @Published public private(set) var rootDirectory: URL

    private init() {
        if let customPath = UserDefaults.standard.string(forKey: userDefaultsKey),
           !customPath.isEmpty {
            self.rootDirectory = URL(fileURLWithPath: customPath, isDirectory: true)
        } else {
            let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            self.rootDirectory = docs.appendingPathComponent("Manageur", isDirectory: true)
        }
        ensureDefaultWorkspacesExist()
        startWatchingDirectory()
    }

    deinit {
        stopWatchingDirectory()
    }

    public func setRootDirectory(_ newURL: URL) {
        stopWatchingDirectory()
        self.rootDirectory = newURL
        UserDefaults.standard.set(newURL.path, forKey: userDefaultsKey)
        ensureDefaultWorkspacesExist()
        startWatchingDirectory()
    }

    private func ensureDefaultWorkspacesExist() {
        let defaults = ["Personal", "Work", "Side Projects"]
        for workspace in defaults {
            let wsDir = rootDirectory.appendingPathComponent(workspace, isDirectory: true)
            if !fileManager.fileExists(atPath: wsDir.path) {
                try? fileManager.createDirectory(at: wsDir, withIntermediateDirectories: true)
            }
        }
    }

    // MARK: - File I/O

    private var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    public func loadAllServices() -> [ServiceItem] {
        guard fileManager.fileExists(atPath: rootDirectory.path) else { return [] }

        var items: [ServiceItem] = []
        guard let workspaceEnumerator = try? fileManager.contentsOfDirectory(at: rootDirectory, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return []
        }

        for wsURL in workspaceEnumerator {
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: wsURL.path, isDirectory: &isDir), isDir.boolValue else {
                continue
            }
            let workspaceName = wsURL.lastPathComponent

            guard let files = try? fileManager.contentsOfDirectory(at: wsURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
                continue
            }

            for fileURL in files where fileURL.pathExtension.lowercased() == "json" {
                if let data = try? Data(contentsOf: fileURL) {
                    do {
                        var item = try jsonDecoder.decode(ServiceItem.self, from: data)
                        // Guarantee workspace matches folder name if missing/empty
                        if item.workspace.isEmpty {
                            item.workspace = workspaceName
                        }
                        items.append(item)
                    } catch {
                        print("Error decoding \(fileURL.lastPathComponent): \(error)")
                    }
                }
            }
        }

        return items
    }

    public func save(service: ServiceItem, oldWorkspace: String? = nil, oldSlug: String? = nil) throws {
        let currentWorkspace = service.workspace.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Personal" : service.workspace
        let wsDir = rootDirectory.appendingPathComponent(currentWorkspace, isDirectory: true)

        if !fileManager.fileExists(atPath: wsDir.path) {
            try fileManager.createDirectory(at: wsDir, withIntermediateDirectories: true)
        }

        let newSlug = service.slug.isEmpty ? ServiceItem.generateSlug(from: service.name) : service.slug
        var updatedService = service
        updatedService.slug = newSlug
        updatedService.workspace = currentWorkspace

        let targetFileURL = wsDir.appendingPathComponent("\(newSlug).json")

        // If workspace or slug changed, remove the old file
        if let oldWs = oldWorkspace, let oldS = oldSlug, (!oldWs.isEmpty && !oldS.isEmpty) {
            if oldWs != currentWorkspace || oldS != newSlug {
                let oldFileURL = rootDirectory.appendingPathComponent(oldWs).appendingPathComponent("\(oldS).json")
                if fileManager.fileExists(atPath: oldFileURL.path) {
                    try? fileManager.removeItem(at: oldFileURL)
                }
            }
        }

        let data = try jsonEncoder.encode(updatedService)
        try data.write(to: targetFileURL, options: .atomic)
    }

    public func delete(service: ServiceItem) throws {
        let ws = service.workspace.isEmpty ? "Personal" : service.workspace
        let fileURL = rootDirectory.appendingPathComponent(ws).appendingPathComponent("\(service.slug).json")
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    public func listWorkspaces() -> [String] {
        var results: Set<String> = ["Personal", "Work", "Side Projects"]
        if let urls = try? fileManager.contentsOfDirectory(at: rootDirectory, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
            for url in urls {
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                    results.insert(url.lastPathComponent)
                }
            }
        }
        return Array(results).sorted()
    }

    // MARK: - Directory Watcher

    private func startWatchingDirectory() {
        guard fileManager.fileExists(atPath: rootDirectory.path) else { return }

        folderFileDescriptor = open(rootDirectory.path, O_EVTONLY)
        guard folderFileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: folderFileDescriptor,
            eventMask: [.write, .delete, .rename, .extend],
            queue: DispatchQueue.main
        )

        source.setEventHandler { [weak self] in
            self?.onExternalChange?()
        }

        source.setCancelHandler { [weak self] in
            if let fd = self?.folderFileDescriptor, fd >= 0 {
                close(fd)
            }
            self?.folderFileDescriptor = -1
        }

        directoryWatcherSource = source
        source.resume()
    }

    private func stopWatchingDirectory() {
        if let source = directoryWatcherSource {
            source.cancel()
            directoryWatcherSource = nil
        }
    }
}
