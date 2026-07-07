import SwiftUI

class DiceManager: ObservableObject {
    static let shared = DiceManager()
    @Published var showDice = false
    @Published var selectedMovie: Movie?
    @Published var isRolling = false
}