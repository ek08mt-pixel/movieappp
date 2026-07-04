import SwiftUI
import UIKit

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .shakeDetected, object: nil)
        }
    }
}

extension Notification.Name {
    static let shakeDetected = Notification.Name("shakeDetected")
}