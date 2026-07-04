import Foundation

enum AppLanguage: String, CaseIterable {
    case vietnamese = "vi"
    case english = "en"
    case korean = "ko"
    case japanese = "ja"
    case chinese = "zh"
    case french = "fr"
    case spanish = "es"
    case german = "de"
    case russian = "ru"
    case thai = "th"
    
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
