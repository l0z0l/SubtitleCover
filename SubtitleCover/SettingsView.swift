import SwiftUI
struct SettingsView: View {
    @ObservedObject var settings: WindowSettings

    var body: some View {
        VStack {
            Text("设置遮挡区域")
            
            Slider(value: $settings.opacity, in: 0...1) {
                Text("透明度")
            }
            Slider(value: $settings.cornerRadius, in: 0...10) {
                Text("圆角")
            }
            ColorPicker("选择遮挡颜色", selection: $settings.color)
            Spacer()
        }
        .padding()
    }
}
