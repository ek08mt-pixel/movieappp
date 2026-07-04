import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var langManager: LanguageManager
    @State private var showRestartAlert = false
    @State private var selectedLang: AppLanguage?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            List {
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Button {
                        selectedLang = lang
                        showRestartAlert = true
                    } label: {
                        HStack {
                            Text(lang.displayName).foregroundColor(.white)
                            Spacer()
                            if langManager.currentLanguage == lang {
                                Image(systemName: "checkmark").foregroundColor(.blue)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Ngôn ngữ / Language")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Khởi động lại", isPresented: $showRestartAlert) {
            Button("OK") {
                if let lang = selectedLang {
                    langManager.setLanguage(lang)
                }
                exit(0)
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("App cần khởi động lại để áp dụng ngôn ngữ mới.")
        }
    }
}
