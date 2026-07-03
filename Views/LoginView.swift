import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "popcorn.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Đăng nhập")
                        .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                    
                    TextField("Tên của bạn", text: $name)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    Button {
                        if !name.isEmpty {
                            appState.isLoggedIn = true
                            appState.userName = name
                            dismiss()
                        }
                    } label: {
                        Text("Vào xem phim")
                            .font(.headline).fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [.orange, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .padding(.horizontal)
                    .disabled(name.isEmpty)
                    .opacity(name.isEmpty ? 0.5 : 1)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Bỏ qua") { dismiss() }
                }
            }
        }
    }
}
