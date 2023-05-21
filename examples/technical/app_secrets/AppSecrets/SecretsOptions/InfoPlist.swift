//
//  InfoPlist.swift
//  AppSecrets
//
//  Created by Fišer Jakub on 17.05.2023.
//

import Foundation

class InfoPlist {
    let apiKey = Bundle.main.infoDictionary?["API_KEY_1"] as? String

    func useApiKey() {
        print("InfoPlist: \(apiKey ?? "nil")")
    }
}
