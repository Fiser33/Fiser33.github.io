//
//  BuildSettings.swift
//  AppSecrets
//
//  Created by Fišer Jakub on 17.05.2023.
//

import Foundation

class BuildSettings {
    let apiKey = Bundle.main.infoDictionary?["API_KEY_2"] as? String

    func useApiKey() {
        print("BuildSettings: \(apiKey ?? "nil")")
    }
}
