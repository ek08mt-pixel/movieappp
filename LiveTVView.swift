import SwiftUI
import AVKit

struct LiveTVView: View {
    @State private var channels: [IPTVChannel] = []
    @State private var isLoading = true
    @State private var selectedChannel: IPTVChannel?
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: [Color(white: 0.08), Color(white: 0.02), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            
            if isLoading {
                ProgressView().tint(.white)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Live TV").font(.largeTitle.bold()).foregroundColor(.white).padding(.top, 70).padding(.horizontal, 16).frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass").foregroundColor(.gray)
                            TextField("Tìm kênh...", text: $searchText).foregroundColor(.white)
                        }.padding(12).background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial.opacity(0.3))).padding(.horizontal, 16)
                        
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(filteredChannels) { channel in
                                Button {
                                    selectedChannel = channel
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: "tv.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.green)
                                            .frame(width: 60, height: 60)
                                            .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                                        Text(channel.name)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                        Text(channel.category ?? "")
                                            .font(.system(size: 9))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.2)))
                                }
                            }
                        }.padding(.horizontal, 16)
                        
                        Spacer().frame(height: 100)
                    }
                }
            }
            
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold)).foregroundColor(.white).padding(12)
                    .background(Circle().fill(.ultraThinMaterial.opacity(0.4)).overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 0.5)))
            }.padding(.top, 54).padding(.leading, 16)
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $selectedChannel) { channel in
            LivePlayerView(channel: channel)
        }
        .task {
            await loadChannels()
        }
    }
    
    var filteredChannels: [IPTVChannel] {
        if searchText.isEmpty { return channels }
        return channels.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
    
    func loadChannels() async {
        isLoading = true
        let service = IPTVService()
        channels = await service.fetchChannels()
        isLoading = false
    }
}

struct IPTVChannel: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let category: String?
    let logo: String?
}

class IPTVService {
    private let playlistURL = "https://iptv-org.github.io/iptv/index.m3u"
    
    func fetchChannels() async -> [IPTVChannel] {
        guard let url = URL(string: playlistURL) else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let content = String(data: data, encoding: .utf8) else { return [] }
            return parseM3U(content)
        } catch {
            print("❌ Failed to fetch IPTV: \(error)")
            return []
        }
    }
    
    private func parseM3U(_ content: String) -> [IPTVChannel] {
        var channels: [IPTVChannel] = []
        let lines = content.components(separatedBy: .newlines)
        
        var currentName = ""
        var currentLogo: String?
        var currentCategory: String?
        
        for i in 0..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            
            if line.hasPrefix("#EXTINF:") {
                // Parse tên kênh và attributes
                if let nameRange = line.range(of: ",") {
                    currentName = String(line[nameRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                }
                
                // Parse logo
                if let logoRange = line.range(of: "tvg-logo=\""),
                   let logoEnd = line[logoRange.upperBound...].range(of: "\"") {
                    let logo = String(line[logoRange.upperBound..<logoEnd.lowerBound])
                    currentLogo = logo.isEmpty ? nil : logo
                }
                
                // Parse category
                if let catRange = line.range(of: "group-title=\""),
                   let catEnd = line[catRange.upperBound...].range(of: "\"") {
                    let cat = String(line[catRange.upperBound..<catEnd.lowerBound])
                    currentCategory = cat.isEmpty ? nil : cat
                }
            } else if !line.hasPrefix("#") && !line.isEmpty {
                // Đây là URL stream
                if !currentName.isEmpty && (line.hasPrefix("http") || line.hasPrefix("https")) {
                    let channel = IPTVChannel(
                        name: currentName,
                        url: line,
                        category: currentCategory,
                        logo: currentLogo
                    )
                    channels.append(channel)
                }
                currentName = ""
                currentLogo = nil
                currentCategory = nil
            }
        }
        
        // Lọc bỏ kênh trùng và sắp xếp theo category
        var seen = Set<String>()
        return channels.filter { seen.insert($0.name).inserted }
    }
}

struct LivePlayerView: View {
    let channel: IPTVChannel
    @Environment(\.dismiss) var dismiss
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let player = player {
                CustomPlayerVC(player: player, pipController: .constant(nil), gravity: .fit)
                    .ignoresSafeArea()
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            } else {
                ProgressView().tint(.white)
            }
            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)).foregroundColor(.white).padding(10)
                            .background(Circle().fill(.ultraThinMaterial.opacity(0.4)))
                    }
                    Spacer()
                    Text(channel.name).font(.caption).foregroundColor(.white).lineLimit(1)
                    Spacer()
                    Circle().fill(.clear).frame(width: 36)
                }.padding(.horizontal, 16).padding(.top, 50)
                Spacer()
            }
        }
        .onAppear {
            if let url = URL(string: channel.url) {
                player = AVPlayer(url: url)
            }
        }
    }
}