//
//  XCConfig.swift
//  AppSecrets
//
//  Created by Fišer Jakub on 18.05.2023.
//

import Foundation

class XCConfig {
    let apiKey = Bundle.main.infoDictionary?["API_KEY_3"] as? String

    func useApiKey() {
        print("XCConfig: \(apiKey ?? "nil")")
    }
}
