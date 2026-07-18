import SwiftUI
import AVKit

// MARK: - IPTV Models & Service
struct IPTVChannel: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let category: String?
    let logo: String?
}

class IPTVService {
    static let shared = IPTVService()
    private let playlistURL = "https://iptv-org.github.io/iptv/index.m3u"
    private let cacheKey = "iptv_channels_cache"
    private let cacheDateKey = "iptv_cache_date"
    
    private let popularChannels: Set<String> = [
        "HBO", "HBO 2", "HBO Signature", "Cinemax", "Starz",
        "Cartoon Network", "Nickelodeon", "Disney Channel", "Boomerang",
        "CNN", "BBC World News", "Al Jazeera", "Sky News",
        "ESPN", "Fox Sports", "NBC Sports", "beIN Sports",
        "MTV", "VH1", "BET", "Comedy Central",
        "National Geographic", "Discovery", "Animal Planet",
        "TV5Monde", "France 24", "DW", "Arte",
        "BBC One", "BBC Two", "ITV", "Channel 4",
        "ABC", "NBC", "CBS", "FOX", "PBS",
        "AMC", "FX", "TNT", "TBS", "USA Network",
        "History", "A&E", "Lifetime", "Freeform",
        "Nick Jr", "Disney Junior", "PBS Kids", "Oggy", "Oggy and the Cockroaches", "Family Guy", "American Dad",
        "Fox Family", "Fox Comedy", "Adult Swim", "Toonami",
        "Animax", "Anime", "Nicktoons", "Cartoon Netowrk"
    ]
    
    private let regionURLs = [
        "https://iptv-org.github.io/iptv/regions/amer.m3u",
        "https://iptv-org.github.io/iptv/regions/eur.m3u",
        "https://iptv-org.github.io/iptv/regions/asia.m3u",
        "https://iptv-org.github.io/iptv/countries/us.m3u",
        "https://iptv-org.github.io/iptv/countries/uk.m3u",
    ]
    
    private let popularCategories = [
        "Movies", "Kids", "News", "Sports", "Music", "Documentary",
        "Entertainment", "General", "Science"
    ]
    
    func fetchRegionChannels() async -> [IPTVChannel] {
        var all: [IPTVChannel] = []
        for urlString in regionURLs {
            guard let url = URL(string: urlString) else { continue }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let content = String(data: data, encoding: .utf8) {
                    all.append(contentsOf: parseM3U(content))
                }
            } catch {}
        }
        var seen = Set<String>()
        return all.filter { seen.insert($0.url).inserted }
    }
    
    func fetchChannels() async -> [IPTVChannel] {
        if let cached = loadCache(), !isCacheExpired() { return cached }
        guard let url = URL(string: playlistURL) else { return loadCache() ?? [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let content = String(data: data, encoding: .utf8) else { return loadCache() ?? [] }
            var channels = filterAndSort(parseM3U(content))
            channels.insert(contentsOf: VietnamIPTV.shared.getChannels(), at: 0)
            let regionChannels = await fetchRegionChannels()
            channels.insert(contentsOf: regionChannels, at: 0)
            saveCache(channels)
            return channels
        } catch { return loadCache() ?? [] }
    }
    
    private func filterAndSort(_ allChannels: [IPTVChannel]) -> [IPTVChannel] {
        var popular: [IPTVChannel] = []
        var byCategory: [String: [IPTVChannel]] = [:]
        var other: [IPTVChannel] = []
        for channel in allChannels {
            let cat = channel.category ?? "Other"
            if popularChannels.contains(channel.name) { popular.append(channel) }
            else if popularCategories.contains(cat) { byCategory[cat, default: []].append(channel) }
            else { other.append(channel) }
        }
        var result: [IPTVChannel] = []
        result.append(contentsOf: popular)
        for cat in popularCategories { if let c = byCategory[cat] { result.append(contentsOf: c) } }
        result.append(contentsOf: other)
        var seen = Set<String>()
        return result.filter { seen.insert($0.url).inserted }
    }
    
    private func parseM3U(_ content: String) -> [IPTVChannel] {
        var channels: [IPTVChannel] = []
        let lines = content.components(separatedBy: .newlines)
        var currentName = "", currentLogo: String?, currentCategory: String?
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#EXTINF:") {
                if let nameRange = trimmed.range(of: ",") { currentName = String(trimmed[nameRange.upperBound...]).trimmingCharacters(in: .whitespaces) }
                if let logoRange = trimmed.range(of: "tvg-logo=\""), let logoEnd = trimmed[logoRange.upperBound...].range(of: "\"") { currentLogo = String(trimmed[logoRange.upperBound..<logoEnd.lowerBound]) }
                if let catRange = trimmed.range(of: "group-title=\""), let catEnd = trimmed[catRange.upperBound...].range(of: "\"") { currentCategory = String(trimmed[catRange.upperBound..<catEnd.lowerBound]) }
            } else if !trimmed.hasPrefix("#") && !trimmed.isEmpty && trimmed.hasPrefix("http") {
                if !currentName.isEmpty { channels.append(IPTVChannel(name: currentName, url: trimmed, category: currentCategory, logo: currentLogo)) }
                currentName = ""; currentLogo = nil; currentCategory = nil
            }
        }
        return channels
    }
    
    private func saveCache(_ channels: [IPTVChannel]) {
        let data = channels.map { ["name": $0.name, "url": $0.url, "category": $0.category ?? "", "logo": $0.logo ?? ""] }
        UserDefaults.standard.set(data, forKey: cacheKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheDateKey)
    }
    
    private func loadCache() -> [IPTVChannel]? {
        guard let data = UserDefaults.standard.array(forKey: cacheKey) as? [[String: String]] else { return nil }
        return data.compactMap { dict in
            guard let name = dict["name"], let url = dict["url"] else { return nil }
            return IPTVChannel(name: name, url: url, category: dict["category"]?.isEmpty == false ? dict["category"] : nil, logo: dict["logo"]?.isEmpty == false ? dict["logo"] : nil)
        }
    }
    
    private func isCacheExpired() -> Bool {
        Date().timeIntervalSince1970 - UserDefaults.standard.double(forKey: cacheDateKey) > 86400
    }
}

// MARK: - LiveTV View
struct LiveTVView: View {
    @State private var channels: [IPTVChannel] = []
    @State private var isLoading = true
    @State private var selectedChannel: IPTVChannel?
    @State private var searchText = ""
    @State private var currentCategory = "All"
    @AppStorage("blocked_channels") private var blockedURLs: String = ""
    @Environment(\.dismiss) var dismiss
    
    var categories: [String] {
        var cats = Set<String>()
        for ch in channels { if let c = ch.category { cats.insert(c) } }
        return ["All"] + Array(cats).sorted()
    }
    
    var filteredChannels: [IPTVChannel] {
        let blocked = Set(blockedURLs.components(separatedBy: ","))
        var result = channels.filter { !blocked.contains($0.url) }
        if currentCategory != "All" { result = result.filter { $0.category == currentCategory } }
        if !searchText.isEmpty { result = result.filter { $0.name.lowercased().contains(searchText.lowercased()) } }
        return result
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(categories.prefix(12), id: \.self) { cat in
                            Button { currentCategory = cat } label: {
                                Text(cat).font(.system(size: 11, weight: currentCategory == cat ? .semibold : .regular))
                                    .foregroundColor(currentCategory == cat ? .white : .white.opacity(0.6))
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(Capsule().fill(currentCategory == cat ? .white.opacity(0.15) : .white.opacity(0.05)))
                            }
                        }
                    }.padding(.horizontal, 12).padding(.leading, 44)
                }.padding(.top, 50).padding(.bottom, 6)
                
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray).font(.system(size: 13))
                    TextField("Tìm kênh...", text: $searchText).foregroundColor(.white).font(.system(size: 13))
                }.padding(10).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.3))).padding(.horizontal, 12).padding(.bottom, 8)
                
                if isLoading { Spacer(); ProgressView().tint(.white); Spacer() }
                else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(filteredChannels) { channel in
                                Button { selectedChannel = channel } label: {
                                    HStack(spacing: 12) {
                                        if let logo = channel.logo, let url = URL(string: logo) { CachedAsyncImage(url: url).frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 8)) }
                                        else { RoundedRectangle(cornerRadius: 8).fill(.ultraThinMaterial.opacity(0.3)).frame(width: 44, height: 44).overlay(Text(String(channel.name.prefix(2))).font(.system(size: 14, weight: .bold)).foregroundColor(.white.opacity(0.5))) }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(channel.name).font(.system(size: 13, weight: .medium)).foregroundColor(.white).lineLimit(1)
                                            if let cat = channel.category { Text(cat).font(.system(size: 10)).foregroundColor(.white.opacity(0.4)) }
                                        }
                                        Spacer()
                                        Image(systemName: "play.circle").font(.system(size: 20)).foregroundColor(.white.opacity(0.3))
                                    }.padding(.horizontal, 14).padding(.vertical, 8).background(Color.white.opacity(0.02))
                                }
                                if channel.id != filteredChannels.last?.id { Divider().background(Color.white.opacity(0.05)).padding(.leading, 70) }
                            }
                        }.padding(.bottom, 100)
                    }
                }
            }
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold)).foregroundColor(.white).padding(12)
                    .background(Circle().fill(.ultraThinMaterial.opacity(0.4)).overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5)))
            }.padding(.top, 35).padding(.leading, 16)
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $selectedChannel) { channel in LivePlayerView(channel: channel, allChannels: filteredChannels) }
        .task { await loadChannels() }
    }
    
    func loadChannels() async {
        isLoading = true
        channels = await IPTVService.shared.fetchChannels()
        isLoading = false
    }
}

// MARK: - Live Player View
struct LivePlayerView: View {
    let channel: IPTVChannel
    let allChannels: [IPTVChannel]
    @Environment(\.dismiss) var dismiss
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var currentChannel: IPTVChannel
    @AppStorage("blocked_channels") private var blockedURLs: String = ""
    
    init(channel: IPTVChannel, allChannels: [IPTVChannel] = []) {
        self.channel = channel
        self.allChannels = allChannels
        _currentChannel = State(initialValue: channel)
    }
    
    var currentIndex: Int { allChannels.firstIndex(where: { $0.url == currentChannel.url }) ?? 0 }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let player = player, errorMessage == nil {
                CustomPlayerVC(player: player, pipController: .constant(nil), gravity: .fit).ignoresSafeArea()
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            } else if isLoading { ProgressView().tint(.white) }
            else if let err = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash").font(.system(size: 40)).foregroundColor(.gray)
                    Text(err).font(.caption).foregroundColor(.gray)
                    Button("Thử lại") { loadStream() }.foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 8).background(Capsule().fill(.ultraThinMaterial))
                }
            }
            VStack {
                HStack {
                    Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.white).padding(10).background(Circle().fill(.ultraThinMaterial.opacity(0.4))) }
                    Spacer()
                    Text(currentChannel.name).font(.system(size: 13, weight: .medium)).foregroundColor(.white).lineLimit(1)
                    Button {
                        var blocked = blockedURLs.components(separatedBy: ",")
                        blocked.append(currentChannel.url)
                        blockedURLs = blocked.joined(separator: ",")
                        dismiss()
                    } label: {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 12)).foregroundColor(.yellow.opacity(0.7))
                    }
                    Spacer()
                    Circle().fill(.clear).frame(width: 36)
                }.padding(.horizontal, 16).padding(.top, 50)
                Spacer()
                if !allChannels.isEmpty {
                    HStack(spacing: 40) {
                        Button {
                            let prev = max(currentIndex - 1, 0)
                            currentChannel = allChannels[prev]; loadStream()
                        } label: {
                            Image(systemName: "chevron.left.2").font(.system(size: 24)).foregroundColor(.white.opacity(0.7)).padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
                        }.opacity(currentIndex > 0 ? 1 : 0.3)
                        Button {
                            let next = min(currentIndex + 1, allChannels.count - 1)
                            currentChannel = allChannels[next]; loadStream()
                        } label: {
                            Image(systemName: "chevron.right.2").font(.system(size: 24)).foregroundColor(.white.opacity(0.7)).padding(12).background(Circle().fill(.ultraThinMaterial.opacity(0.3)))
                        }.opacity(currentIndex < allChannels.count - 1 ? 1 : 0.3)
                    }.padding(.bottom, 30)
                }
            }
        }
        .onAppear { loadStream() }
    }
    
    func loadStream() {
        isLoading = true; errorMessage = nil
        player?.pause(); player?.replaceCurrentItem(with: nil); player = nil
        guard let url = URL(string: currentChannel.url) else { errorMessage = "URL không hợp lệ"; isLoading = false; return }
        let newPlayer = AVPlayer(url: url)
        player = newPlayer; isLoading = false; newPlayer.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if newPlayer.currentItem?.status == .failed { errorMessage = "Không thể phát kênh này"; player = nil }
        }
    }
}