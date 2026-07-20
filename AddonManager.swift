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
    var baseURL = urlString
    
    // Nếu URL đã có manifest.json thì dùng trực tiếp
    if !urlString.contains("manifest.json") {
        baseURL = urlString.hasSuffix("/") ? urlString + "manifest.json" : urlString + "/manifest.json"
    }
    
    guard let url = URL(string: baseURL) else {
        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL không hợp lệ"])
    }
    
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy manifest.json"])
    }
    
    // Parse linh hoạt - bỏ qua field lỗi
    let decoder = JSONDecoder()
    do {
        let manifest = try decoder.decode(AddonManifest.self, from: data)
        return manifest
    } catch {
        // Thử parse thủ công
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let id = json["id"] as? String ?? UUID().uuidString
            let name = json["name"] as? String ?? "Unknown"
            let version = json["version"] as? String ?? "0.0.0"
            let description = json["description"] as? String
            let logo = json["logo"] as? String
            let idPrefixes = json["idPrefixes"] as? [String]
            let resources = json["resources"] as? [String]
            let types = json["types"] as? [String]
            let behaviorHints = json["behaviorHints"] as? [String: String]
            
            var catalogs: [AddonCatalog]? = nil
            if let cats = json["catalogs"] as? [[String: Any]] {
                catalogs = cats.compactMap { cat in
                    guard let type = cat["type"] as? String,
                          let catId = cat["id"] as? String,
                          let catName = cat["name"] as? String else { return nil }
                    var extras: [AddonExtra]? = nil
                    if let extraArr = cat["extra"] as? [[String: Any]] {
                        extras = extraArr.compactMap { extra in
                            guard let extraName = extra["name"] as? String else { return nil }
                            return AddonExtra(name: extraName, options: extra["options"] as? [String], isRequired: extra["isRequired"] as? Bool)
                        }
                    }
                    return AddonCatalog(type: type, id: catId, name: catName, extra: extras)
                }
            }
            
            return AddonManifest(id: id, name: name, version: version, description: description, idPrefixes: idPrefixes, catalogs: catalogs, resources: resources, types: types, logo: logo, behaviorHints: behaviorHints)
        }
        throw NSError(domain: "", code: -3, userInfo: [NSLocalizedDescriptionKey: "Không parse được manifest.json"])
    }
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
    func fetchStream(from addon: SavedAddon, metaId: String, mediaType: String? = nil) async throws -> [AddonStream] {
    let type = (mediaType == "tv") ? "series" : "movie"
    let urlString = "\(addon.url)stream/\(type)/\(metaId).json"
    
    guard let url = URL(string: urlString) else {
        throw NSError(domain: "", code: -1)
    }
    
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw NSError(domain: "", code: -4, userInfo: [NSLocalizedDescriptionKey: "Addon không có stream cho phim này"])
    }
    
    let streamResponse = try JSONDecoder().decode(AddonStreamResponse.self, from: data)
    return streamResponse.streams
}
    
    func fetchBestStream(metaId: String, mediaType: String? = nil) async throws -> URL? {
    let enabledAddons = addons.filter { $0.enabled }
    
    return try await withThrowingTaskGroup(of: (URL, SavedAddon)?.self) { group in
        for addon in enabledAddons {
            group.addTask {
                guard let streams = try? await self.fetchStream(from: addon, metaId: metaId, mediaType: mediaType),
                      let bestStream = streams.first(where: { $0.url != nil && ($0.behaviorHints?.notWebReady != true) }),
                      let urlString = bestStream.url,
                      let url = URL(string: urlString) else {
                    return nil
                }
                return (url, addon)
            }
        }
        
        for try await result in group {
            if let (url, _) = result {
                group.cancelAll()
                return url
            }
        }
        
        throw StreamError.noStreamAvailable
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