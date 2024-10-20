//
//  SubtitleCoverApp.swift
//  SubtitleCover
//
//  Created by 张羽 on 10/10/24.
//

import SwiftUI



@main
struct SubtitleCoverApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
