import SwiftUI
import CoreMotion

class ShakeDetector: ObservableObject {
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, error in
            guard let self = self, let acceleration = data?.acceleration else { return }
            let magnitude = sqrt(acceleration.x * acceleration.x + acceleration.y * acceleration.y + acceleration.z * acceleration.z)
            
            if magnitude > 2.8 {
                DispatchQueue.main.async {
                    DiceManager.shared.showDice = true
                }
            }
        }
    }
    
    func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
    }
}