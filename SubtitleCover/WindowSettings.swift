import SwiftUI

class WindowSettings: ObservableObject {
    @Published var color: Color = .black
    @Published var opacity: CGFloat = 0.5
    @Published var cornerRadius: CGFloat = 0
    @Published var width: CGFloat = 1000
    @Published var height: CGFloat = 200
}
