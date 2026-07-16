import SwiftUI
import AuthenticationServices

// MARK: - Onboarding Manager
class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @Published var currentStep = 0
    @Published var selectedReason: String?
    @Published var selectedMovies: [Movie] = []
    @Published var email = ""
    @Published var profiles: [String] = ["😎", "🦊", "🐱"]
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentStep = 0
        selectedMovies = []
        email = ""
    }
}

// MARK: - Main Onboarding View
struct OnboardingView: View {
    @StateObject private var om = OnboardingManager.shared
    @State private var showHome = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch om.currentStep {
            case 0: WelcomeStep(om: om)
            case 1: ReasonStep(om: om)
            case 2: MoviePickerStep(om: om)
            case 3: GoodChoiceStep(om: om)
            case 4: ProfileStep(om: om)
            default: EmptyView()
            }
        }
        .fullScreenCover(isPresented: $showHome) {
            MainTabView()
        }
        .onChange(of: om.currentStep) { step in
            if step > 4 {
                om.completeOnboarding()
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
            HStack {
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

// MARK: - Step 0: Welcome
struct WelcomeStep: View {
    @ObservedObject var om: OnboardingManager
    @State private var showEmail = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Logo & Welcome
            VStack(spacing: 12) {
                Text("👋")
                    .font(.system(size: 60))
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
            
            // Email & Buttons
            VStack(spacing: 16) {
                // Email field
                TextField("Email address", text: $om.email)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.1)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.15), lineWidth: 0.5))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                // Continue button
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
                
                // Or
                HStack(spacing: 12) {
                    Rectangle().fill(.white.opacity(0.2)).frame(height: 1)
                    Text("or").font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                    Rectangle().fill(.white.opacity(0.2)).frame(height: 1)
                }
                
                // Continue with Google
                Button {
                    withAnimation { om.currentStep = 1 }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                        Text("Continue with Google")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.1)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.15), lineWidth: 0.5))
                }
                
                // Continue with Apple
                Button {
                    withAnimation { om.currentStep = 1 }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        Text("Continue with Apple")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.1)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.15), lineWidth: 0.5))
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
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedReason == text ? .white.opacity(0.12) : .white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedReason == text ? .white.opacity(0.3) : .white.opacity(0.08), lineWidth: 0.5)
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Next button
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
    
    let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
    
    var displayMovies: [Movie] {
        searchText.isEmpty ? popularMovies : searchResults
    }
    
    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressBar(currentStep: om.currentStep)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose 3 or more\nmovies you like")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                
                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    TextField("Search movies...", text: $searchText)
                        .foregroundColor(.white)
                        .onChange(of: searchText) { query in
                            searchMovies(query: query)
                        }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.1)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.12), lineWidth: 0.5))
                .padding(.horizontal, 24)
                
                // Movie grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(displayMovies.prefix(12)) { movie in
                            let isSelected = om.selectedMovies.contains(where: { $0.id == movie.id })
                            Button {
                                if isSelected {
                                    om.selectedMovies.removeAll { $0.id == movie.id }
                                } else {
                                    om.selectedMovies.append(movie)
                                }
                            } label: {
                                ZStack {
                                    CachedAsyncImage(url: movie.posterURL)
                                        .aspectRatio(2/3, contentMode: .fill)
                                        .frame(height: 160)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(isSelected ? Color.white.opacity(0.3) : Color.clear)
                                        )
                                    
                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(.white, lineWidth: 3)
                                        
                                        VStack {
                                            Spacer()
                                            HStack {
                                                Spacer()
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.white)
                                                    .padding(6)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
            
            Spacer()
            
            // Next button
            Button {
                withAnimation { om.currentStep = 3 }
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
    @State private var showStars = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text("Good choice! 👏")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 30)
            
            // Selected movies
            HStack(spacing: 12) {
                ForEach(Array(om.selectedMovies.prefix(3))) { movie in
                    CachedAsyncImage(url: movie.posterURL)
                        .aspectRatio(2/3, contentMode: .fill)
                        .frame(width: 100, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .white.opacity(0.2), radius: 10)
                }
            }
            
            Text("We'll recommend movies based on your taste")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 20)
            
            // Stars
            HStack(spacing: 6) {
                ForEach(0..<3) { i in
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(.yellow)
                        .opacity(showStars ? 1 : 0.3)
                        .scaleEffect(showStars ? 1 : 0.5)
                        .animation(.easeInOut(duration: 0.6).delay(Double(i) * 0.2).repeatForever(autoreverses: true), value: showStars)
                }
            }
            .padding(.top, 12)
            
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
            showStars = true
        }
    }
}

// MARK: - Step 4: Profile
struct ProfileStep: View {
    @ObservedObject var om: OnboardingManager
    @State private var showImagePicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text("Select Profile")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 40)
            
            // 3 avatar slots (2 trên, 1 dưới)
            VStack(spacing: 20) {
                // 2 trên
                HStack(spacing: 20) {
                    profileCircle(index: 0)
                    profileCircle(index: 1)
                }
                // 1 dưới
                profileCircle(index: 2)
            }
            
            Text("Add Profile")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 12)
            
            Spacer()
            
            // Don't ask again
            HStack {
                Image(systemName: "checkmark.square.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                Text("Don't ask again")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.bottom, 20)
            .onTapGesture {
                om.completeOnboarding()
            }
            
            Button {
                om.completeOnboarding()
            } label: {
                Text("Let's go! 🚀")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(.white))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
    }
    
    func profileCircle(index: Int) -> some View {
        ZStack {
            if index < om.profiles.count {
                Circle()
                    .fill(.ultraThinMaterial.opacity(0.4))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(om.profiles[index])
                            .font(.system(size: 36))
                    )
                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
            } else {
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.5))
                    )
                    .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
            }
        }
    }
}