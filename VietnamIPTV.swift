import Foundation

class VietnamIPTV {
    static let shared = VietnamIPTV()
    
    func getChannels() -> [IPTVChannel] {
        return [
            // MARK: - VTV
            IPTVChannel(name: "VTV1", url: "https://live.fptplay53.net/live/media/vtv1/live247-hls-avc/index.m3u8", category: "🇻🇳 VTV", logo: "https://i.imgur.com/nfkmvAY.png"),
            IPTVChannel(name: "VTV2", url: "https://live.fptplay53.net/live/media/vtv2/live247-hls-avc/index.m3u8", category: "🇻🇳 VTV", logo: "https://i.imgur.com/BVwi3K3.png"),
            IPTVChannel(name: "VTV3", url: "https://live.fptplay53.net/live/media/vtv3/live247-hls-avc/index.m3u8", category: "🇻🇳 VTV", logo: "https://i.imgur.com/7rLCvgS.png"),
            IPTVChannel(name: "VTV4", url: "https://live.fptplay53.net/live/media/vtv4/live247-hls-avc/index.m3u8", category: "🇻🇳 VTV", logo: "https://i.imgur.com/9zVTtsA.png"),
            IPTVChannel(name: "VTV5", url: "https://live.fptplay53.net/live/media/vtv5/live247-hls-avc/index.m3u8", category: "🇻🇳 VTV", logo: "https://i.imgur.com/7qPKNFU.png"),
            IPTVChannel(name: "VTV6", url: "https://live.fptplay53.net/live/media/vtv6/live247-hls-avc/index.m3u8", category: "🇻🇳 VTV", logo: nil),
            IPTVChannel(name: "VTV7", url: "https://live.fptplay53.net/live/media/vtv7/live247-hls-avc/index.m3u8", category: "🇻🇳 VTV", logo: nil),
            IPTVChannel(name: "VTV8", url: "https://live.fptplay53.net/live/media/vtv8/live-hls-avc/index.m3u8", category: "🇻🇳 VTV", logo: nil),
            IPTVChannel(name: "VTV9", url: "https://live.fptplay53.net/live/media/vtv9/live247-hls-avc/index.m3u8", category: "🇻🇳 VTV", logo: nil),
            IPTVChannel(name: "VTV5 Tây Nam Bộ", url: "https://live.fptplay53.net/live/media/vtv5tnb/live-hls-avc/index.m3u8", category: "🇻🇳 VTV", logo: nil),
            IPTVChannel(name: "VTV5 Tây Nguyên", url: "https://live.fptplay53.net/live/media/vtv5tn/live-hls-avc/index.m3u8", category: "🇻🇳 VTV", logo: nil),
            
            // MARK: - Cartoon / Kids
IPTVChannel(name: "Disney Channel", url: "http://45.171.108.253:8888/DISNEY_CHANNEL/index.m3u8", category: "🌟 Cartoon", logo: nil),

            // MARK: - HTV
            IPTVChannel(name: "HTV1", url: "https://live.fptplay53.net/epzhd1/htv1_vhls.smil/chunklist.m3u8", category: "🇻🇳 HTV", logo: nil),
            IPTVChannel(name: "HTV2", url: "https://live.fptplay53.net/epzhd1/htv2hd_vhls.smil/chunklist.m3u8", category: "🇻🇳 HTV", logo: nil),
            IPTVChannel(name: "HTV3", url: "https://live.fptplay53.net/epzhd1/htv3_hls.smil/chunklist.m3u8", category: "🇻🇳 HTV", logo: nil),
            IPTVChannel(name: "HTV4", url: "https://live.fptplay53.net/epzhd1/htv4_hls.smil/chunklist.m3u8", category: "🇻🇳 HTV", logo: nil),
            IPTVChannel(name: "HTV5", url: "https://live.fptplay53.net/fnxsd1/btv9_hls.smil/chunklist.m3u8", category: "🇻🇳 HTV", logo: nil),
            IPTVChannel(name: "HTV7", url: "https://live.fptplay53.net/live/media/htv7/live247-hls-avc/index.m3u8", category: "🇻🇳 HTV", logo: nil),
            IPTVChannel(name: "HTV9", url: "https://live.fptplay53.net/epzhd1/htv9hd_vhls.smil/chunklist.m3u8", category: "🇻🇳 HTV", logo: nil),
            IPTVChannel(name: "HTV Thể Thao", url: "https://live.fptplay53.net/live/media/htvthethao/live247-hls-avc/index.m3u8", category: "🇻🇳 HTV", logo: nil),
            IPTVChannel(name: "HTVC Ca Nhạc", url: "https://live.fptplay53.net/epzhd1/htvcmusic_vhls.smil/chunklist.m3u8", category: "🇻🇳 HTV", logo: nil),
            IPTVChannel(name: "HTVC Phim", url: "https://live.fptplay53.net/epzhd1/htvcmovieshd_vhls.smil/chunklist.m3u8", category: "🇻🇳 HTV", logo: nil),
            
            // MARK: - VTVcab
            IPTVChannel(name: "ON Vie Giải Trí", url: "https://freem3u.xyz/api/live/play.m3u8?vid=180", category: "🇻🇳 VTVcab", logo: nil),
            IPTVChannel(name: "ON Phim Việt", url: "https://vpsttt.vietanhtv.top/tv360/tv360.php?id=175", category: "🇻🇳 VTVcab", logo: nil),
            IPTVChannel(name: "ON Movies", url: "https://freem3u.xyz/api/live/play.m3u8?vid=181", category: "🇻🇳 VTVcab", logo: nil),
            IPTVChannel(name: "ON Kids", url: "https://freem3u.xyz/api/live/play.m3u8?vid=179", category: "🇻🇳 VTVcab", logo: nil),
            IPTVChannel(name: "ON Music", url: "https://freem3u.xyz/api/live/play.m3u8?vid=185", category: "🇻🇳 VTVcab", logo: nil),
            IPTVChannel(name: "ON Cine", url: "https://freem3u.xyz/api/live/play.m3u8?vid=176", category: "🇻🇳 VTVcab", logo: nil),
            
            // MARK: - Khác
            IPTVChannel(name: "ANTV", url: "https://vips-livecdn.fptplay.net/live/media/antv/live-hls-avc/index.m3u8", category: "🇻🇳 Khác", logo: nil),
            IPTVChannel(name: "QPVN", url: "https://qpvn.vn/live/qpvn/master.m3u8", category: "🇻🇳 Khác", logo: nil),
            IPTVChannel(name: "Da Vinci", url: "https://live.fptplay53.net/fnxhd2/davincihd_vhls.smil/chunklist.m3u8", category: "🇻🇳 Khác", logo: nil),
            IPTVChannel(name: "TVB Việt Nam", url: "https://amg01868-amg01868c3-tvbanywhere-us-4491.playouts.now.amagi.tv/playlist1080p.m3u8", category: "🇻🇳 Khác", logo: nil),
            IPTVChannel(name: "Kix", url: "https://live.fptplay53.net/fnxhd2/kixhd_vhls.smil/chunklist.m3u8", category: "🇻🇳 Khác", logo: nil),
        ]
    }
}