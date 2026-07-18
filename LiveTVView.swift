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
    private let playlistURL = "https://iptv-org.github.io/iptv/index.m3u"
    
    // Danh sách kênh nổi tiếng ưu tiên
    private let popularChannels: Set<String> = [
        "HBO", "HBO 2", "HBO Signature", "Cinemax", "Starz",
        "Cartoon Network", "Nickelodeon", "Disney Channel", "Boomerang",
        "CNN", "BBC World News", "Al Jazeera", "Sky News",
        "ESPN", "Fox Sports", "NBC Sports", "beIN Sports",
        "MTV", "VH1", "BET", "Comedy Central",
        "National Geographic", "Discovery", "Animal Planet",
        "TV5Monde", "France 24", "DW", "Arte"
    ]
    
    private let popularCategories = [
        "Movies", "Kids", "News", "Sports", "Music", "Documentary",
        "Entertainment", "General", "Science"
    ]
    
    func fetchChannels() async -> [IPTVChannel] {
        guard let url = URL(string: playlistURL) else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let content = String(data: data, encoding: .utf8) else { return [] }
            var allChannels = parseM3U(content)
            
            // Phân loại
            var popular: [IPTVChannel] = []
            var byCategory: [String: [IPTVChannel]] = [:]
            var other: [IPTVChannel] = []
            
            for channel in allChannels {
                let cat = channel.category ?? "Other"
                if popularChannels.contains(channel.name) {
                    popular.append(channel)
                } else if popularCategories.contains(cat) {
                    byCategory[cat, default: []].append(channel)
                } else {
                    other.append(channel)
                }
            }
            
            // Sắp xếp: Popular trước, sau đó theo category
            var result: [IPTVChannel] = []
            result.append(contentsOf: popular)
            
            for cat in popularCategories {
                if let channels = byCategory[cat] {
                    result.append(contentsOf: channels.prefix(10)) // Giới hạn 10 kênh/category
                }
            }
            
            result.append(contentsOf: other.prefix(50))
            
            // Xóa trùng
            var seen = Set<String>()
            return result.filter { seen.insert($0.url).inserted }
            
        } catch {
            print("❌ IPTV fetch error: \(error)")
            return []
        }
    }
    
    private func parseM3U(_ content: String) -> [IPTVChannel] {
        var channels: [IPTVChannel] = []
        let lines = content.components(separatedBy: .newlines)
        var currentName = "", currentLogo: String?, currentCategory: String?
        
        for i in 0..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("#EXTINF:") {
                if let nameRange = line.range(of: ",") {
                    currentName = String(line[nameRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                }
                if let logoRange = line.range(of: "tvg-logo=\""), let logoEnd = line[logoRange.upperBound...].range(of: "\"") {
                    currentLogo = String(line[logoRange.upperBound..<logoEnd.lowerBound])
                }
                if let catRange = line.range(of: "group-title=\""), let catEnd = line[catRange.upperBound...].range(of: "\"") {
                    currentCategory = String(line[catRange.upperBound..<catEnd.lowerBound])
                }
            } else if !line.hasPrefix("#") && !line.isEmpty && line.hasPrefix("http") {
                if !currentName.isEmpty {
                    channels.append(IPTVChannel(name: currentName, url: line, category: currentCategory, logo: currentLogo))
                }
                currentName = ""; currentLogo = nil; currentCategory = nil
            }
        }
        return channels
    }
}

// MARK: - LiveTV View
struct LiveTVView: View {
    @State private var channels: [IPTVChannel] = []
    @State private var isLoading = true
    @State private var selectedChannel: IPTVChannel?
    @State private var searchText = ""
    @State private var currentCategory = "All"
    @Environment(\.dismiss) var dismiss
    
    var categories: [String] {
        var cats = Set<String>()
        for ch in channels { if let c = ch.category { cats.insert(c) } }
        return ["All"] + Array(cats).sorted()
    }
    
    var filteredChannels: [IPTVChannel] {
        var result = channels
        if currentCategory != "All" {
            result = result.filter { $0.category == currentCategory }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        return result
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Category tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(categories.prefix(12), id: \.self) { cat in
                            Button {
                                currentCategory = cat
                            } label: {
                                Text(cat)
                                    .font(.system(size: 11, weight: currentCategory == cat ? .semibold : .regular))
                                    .foregroundColor(currentCategory == cat ? .white : .white.opacity(0.6))
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(Capsule().fill(currentCategory == cat ? .white.opacity(0.15) : .white.opacity(0.05)))
                            }
                        }
                    }.padding(.horizontal, 12)
                }.padding(.top, 60).padding(.bottom, 6)
                
                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray).font(.system(size: 13))
                    TextField("Tìm kênh...", text: $searchText).foregroundColor(.white).font(.system(size: 13))
                }.padding(10).background(RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial.opacity(0.3))).padding(.horizontal, 12).padding(.bottom, 8)
                
                if isLoading {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(filteredChannels) { channel in
                                Button {
                                    selectedChannel = channel
                                } label: {
                                    HStack(spacing: 12) {
                                        // Logo
                                        if let logo = channel.logo, let url = URL(string: logo) {
                                            CachedAsyncImage(url: url)
                                                .frame(width: 44, height: 44)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        } else {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(.ultraThinMaterial.opacity(0.3))
                                                .frame(width: 44, height: 44)
                                                .overlay(Text(String(channel.name.prefix(2))).font(.system(size: 14, weight: .bold)).foregroundColor(.white.opacity(0.5)))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(channel.name)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            if let cat = channel.category {
                                                Text(cat)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white.opacity(0.4))
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "play.circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(Color.white.opacity(0.02))
                                }
                                
                                if channel.id != filteredChannels.last?.id {
                                    Divider().background(Color.white.opacity(0.05)).padding(.leading, 70)
                                }
                            }
                        }.padding(.bottom, 100)
                    }
                }
            }
            
            // Back button
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold)).foregroundColor(.white).padding(12)
                    .background(Circle().fill(.ultraThinMaterial.opacity(0.4)).overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5)))
            }.padding(.top, 54).padding(.leading, 16)
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $selectedChannel) { channel in
            LivePlayerView(channel: channel)
        }
        .task { await loadChannels() }
    }
    
    func loadChannels() async {
        isLoading = true
        let service = IPTVService()
        channels = await service.fetchChannels()
        isLoading = false
    }
}

// MARK: - Live Player View
struct LivePlayerView: View {
    let channel: IPTVChannel
    @Environment(\.dismiss) var dismiss
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player, errorMessage == nil {
                CustomPlayerVC(player: player, pipController: .constant(nil), gravity: .fit)
                    .ignoresSafeArea()
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            } else if isLoading {
                ProgressView().tint(.white)
            } else if let err = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash").font(.system(size: 40)).foregroundColor(.gray)
                    Text(err).font(.caption).foregroundColor(.gray)
                    Button("Thử lại") { loadStream() }.foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 8).background(Capsule().fill(.ultraThinMaterial))
                }
            }
            
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.white).padding(10)
                            .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                    }
                    Spacer()
                    Text(channel.name).font(.system(size: 13, weight: .medium)).foregroundColor(.white).lineLimit(1)
                    Spacer()
                    Circle().fill(.clear).frame(width: 36)
                }.padding(.horizontal, 16).padding(.top, 50)
                Spacer()
            }
        }
        .onAppear { loadStream() }
    }
    
    func loadStream() {
        isLoading = true
        errorMessage = nil
        guard let url = URL(string: channel.url) else {
            errorMessage = "URL không hợp lệ"
            isLoading = false
            return
        }
        player = AVPlayer(url: url)
        isLoading = false
        
        // Check lỗi sau 3s
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if player?.currentItem?.status == .failed {
                errorMessage = "Không thể phát kênh này"
                player = nil
            }
        }
    }
}