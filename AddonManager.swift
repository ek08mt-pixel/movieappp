import Foundation

// MARK: - Stremio Addon Models
struct AddonManifest: Codable {
    let id: String
    let name: String
    let version: String
    let description: String?
    let idPrefixes: [String]?
    let catalogs: [AddonCatalog]?
    let resources: [String]?
    let types: [String]?
    let logo: String?
    let behaviorHints: [String: String]?
}

struct AddonCatalog: Codable {
    let type: String
    let id: String
    let name: String
    let extra: [AddonExtra]?
}

struct AddonExtra: Codable {
    let name: String
    let options: [String]?
    let isRequired: Bool?
}

struct AddonMeta: Codable {
    let id: String
    let type: String
    let name: String
    let poster: String?
    let posterShape: String?
    let description: String?
    let releaseInfo: String?
    let imdbRating: String?
    let genres: [String]?
    let year: String?
}

struct AddonStream: Codable {
    let title: String?
    let url: String?
    let infoHash: String?
    let fileIdx: Int?
    let behaviorHints: StreamHints?
}

struct StreamHints: Codable {
    let bingeGroup: String?
    let notWebReady: Bool?
    let proxyHeaders: [String: String]?
}

struct AddonCatalogResponse: Codable {
    let metas: [AddonMeta]
}

struct AddonStreamResponse: Codable {
    let streams: [AddonStream]
}

// MARK: - Saved Addon
struct SavedAddon: Codable, Identifiable {
    var id: String { url }
    let url: String
    let manifest: AddonManifest
    var enabled: Bool
    var addedDate: Date
}

// MARK: - Addon Manager
class AddonManager: ObservableObject {
    static let shared = AddonManager()
    
    @Published var addons: [SavedAddon] = []
    
    private let storageKey = "savedAddons"
    
    init() {
        loadAddons()
    }
    
    func fetchManifest(from urlString: String) async throws -> AddonManifest {
        let baseURL = urlString.hasSuffix("/") ? urlString : urlString + "/"
        guard let url = URL(string: baseURL + "manifest.json") else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL không hợp lệ"])
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy manifest.json"])
        }
        
        let manifest = try JSONDecoder().decode(AddonManifest.self, from: data)
        return manifest
    }
    
    func addAddon(url: String, manifest: AddonManifest) {
        let baseURL = url.hasSuffix("/") ? url : url + "/"
        let saved = SavedAddon(url: baseURL, manifest: manifest, enabled: true, addedDate: Date())
        
        // Xóa addon cũ cùng id nếu có
        addons.removeAll { $0.manifest.id == manifest.id }
        addons.append(saved)
        saveAddons()
    }
    
    func removeAddon(at offsets: IndexSet) {
        addons.remove(atOffsets: offsets)
        saveAddons()
    }
    
    func toggleAddon(id: String) {
        if let idx = addons.firstIndex(where: { $0.manifest.id == id }) {
            addons[idx].enabled.toggle()
            saveAddons()
        }
    }
    
    // Lấy catalog từ addon (danh sách phim)
    func fetchCatalog(from addon: SavedAddon, type: String = "movie") async throws -> [AddonMeta] {
        guard let catalog = addon.manifest.catalogs?.first else {
            throw NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "Addon không hỗ trợ catalog"])
        }
        
        var urlString = "\(addon.url)catalog/\(type)/\(catalog.id).json"
        if let extra = catalog.extra?.first, let _ = extra.options {
            urlString += "?\(extra.name)=\(extra.options?.first ?? "")"
        }
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "", code: -1)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(AddonCatalogResponse.self, from: data)
        return response.metas
    }
    
    // Lấy stream từ addon
    func fetchStream(from addon: SavedAddon, metaId: String) async throws -> [AddonStream] {
        let urlString = "\(addon.url)stream/movie/\(metaId).json"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "", code: -1)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(AddonStreamResponse.self, from: data)
        return response.streams
    }
    
    // Lấy stream nhanh nhất từ tất cả addon
    func fetchBestStream(metaId: String) async throws -> URL? {
        let enabledAddons = addons.filter { $0.enabled }
        
        return try await withThrowingTaskGroup(of: (AddonStream, SavedAddon)?.self) { group in
            for addon in enabledAddons {
                group.addTask {
                    guard let streams = try? await self.fetchStream(from: addon, metaId: metaId),
                          let bestStream = streams.first(where: { $0.url != nil }) else {
                        return nil
                    }
                    return (bestStream, addon)
                }
            }
            
            for try await result in group {
                if let (stream, _) = result, let urlString = stream.url, let url = URL(string: urlString) {
                    group.cancelAll()
                    return url
                }
            }
            
            return nil
        }
    }
    
    // Lấy tất cả catalog từ tất cả addon
    func fetchAllCatalogs(type: String = "movie") async -> [AddonMeta] {
        let enabledAddons = addons.filter { $0.enabled }
        var allMetas: [AddonMeta] = []
        
        for addon in enabledAddons {
            if let metas = try? await fetchCatalog(from: addon, type: type) {
                allMetas.append(contentsOf: metas)
            }
        }
        
        return allMetas
    }
    
    private func saveAddons() {
        if let data = try? JSONEncoder().encode(addons) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadAddons() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([SavedAddon].self, from: data) {
            addons = saved
        }
    }
}