import SwiftUI
import PhotosUI
import AuthenticationServices

// MARK: - Google Sign-In Service
class GoogleSignInService: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = GoogleSignInService()
    
    private let clientID = "1061753109498-js6p8j75lg95m051stn6su5qgn713bo2.apps.googleusercontent.com"
    private let redirectURI = "https://oauth2redirect.com/callback"
    
    struct GoogleUser {
        let email: String
        let name: String
        let avatarURL: String?
    }
    
    func signIn(completion: @escaping (GoogleUser?) -> Void) {
        let scope = "email%20profile%20openid"
        let authURL = "https://accounts.google.com/o/oauth2/v2/auth?client_id=\(clientID)&redirect_uri=\(redirectURI)&response_type=code&scope=\(scope)&access_type=offline&prompt=consent"
        
        guard let url = URL(string: authURL) else {
            completion(nil)
            return
        }
        
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "com.emmew.app") { callbackURL, error in
            guard let callbackURL = callbackURL, error == nil,
                  let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                  let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                completion(nil)
                return
            }
            
            self.exchangeCodeForToken(code: code) { token in
                guard let token = token else {
                    completion(nil)
                    return
                }
                self.fetchUserInfo(token: token, completion: completion)
            }
        }
        
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }
    
    private func exchangeCodeForToken(code: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "code=\(code)&client_id=\(clientID)&redirect_uri=\(redirectURI)&grant_type=authorization_code"
        req.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["access_token"] as? String else {
                completion(nil)
                return
            }
            completion(token)
        }.resume()
    }
    
    private func fetchUserInfo(token: String, completion: @escaping (GoogleUser?) -> Void) {
        let url = URL(string: "https://www.googleapis.com/oauth2/v3/userinfo")!
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(nil)
                return
            }
            
            let email = json["email"] as? String ?? ""
            let name = json["name"] as? String ?? email.components(separatedBy: "@").first ?? ""
            let avatarURL = json["picture"] as? String
            
            let user = GoogleUser(email: email, name: name, avatarURL: avatarURL)
            completion(user)
        }.resume()
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? UIWindow()
    }
}

// MARK: - Onboarding Manager
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    @Published var currentStep = 0
    @Published var selectedReason: String?
    @Published var selectedMovies: [Movie] = []
    @Published var email = ""
    @Published var profiles: [UIImage?] = [nil, nil, nil]
    @Published var recommendedMovies: [Movie] = []
    
    func completeOnboarding(appState: AppState? = nil) {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        if let appState = appState {
            // Google user info
            if let googleName = UserDefaults.standard.string(forKey: "googleName"),
               let googleEmail = UserDefaults.standard.string(forKey: "googleEmail") {
                appState.email = googleEmail
                appState.nickname = googleName
                appState.isLoggedIn = true
                if let googleAvatar = UserDefaults.standard.string(forKey: "googleAvatar") {
                    appState.telegramAvatarURL = googleAvatar
                }
                UserDefaults.standard.removeObject(forKey: "googleName")
                UserDefaults.standard.removeObject(forKey: "googleEmail")
                UserDefaults.standard.removeObject(forKey: "googleAvatar")
            } else if !email.isEmpty {
                appState.email = email
                appState.isLoggedIn = true
                if appState.nickname.isEmpty {
                    let nameFromEmail = email.components(separatedBy: "@").first ?? ""
                    appState.nickname = nameFromEmail.replacingOccurrences(of: "[._-]", with: " ", options: .regularExpression).capitalized
                }
            }
            // Đồng bộ avatar từ onboarding vào appState
            if let firstProfile = profiles.first(where: { $0 != nil }), let imageData = firstProfile?.jpegData(compressionQuality: 0.7) {
                appState.avatarImageData = imageData
                appState.selectedAvatar = ""
            }
            appState.save()
        }
    }
    
    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        currentStep = 0
        selectedMovies = []
        email = ""
        profiles = [nil, nil, nil]
        recommendedMovies = []
    }
    
    func fetchRecommendations() async {
        guard !selectedMovies.isEmpty else { return }
        let genreIds = selectedMovies.compactMap { $0.genreIds }.flatMap { $0 }
        let uniqueGenres = Array(Set(genreIds)).prefix(3)
        
        var allMovies: [Movie] = []
        for genreId in uniqueGenres {
            if let movies = try? await APIService.shared.moviesByGenre(genreId: genreId, page: 1) {
                let filtered = movies.filter { m in !selectedMovies.contains(where: { $0.id == m.id }) && !(m.adult ?? false) }
                allMovies.append(contentsOf: filtered)
            }
        }
        
        let shuffled = Array(Set(allMovies)).shuffled()
        await MainActor.run {
            self.recommendedMovies = Array(shuffled.prefix(9))
        }
    }
}

// MARK: - Main Onboarding View
struct OnboardingView: View {
    @StateObject private var om = OnboardingManager.shared
    var appState: AppState
    @State private var showHome = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch om.currentStep {
            case 0: WelcomeStep(om: om)
            case 1: ReasonStep(om: om)
            case 2: MoviePickerStep(om: om)
            case 3: GoodChoiceStep(om: om)
            case 4: ProfileStep(om: om, appState: appState)
            default: EmptyView()
            }
        }
        .fullScreenCover(isPresented: $showHome) {
            MainTabView()
        }
        .onChange(of: om.currentStep) { step in
            if step > 4 {
                om.completeOnboarding(appState: appState)
                showHome = true
            }
        }
    }
}

// MARK: - Progress Bar
struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int = 3
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Capsule()
                        .fill(i <= currentStep - 1 ? Color.white : Color.white.opacity(0.2))
                        .frame(height: 3)
                        .animation(.easeInOut(duration: 0.5), value: currentStep)
                }
            }
            .padding(.horizontal, 40)
            
            HStack {
                Spacer()
                Button("Skip") {
                    OnboardingManager.shared.currentStep = 4
                }
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }
}

// MARK: - Glass Card Modifier
struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}

// MARK: - Step 0: Welcome
struct WelcomeStep: View {
    @ObservedObject var om: OnboardingManager
    @State private var showEmail = false
    @State private var isGoogleSigningIn = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.1))
                        .frame(width: 80, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                    Path { path in
                        path.move(to: CGPoint(x: 40, y: 60))
                        path.addLine(to: CGPoint(x: 35, y: 72))
                        path.addLine(to: CGPoint(x: 48, y: 60))
                    }
                    .fill(.white.opacity(0.1))
                    .overlay(
                        Path { path in
                            path.move(to: CGPoint(x: 40, y: 60))
                            path.addLine(to: CGPoint(x: 35, y: 72))
                            path.addLine(to: CGPoint(x: 48, y: 60))
                        }
                        .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                    
                    Text("!?")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                }
                
                Text("Welcome to Emmew")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text("Your ultimate movie streaming experience.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                TextField("Email address", text: $om.email)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .glassCard()
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                Button {
                    withAnimation { om.currentStep = 1 }
                } label: {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(.white))
                }
                
                Text("or")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                
                Button {
                    isGoogleSigningIn = true
                    GoogleSignInService.shared.signIn { googleUser in
                        DispatchQueue.main.async {
                            isGoogleSigningIn = false
                            guard let user = googleUser else { return }
                            om.email = user.email
                            UserDefaults.standard.set(user.name, forKey: "googleName")
                            UserDefaults.standard.set(user.email, forKey: "googleEmail")
                            if let avatar = user.avatarURL {
                                UserDefaults.standard.set(avatar, forKey: "googleAvatar")
                            }
                            withAnimation { om.currentStep = 4 }
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Spacer()
                        if isGoogleSigningIn {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                        }
                        Text("Continue with Google")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .glassCard()
                }
                .disabled(isGoogleSigningIn)
                
                Button {
                    withAnimation { om.currentStep = 1 }
                } label: {
                    HStack(spacing: 10) {
                        Spacer()
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        Text("Continue with Apple")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .glassCard()
                }
            }
            .padding(.horizontal, 24)
            
            Spacer().frame(height: 50)
        }
    }
}

// MARK: - Step 1: What brings you?
struct ReasonStep: View {
    @ObservedObject var om: OnboardingManager
    @State private var selectedReason: String? = nil
    
    let reasons = [
        ("🎬", "Khám phá phim mới"),
        ("📺", "Xem TV Shows"),
        ("🎵", "Nghe OST & Nhạc phim")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressBar(currentStep: om.currentStep)
            
            Spacer()
            
            VStack(spacing: 32) {
                Text("What brings you to\nEmmew?")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    ForEach(reasons, id: \.1) { emoji, text in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedReason = text
                            }
                        } label: {
                            HStack(spacing: 14) {
                                Text(emoji).font(.system(size: 28))
                                Text(text).font(.system(size: 16, weight: .medium)).foregroundColor(.white)
                                Spacer()
                                if selectedReason == text {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(16)
                            .glassCard()
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            Button {
                om.selectedReason = selectedReason
                withAnimation { om.currentStep = 2 }
            } label: {
                Text("Next")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(selectedReason != nil ? .white : .white.opacity(0.3)))
            }
            .disabled(selectedReason == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
    }
}

// MARK: - Step 2: Choose movies
struct MoviePickerStep: View {
    @ObservedObject var om: OnboardingManager
    @State private var searchText = ""
    @State private var popularMovies: [Movie] = []
    @State private var searchResults: [Movie] = []
    
    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    
    var displayMovies: [Movie] {
        searchText.isEmpty ? popularMovies : searchResults
    }
    
    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressBar(currentStep: om.currentStep)
            
            VStack(spacing: 16) {
                Text("Choose 3 or more\nmovies you like")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField("Search movies...", text: $searchText)
                        .foregroundColor(.white)
                        .onChange(of: searchText) { query in
                            searchMovies(query: query)
                        }
                }
                .padding(12)
                .glassCard()
                .padding(.horizontal, 24)
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(displayMovies.prefix(12)) { movie in
                            let isSelected = om.selectedMovies.contains(where: { $0.id == movie.id })
                            Button {
                                if isSelected {
                                    om.selectedMovies.removeAll { $0.id == movie.id }
                                } else {
                                    om.selectedMovies.append(movie)
                                }
                            } label: {
                                ZStack(alignment: .bottomTrailing) {
                                    CachedAsyncImage(url: movie.posterURL)
                                        .aspectRatio(2/3, contentMode: .fill)
                                        .frame(height: 160)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(isSelected ? Color.white.opacity(0.35) : Color.clear)
                                        )
                                    
                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(.white, lineWidth: 3)
                                        
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 26))
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Circle().fill(.black.opacity(0.4)))
                                            .padding(6)
                                    }
                                }
                                .frame(height: 160)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
            
            Spacer()
            
            Button {
                withAnimation { om.currentStep = 3 }
                Task { await om.fetchRecommendations() }
            } label: {
                Text("Next")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(om.selectedMovies.count >= 3 ? .white : .white.opacity(0.3)))
            }
            .disabled(om.selectedMovies.count < 3)
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .task {
            popularMovies = (try? await APIService.shared.popular())?.filter { !($0.adult ?? false) } ?? []
        }
    }
    
    func searchMovies(query: String) {
        guard query.count >= 2 else { searchResults = []; return }
        Task {
            searchResults = (try? await APIService.shared.searchMovies(query: query))?.filter { !($0.adult ?? false) } ?? []
        }
    }
}

// MARK: - Step 3: Good Choice!
struct GoodChoiceStep: View {
    @ObservedObject var om: OnboardingManager
    @State private var isLoading = true
    let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text("Good choice!")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 20)
            
            HStack(spacing: 12) {
                ForEach(Array(om.selectedMovies.prefix(3))) { movie in
                    CachedAsyncImage(url: movie.posterURL)
                        .aspectRatio(2/3, contentMode: .fill)
                        .frame(width: 90, height: 135)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .white.opacity(0.15), radius: 8)
                }
            }
            .padding(.bottom, 24)
            
            Text("We'll recommend movies based on your taste")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            
            if isLoading {
                HStack(spacing: 12) {
                    ForEach(0..<3) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .opacity(0.4 + Double(i) * 0.3)
                            .scaleEffect(1.0 + 0.1 * Double(i))
                    }
                }
                .padding(.bottom, 12)
                Text("Đang tìm phim cho bạn...")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            } else if !om.recommendedMovies.isEmpty {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(om.recommendedMovies) { movie in
                            CachedAsyncImage(url: movie.posterURL)
                                .aspectRatio(2/3, contentMode: .fill)
                                .frame(height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: .white.opacity(0.1), radius: 4)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .frame(maxHeight: 300)
            }
            
            Spacer()
            
            Button {
                withAnimation { om.currentStep = 4 }
            } label: {
                Text("Next")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(.white))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .onAppear {
            isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { isLoading = false }
            }
        }
    }
}

// MARK: - Step 4: Profile
struct ProfileStep: View {
    @ObservedObject var om: OnboardingManager
    var appState: AppState
    @State private var selectedProfileIndex: Int = 0
    @State private var showPhotoPicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text("Select Profile")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 50)
            
            VStack(spacing: 30) {
                HStack(spacing: 30) {
                    profileCircle(index: 0)
                    profileCircle(index: 1)
                }
                profileCircle(index: 2)
            }
            
            Text("Add Profile")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 16)
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: "checkmark.square.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                Text("Don't ask again")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.bottom, 20)
            .onTapGesture {
                om.completeOnboarding(appState: appState)
            }
            
            Button {
                om.completeOnboarding(appState: appState)
            } label: {
                Text("Let's go!")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(.white))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView { image in
                om.profiles[selectedProfileIndex] = image
            }
        }
    }
    
    func profileCircle(index: Int) -> some View {
        Button {
            selectedProfileIndex = index
            showPhotoPicker = true
        } label: {
            ZStack {
                if let image = om.profiles[index] {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 2))
                } else {
                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 90, height: 90)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.5))
                        )
                        .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                }
            }
        }
    }
}

// MARK: - Photo Picker
struct PhotoPickerView: UIViewControllerRepresentable {
    var onPick: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (UIImage) -> Void
        init(onPick: @escaping (UIImage) -> Void) { self.onPick = onPick }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let result = results.first else { return }
            result.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                if let image = image as? UIImage {
                    DispatchQueue.main.async { self.onPick(image) }
                }
            }
        }
    }
}