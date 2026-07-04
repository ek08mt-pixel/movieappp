import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var langManager: LanguageManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            List {
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Button {
                        langManager.setLanguage(lang)
                        dismiss()
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
        .navigationTitle("Chọn ngôn ngữ")
        .navigationBarTitleDisplayMode(.inline)
    }
}
