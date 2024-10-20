import Cocoa
import SwiftUI


class AppDelegate: NSObject, NSApplicationDelegate {
    var settingsWindow: NSWindow?
    var mainWindow: NSWindow?
    
    @ObservedObject var settings = WindowSettings()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()
        setupMainWindow()
    }

    func setupMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu(title: "App")
        appMenuItem.submenu = appMenu

        let settingsMenuItem = NSMenuItem(title: "设置", action: #selector(openSettings), keyEquivalent: ",")
        appMenu.addItem(settingsMenuItem)

        let quitMenuItem = NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitMenuItem)

        NSApplication.shared.mainMenu = mainMenu
    }

    func setupMainWindow() {
        mainWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: settings.width, height: settings.height),
            styleMask: [.borderless, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        mainWindow?.isOpaque = false
        mainWindow?.backgroundColor = .clear
        mainWindow?.hasShadow = false
        mainWindow?.level = .floating
        mainWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        mainWindow?.isMovableByWindowBackground = true

        let contentView = NSHostingView(rootView: ResizableView(settings: settings))
        mainWindow?.contentView = contentView
        mainWindow?.makeKeyAndOrderFront(nil)
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 200, y: 200, width: 400, height: 300),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            settingsWindow?.title = "设置"
            settingsWindow?.contentView = NSHostingView(rootView: SettingsView(settings: settings))
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}
