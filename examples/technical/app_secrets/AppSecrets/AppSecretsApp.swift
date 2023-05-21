//
//  AppSecretsApp.swift
//  AppSecrets
//
//  Created by Fišer Jakub on 17.05.2023.
//

import SwiftUI

@main
struct AppSecretsApp: App {
    init() {
        SourceCode().useApiKey()
        InfoPlist().useApiKey()
        BuildSettings().useApiKey()
        XCConfig().useApiKey()
        ThirdParty().useApiKey()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
