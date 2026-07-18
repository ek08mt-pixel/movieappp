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
    func fetchChannels() async -> [IPTVChannel] {
        // Tạm thời dùng danh sách kênh cứng để test
        return [
            IPTVChannel(name: "Cartoon Network", url: "", category: "Kids", logo: nil),
            IPTVChannel(name: "Nickelodeon", url: "", category: "Kids", logo: nil),
            IPTVChannel(name: "Disney Channel", url: "", category: "Kids", logo: nil),
            IPTVChannel(name: "HBO", url: "", category: "Movies", logo: nil),
            IPTVChannel(name: "HBO 2", url: "", category: "Movies", logo: nil),
            IPTVChannel(name: "Cinemax", url: "", category: "Movies", logo: nil),
            IPTVChannel(name: "CNN", url: "", category: "News", logo: nil),
            IPTVChannel(name: "BBC World", url: "", category: "News", logo: nil),
            IPTVChannel(name: "ESPN", url: "", category: "Sports", logo: nil),
            IPTVChannel(name: "Fox Sports", url: "", category: "Sports", logo: nil),
            IPTVChannel(name: "MTV", url: "", category: "Music", logo: nil),
            IPTVChannel(name: "VH1", url: "", category: "Music", logo: nil),
        ]
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