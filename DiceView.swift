import SwiftUI
import SceneKit
import CoreMotion

struct DiceOverlayView: View {
    @StateObject private var diceManager = DiceManager.shared
    @EnvironmentObject var appState: AppState
    @State private var scene = SCNScene()
    @State private var diceNode: SCNNode?
    @State private var isAnimating = false
    @State private var showResult = false
    @State private var movies: [Movie] = []
    @State private var selectedMovie: Movie?
    @State private var showMovieDetail = false
    
    let motionManager = CMMotionManager()
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
                .onTapGesture { diceManager.showDice = false }
            
            VStack(spacing: 24) {
                Text(isAnimating ? "🎲 Đang lắc..." : "Lắc mạnh điện thoại để đổ xí ngầu!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 60)
                
                SceneView(scene: scene, options: [.allowsCameraControl, .autoenablesDefaultLighting])
                    .frame(width: 220, height: 220)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.ultraThinMaterial.opacity(0.2))
                            .shadow(color: .black.opacity(0.6), radius: 25, y: 15)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
                
                if showResult, let movie = selectedMovie {
                    VStack(spacing: 16) {
                        Text("🎬 Kết quả: \(movie.title)")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        if let posterURL = movie.posterURL {
                            CachedAsyncImage(url: posterURL)
                                .aspectRatio(2/3, contentMode: .fill)
                                .frame(width: 140, height: 210)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .white.opacity(0.2), radius: 10)
                        }
                        
                        HStack(spacing: 16) {
                            Button {
                                showMovieDetail = true
                            } label: {
                                Text("Xem chi tiết")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24).padding(.vertical, 10)
                                    .background(Capsule().fill(.ultraThinMaterial.opacity(0.5)))
                                    .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 0.5))
                            }
                            
                            Button {
                                diceManager.showDice = false
                            } label: {
                                Text("Thử lại")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 24).padding(.vertical, 10)
                                    .background(Capsule().fill(.ultraThinMaterial.opacity(0.3)))
                                    .overlay(Capsule().stroke(.white.opacity(0.15), lineWidth: 0.5))
                            }
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showResult)
                }
                
                Spacer()
            }
        }
        .onAppear {
            setupDice()
            loadMovies()
            startMotionDetection()
        }
        .onDisappear {
            motionManager.stopAccelerometerUpdates()
        }
        .fullScreenCover(isPresented: $showMovieDetail) {
            if let movie = selectedMovie {
                MovieDetailView(movie: movie)
                    .environmentObject(appState)
            }
        }
    }
    
    func setupDice() {
        scene.background.contents = UIColor.clear
        
        let camera = SCNCamera()
        camera.fieldOfView = 45
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 5)
        scene.rootNode.addChildNode(cameraNode)
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.4, alpha: 1)
        scene.rootNode.addChildNode(ambientLight)
        
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.color = UIColor(white: 0.8, alpha: 1)
        directionalLight.position = SCNVector3(5, 5, 5)
        scene.rootNode.addChildNode(directionalLight)
        
        let box = SCNBox(width: 2, height: 2, length: 2, chamferRadius: 0.3)
        for i in 0..<6 {
            box.materials[i].diffuse.contents = UIColor(white: 0.2, alpha: 1)
            box.materials[i].specular.contents = UIColor.white
            box.materials[i].shininess = 1.0
        }
        
        diceNode = SCNNode(geometry: box)
        diceNode?.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(diceNode!)
        
        let rotateAction = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 10)
        diceNode?.runAction(SCNAction.repeatForever(rotateAction))
    }
    
    func loadMovies() {
        Task {
            if let m = try? await APIService.shared.popular() {
                movies = Array(m.filter { !($0.adult ?? false) }.shuffled().prefix(6))
                updateDiceFaces()
            }
        }
    }
    
    func updateDiceFaces() {
        guard let diceNode = diceNode, let box = diceNode.geometry as? SCNBox, movies.count == 6 else { return }
        for i in 0..<6 {
            if let posterURL = movies[i].posterURL {
                URLSession.shared.dataTask(with: posterURL) { data, _, _ in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            box.materials[i].diffuse.contents = image
                        }
                    }
                }.resume()
            }
        }
    }
    
    func startMotionDetection() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { data, _ in
            guard let acc = data?.acceleration, !isAnimating else { return }
            let magnitude = sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z)
            if magnitude > 2.8 {
                rollDice()
            }
        }
    }
    
    func rollDice() {
        guard !isAnimating, let diceNode = diceNode else { return }
        isAnimating = true
        showResult = false
        
        let rx = CGFloat.random(in: 6...15) * .pi
        let ry = CGFloat.random(in: 6...15) * .pi
        let rz = CGFloat.random(in: 6...15) * .pi
        
        diceNode.removeAllActions()
        let spin = SCNAction.rotateBy(x: rx, y: ry, z: rz, duration: 1.8)
        spin.timingMode = .easeOut
        
        diceNode.runAction(spin) {
            isAnimating = false
            selectedMovie = movies.randomElement()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showResult = true
            }
        }
    }
}