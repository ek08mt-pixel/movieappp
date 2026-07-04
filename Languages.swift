import Foundation

enum AppLanguage: String, CaseIterable {
    case vietnamese = "vi-VN"
    case english = "en-US"
    case korean = "ko-KR"
    case japanese = "ja-JP"
    case chinese = "zh-CN"
    case french = "fr-FR"
    case spanish = "es-ES"
    case german = "de-DE"
    case russian = "ru-RU"
    case thai = "th-TH"
    
    var displayName: String {
        switch self {
        case .vietnamese: return "Tiếng Việt"
        case .english: return "English"
        case .korean: return "한국어"
        case .japanese: return "日本語"
        case .chinese: return "中文"
        case .french: return "Français"
        case .spanish: return "Español"
        case .german: return "Deutsch"
        case .russian: return "Русский"
        case .thai: return "ไทย"
        }
    }
    
    var tmdbLanguage: String {
        return rawValue
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    @Published var currentLanguage: AppLanguage = .vietnamese
    
    init() {
        if let saved = UserDefaults.standard.string(forKey: "appLanguage"),
           let lang = AppLanguage(rawValue: saved) {
            currentLanguage = lang
        }
    }
    
    func setLanguage(_ lang: AppLanguage) {
        currentLanguage = lang
        UserDefaults.standard.set(lang.rawValue, forKey: "appLanguage")
    }
}
