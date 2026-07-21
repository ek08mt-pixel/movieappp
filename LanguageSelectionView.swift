import SwiftUI

struct LanguageSelectionView: View {
    @StateObject private var langManager = LanguageManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showRestartAlert = false
    @State private var selectedLang: AppLanguage?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(AppLanguage.allCases, id: \.self) { lang in
                        Button {
                            selectedLang = lang
                            showRestartAlert = true
                        } label: {
                            HStack {
                                Text(lang.displayName)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                Spacer()
                                if langManager.currentLanguage == lang {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        
                        if lang != AppLanguage.allCases.last {
                            Divider()
                                .background(Color.white.opacity(0.08))
                                .padding(.leading, 20)
                        }
                    }
                }
                .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial.opacity(0.3)))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.08), lineWidth: 0.5))
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationTitle("Ngôn ngữ")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Khởi động lại ứng dụng", isPresented: $showRestartAlert) {
            Button("OK", role: .cancel) {
                if let lang = selectedLang {
                    langManager.setLanguage(lang)
                }
                dismiss()
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Ngôn ngữ sẽ được áp dụng khi bạn mở lại app.")
        }
    }
}